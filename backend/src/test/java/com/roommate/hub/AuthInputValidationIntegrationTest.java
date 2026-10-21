package com.roommate.hub;

import com.roommate.hub.config.JwtUtils;
import com.roommate.hub.dto.RegisterRequest;
import com.roommate.hub.entity.AuthOtp;
import com.roommate.hub.entity.RefreshToken;
import com.roommate.hub.entity.User;
import com.roommate.hub.repository.AuthOtpRepository;
import com.roommate.hub.repository.RefreshTokenRepository;
import com.roommate.hub.repository.UserRepository;
import com.roommate.hub.service.AuthService;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.MethodSource;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.FilterChainProxy;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.context.WebApplicationContext;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;
import java.util.stream.Stream;
import org.junit.jupiter.params.provider.Arguments;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/** Real validation, BCrypt, controllers and H2 only; no cloud database, R2 or SMTP. */
@SpringBootTest
@Transactional
class AuthInputValidationIntegrationTest {
    @Autowired UserRepository users;
    @Autowired RefreshTokenRepository grants;
    @Autowired AuthOtpRepository otps;
    @Autowired PasswordEncoder encoder;
    @Autowired AuthService auth;
    @Autowired JwtUtils jwt;
    @Autowired WebApplicationContext context;
    @Autowired FilterChainProxy security;
    @Autowired jakarta.persistence.EntityManager entityManager;
    private MockMvc mvc;

    @BeforeEach void setUp() {
        mvc = MockMvcBuilders.webAppContextSetup(context).addFilters(security).build();
    }
    @AfterEach void clearAuthentication() { SecurityContextHolder.clearContext(); }

    static Stream<Arguments> invalidRegistration() {
        return Stream.of(
                Arguments.of("email", "a".repeat(60) + "@" + "b".repeat(36) + ".com"),
                Arguments.of("email", "bad-email"),
                Arguments.of("fullName", "N".repeat(101)),
                Arguments.of("fullName", "   "),
                Arguments.of("phone", "0".repeat(21)),
                Arguments.of("university", "U".repeat(151)),
                Arguments.of("gender", "UNKNOWN"),
                Arguments.of("gender", ""),
                Arguments.of("password", "1234567"),
                Arguments.of("password", " ".repeat(8)),
                Arguments.of("password", "a".repeat(73)),
                Arguments.of("password", "ắ".repeat(25)));
    }

    @ParameterizedTest @MethodSource("invalidRegistration")
    void invalidRegistrationReturnsFieldErrorsAndWritesNothing(String field, String value) throws Exception {
        Map<String, String> payload = registration();
        payload.put(field, value);
        long userCount = users.count(), grantCount = grants.count();
        String body = mvc.perform(post("/api/v1/auth/register").contentType(MediaType.APPLICATION_JSON)
                        .content(json(payload)))
                .andExpect(status().isBadRequest()).andExpect(jsonPath("status").value(400))
                .andExpect(jsonPath("message").value("Dữ liệu không hợp lệ"))
                .andExpect(jsonPath("fields." + field).isNotEmpty())
                .andReturn().getResponse().getContentAsString();
        if (field.equals("password")) assertThat(body).doesNotContain(value);
        assertThat(users.count()).isEqualTo(userCount);
        assertThat(grants.count()).isEqualTo(grantCount);
    }

    @Test void registrationServiceAlsoValidatesBeforeSavingOrIssuingTokens() {
        RegisterRequest request = new RegisterRequest();
        request.setEmail(UUID.randomUUID() + "@test.invalid");
        request.setPassword("12345678");
        request.setFullName("Test user");
        request.setGender("INVALID");
        request.setBirthDate(LocalDate.now().minusYears(20));
        request.setUniversity("Test university");
        long userCount = users.count(), grantCount = grants.count();
        assertThatThrownBy(() -> auth.register(request)).isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("Giới tính");
        assertThat(users.count()).isEqualTo(userCount);
        assertThat(grants.count()).isEqualTo(grantCount);
    }

    @Test void missingRequiredInputsReturn400WithoutWritingOrConsumingOtp() throws Exception {
        long userCount = users.count(), grantCount = grants.count();
        for (String field : new String[]{"email", "password", "fullName", "gender", "birthDate", "university"}) {
            Map<String, String> payload = registration();
            payload.remove(field);
            mvc.perform(post("/api/v1/auth/register").contentType(MediaType.APPLICATION_JSON).content(json(payload)))
                    .andExpect(status().isBadRequest()).andExpect(jsonPath("fields." + field).isNotEmpty());
        }
        assertThat(users.count()).isEqualTo(userCount);
        assertThat(grants.count()).isEqualTo(grantCount);
        User user = existingUser();
        RefreshToken grant = grant(user);
        AuthOtp otp = otp(user);
        String hash = user.getPasswordHash();
        mvc.perform(put("/api/v1/auth/change-password").header("Authorization", bearer(user, grant))
                        .contentType(MediaType.APPLICATION_JSON).content(json(Map.of("oldPassword", "123456"))))
                .andExpect(status().isBadRequest()).andExpect(jsonPath("fields.newPassword").isNotEmpty());
        mvc.perform(post("/api/v1/auth/reset-password").contentType(MediaType.APPLICATION_JSON)
                        .content(json(Map.of("email", user.getEmail(), "code", "123456"))))
                .andExpect(status().isBadRequest()).andExpect(jsonPath("fields.newPassword").isNotEmpty());
        assertUnchanged(user, grant, otp, hash);
    }

    @Test void registrationAcceptsDatabaseBoundariesAndNormalizesSupportedGender() throws Exception {
        Map<String, String> payload = registration();
        payload.put("email", "a".repeat(60) + "@" + "b".repeat(35) + ".com");
        payload.put("fullName", "N".repeat(100));
        payload.put("phone", "0".repeat(20));
        payload.put("university", "U".repeat(150));
        payload.put("gender", "other");
        payload.put("password", "ắ".repeat(24)); // exactly 72 UTF-8 bytes
        mvc.perform(post("/api/v1/auth/register").contentType(MediaType.APPLICATION_JSON).content(json(payload)))
                .andExpect(status().isOk()).andExpect(jsonPath("gender").value("OTHER"));
        User user = users.findByEmail(payload.get("email")).orElseThrow();
        assertThat(user.getFullName()).hasSize(100);
        assertThat(user.getPhone()).hasSize(20);
        assertThat(user.getUniversity()).hasSize(150);
        assertThat(encoder.matches(payload.get("password"), user.getPasswordHash())).isTrue();
    }

    @Test void optionalPhoneAndPasswordSpacesAreNotReplacedOrTrimmed() throws Exception {
        Map<String, String> payload = registration();
        payload.remove("phone");
        payload.put("password", " 123456 ");
        mvc.perform(post("/api/v1/auth/register").contentType(MediaType.APPLICATION_JSON).content(json(payload)))
                .andExpect(status().isOk());
        User user = users.findByEmail(payload.get("email")).orElseThrow();
        assertThat(user.getPhone()).isNull();
        assertThat(encoder.matches(" 123456 ", user.getPasswordHash())).isTrue();
        assertThat(encoder.matches("123456", user.getPasswordHash())).isFalse();
    }

    static Stream<String> invalidPasswords() {
        return Stream.of("1234567", " ".repeat(8), "a".repeat(73), "ắ".repeat(25));
    }

    @ParameterizedTest @MethodSource("invalidPasswords")
    void invalidNewPasswordInBothApisKeepsHashSessionAndOtp(String password) throws Exception {
        User user = existingUser();
        RefreshToken grant = grant(user);
        AuthOtp otp = otp(user);
        String oldHash = user.getPasswordHash();
        mvc.perform(put("/api/v1/auth/change-password").header("Authorization", bearer(user, grant))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(json(Map.of("oldPassword", "123456", "newPassword", password))))
                .andExpect(status().isBadRequest()).andExpect(jsonPath("fields.newPassword").isNotEmpty());
        mvc.perform(post("/api/v1/auth/reset-password").contentType(MediaType.APPLICATION_JSON)
                        .content(json(Map.of("email", user.getEmail(), "code", "123456", "newPassword", password))))
                .andExpect(status().isBadRequest()).andExpect(jsonPath("fields.newPassword").isNotEmpty());
        assertUnchanged(user, grant, otp, oldHash);
    }

    @ParameterizedTest @MethodSource("invalidPasswords")
    void serviceGuardsRejectBadNewPasswordsBeforeCredentialOrOtpMutation(String password) {
        User user = existingUser();
        RefreshToken grant = grant(user);
        AuthOtp otp = otp(user);
        String oldHash = user.getPasswordHash();
        assertThatThrownBy(() -> auth.changePassword(user.getEmail(), "123456", password))
                .isInstanceOf(IllegalArgumentException.class);
        assertThatThrownBy(() -> auth.resetPassword(user.getEmail(), "123456", password))
                .isInstanceOf(IllegalArgumentException.class);
        assertUnchanged(user, grant, otp, oldHash);
    }

    @Test void invalidResetEmailOrCodeReturns400WithoutUsingOtp() throws Exception {
        User user = existingUser();
        AuthOtp otp = otp(user);
        for (String code : new String[]{"", "abcdef", "1234567"}) {
            mvc.perform(post("/api/v1/auth/reset-password").contentType(MediaType.APPLICATION_JSON)
                            .content(json(Map.of("email", user.getEmail(), "code", code, "newPassword", "12345678"))))
                    .andExpect(status().isBadRequest()).andExpect(jsonPath("fields.code").isNotEmpty());
        }
        mvc.perform(post("/api/v1/auth/reset-password").contentType(MediaType.APPLICATION_JSON)
                        .content(json(Map.of("email", "bad-email", "code", "123456", "newPassword", "12345678"))))
                .andExpect(status().isBadRequest()).andExpect(jsonPath("fields.email").isNotEmpty());
        assertThat(otps.findById(otp.getId()).orElseThrow().isUsed()).isFalse();
        assertThat(otp.getFailedAttempts()).isZero();
    }

    @Test void oversizedLoginOrCurrentPasswordFailsNormallyWithoutRevokingSession() throws Exception {
        User user = existingUser();
        RefreshToken grant = grant(user);
        AuthOtp otp = otp(user);
        String hash = user.getPasswordHash();
        for (String password : new String[]{"a".repeat(73), "ắ".repeat(25)}) {
            mvc.perform(post("/api/v1/auth/login").contentType(MediaType.APPLICATION_JSON)
                            .content(json(Map.of("email", user.getEmail(), "password", password))))
                    .andExpect(status().isUnauthorized());
            mvc.perform(put("/api/v1/auth/change-password").header("Authorization", bearer(user, grant))
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(json(Map.of("oldPassword", password, "newPassword", "12345678"))))
                    .andExpect(status().isBadRequest());
        }
        assertUnchanged(user, grant, otp, hash);
    }

    @Test void oldSixCharacterPasswordStillLogsInAndCanBeChanged() throws Exception {
        User user = existingUser();
        mvc.perform(post("/api/v1/auth/login").contentType(MediaType.APPLICATION_JSON)
                        .content(json(Map.of("email", user.getEmail(), "password", "123456"))))
                .andExpect(status().isOk()).andExpect(jsonPath("token").isNotEmpty());
        RefreshToken grant = grant(user);
        String newPassword = "a".repeat(72);
        mvc.perform(put("/api/v1/auth/change-password").header("Authorization", bearer(user, grant))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(json(Map.of("oldPassword", "123456", "newPassword", newPassword))))
                .andExpect(status().isOk());
        assertThat(encoder.matches(newPassword, user.getPasswordHash())).isTrue();
        entityManager.refresh(grant); // bulk token revocation bypasses the persistence-context snapshot
        assertThat(grant.isRevoked()).isTrue();
    }

    @Test void validEightCharacterResetUsesOtpAndRevokesPreviousSession() throws Exception {
        User user = existingUser();
        RefreshToken grant = grant(user);
        AuthOtp otp = otp(user);
        mvc.perform(post("/api/v1/auth/reset-password").contentType(MediaType.APPLICATION_JSON)
                        .content(json(Map.of("email", user.getEmail(), "code", "123456", "newPassword", "12345678"))))
                .andExpect(status().isOk());
        assertThat(encoder.matches("12345678", user.getPasswordHash())).isTrue();
        assertThat(otps.findById(otp.getId()).orElseThrow().isUsed()).isTrue();
        entityManager.refresh(grant);
        assertThat(grant.isRevoked()).isTrue();
    }

    private void assertUnchanged(User user, RefreshToken grant, AuthOtp otp, String hash) {
        entityManager.refresh(user);
        entityManager.refresh(grant);
        entityManager.refresh(otp);
        assertThat(users.findById(user.getId()).orElseThrow().getPasswordHash()).isEqualTo(hash);
        assertThat(user.getPasswordChangedAt()).isNull();
        assertThat(grants.findById(grant.getId()).orElseThrow().isRevoked()).isFalse();
        AuthOtp persisted = otps.findById(otp.getId()).orElseThrow();
        assertThat(persisted.isUsed()).isFalse();
        assertThat(persisted.getFailedAttempts()).isZero();
    }

    private Map<String, String> registration() {
        Map<String, String> fields = new LinkedHashMap<>();
        fields.put("email", UUID.randomUUID() + "@test.invalid");
        fields.put("password", "12345678");
        fields.put("fullName", "Test user");
        fields.put("gender", "MALE");
        fields.put("phone", "0901234567");
        fields.put("birthDate", LocalDate.now().minusYears(20).toString());
        fields.put("university", "Test university");
        return fields;
    }
    private User existingUser() {
        return users.saveAndFlush(User.builder().email(UUID.randomUUID() + "@test.invalid")
                .passwordHash(encoder.encode("123456")).fullName("Legacy user").gender("MALE")
                .role(User.Role.ROLE_USER).build());
    }
    private RefreshToken grant(User user) {
        return grants.saveAndFlush(RefreshToken.builder().user(user).token(UUID.randomUUID().toString())
                .expiresAt(LocalDateTime.now().plusDays(1)).build());
    }
    private String bearer(User user, RefreshToken grant) {
        return "Bearer " + jwt.generateToken(user.getEmail(), user.getId(), grant.getId());
    }
    private AuthOtp otp(User user) {
        return otps.saveAndFlush(AuthOtp.builder().email(user.getEmail()).otpCode(encoder.encode("123456"))
                .type(AuthOtp.OtpType.PASSWORD_RESET).expiresAt(LocalDateTime.now().plusMinutes(5)).build());
    }
    // Synthetic fixture values contain no JSON control characters.
    private String json(Map<String, String> values) {
        return values.entrySet().stream().map(e -> "\"" + e.getKey() + "\":\"" + e.getValue() + "\"")
                .collect(Collectors.joining(",", "{", "}"));
    }
}
