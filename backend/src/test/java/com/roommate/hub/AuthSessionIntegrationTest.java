package com.roommate.hub;

import com.roommate.hub.dto.AuthResponse;
import com.roommate.hub.dto.LoginRequest;
import com.roommate.hub.dto.RegisterRequest;
import com.roommate.hub.entity.AuthOtp;
import com.roommate.hub.entity.User;
import com.roommate.hub.repository.AuthOtpRepository;
import com.roommate.hub.repository.UserRepository;
import com.roommate.hub.service.AuthService;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.FilterChainProxy;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.context.WebApplicationContext;
import org.springframework.web.server.ResponseStatusException;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.SignatureAlgorithm;
import io.jsonwebtoken.security.Keys;

import java.time.LocalDateTime;
import java.time.LocalDate;
import java.nio.charset.StandardCharsets;
import java.util.Date;
import java.util.UUID;

import static org.assertj.core.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@Transactional
class AuthSessionIntegrationTest {
    @Autowired AuthService auth;
    @Autowired UserRepository users;
    @Autowired AuthOtpRepository otps;
    @Autowired PasswordEncoder encoder;
    @Autowired WebApplicationContext webContext;
    @Autowired FilterChainProxy securityFilterChain;
    @Value("${app.jwt.secret}") String jwtSecret;
    private MockMvc mvc;
    private User user;
    private String password;

    @BeforeEach void setUp() {
        password = UUID.randomUUID().toString();
        user = users.saveAndFlush(User.builder().email(UUID.randomUUID() + "@test.invalid")
                .passwordHash(encoder.encode(password)).fullName("Session test")
                .gender("MALE").role(User.Role.ROLE_USER).build());
        mvc = MockMvcBuilders.webAppContextSetup(webContext).addFilters(securityFilterChain).build();
    }

    @AfterEach void clearAuthentication() { SecurityContextHolder.clearContext(); }

    @Test void reloginDoesNotDependOnLogoutTimestampAndOldTokenStaysRevoked() throws Exception {
        AuthResponse first = login(password);
        assertAccess(first.getToken(), 200);
        auth.logout(first.getRefreshToken(), user.getEmail());
        assertAccess(first.getToken(), 401);

        // Deterministically reproduce the old timestamp comparison failing, without sleeps.
        // A newer logout watermark must not invalidate a freshly authenticated session.
        user.setLoggedOutAt(LocalDateTime.now().plusMinutes(1));
        users.saveAndFlush(user);
        AuthResponse second = login(password);
        assertAccess(second.getToken(), 200);
        assertAccess(first.getToken(), 401);
    }

    @Test void consecutiveLoginsInvalidateOnlyThePreviousSession() throws Exception {
        AuthResponse first = login(password);
        AuthResponse second = login(password);
        assertThat(second.getToken()).isNotEqualTo(first.getToken());
        assertAccess(first.getToken(), 401);
        assertAccess(second.getToken(), 200);
    }

    @Test void refreshRotatesBothTokensAndLogoutRevokesTheRotatedAccessToken() throws Exception {
        AuthResponse first = login(password);
        var rotated = auth.refreshToken(first.getRefreshToken());
        String access = (String) rotated.get("token");
        assertAccess(access, 200);
        assertAccess(first.getToken(), 401);
        auth.logout((String) rotated.get("refreshToken"), user.getEmail());
        assertAccess(access, 401);
    }

    @Test void changingPasswordRevokesAccessAndRefreshButImmediateReloginWorks() throws Exception {
        AuthResponse first = login(password);
        String newPassword = UUID.randomUUID().toString();
        auth.changePassword(user.getEmail(), password, newPassword);
        assertAccess(first.getToken(), 401);
        assertThatThrownBy(() -> auth.refreshToken(first.getRefreshToken()))
                .isInstanceOf(ResponseStatusException.class);
        AuthResponse second = login(newPassword);
        assertAccess(second.getToken(), 200);
        assertAccess(first.getToken(), 401);
    }

    @Test void reusingRevokedRefreshTokenAlsoRevokesAccessForTheActiveSession() throws Exception {
        AuthResponse first = login(password);
        var rotated = auth.refreshToken(first.getRefreshToken());
        String access = (String) rotated.get("token");
        assertAccess(access, 200);
        assertThatThrownBy(() -> auth.refreshToken(first.getRefreshToken()))
                .isInstanceOf(ResponseStatusException.class);
        assertAccess(access, 401);
    }

    @Test void registrationIssuesAnAccessTokenBoundToItsPersistedGrant() throws Exception {
        RegisterRequest request = new RegisterRequest();
        request.setEmail(UUID.randomUUID() + "@test.invalid");
        request.setPassword(password);
        request.setFullName("Registered session");
        request.setGender("MALE");
        request.setBirthDate(LocalDate.now().minusYears(20));
        request.setUniversity("Test university");
        AuthResponse registered = auth.register(request);
        assertAccess(registered.getToken(), 200);
    }

    @Test void passwordResetRevokesTheOldGrantAndNewLoginWorksImmediately() throws Exception {
        AuthResponse first = login(password);
        String otp = Integer.toString(java.util.concurrent.ThreadLocalRandom.current().nextInt(100000, 1000000));
        otps.saveAndFlush(AuthOtp.builder().email(user.getEmail()).otpCode(encoder.encode(otp))
                .type(AuthOtp.OtpType.PASSWORD_RESET).expiresAt(LocalDateTime.now().plusMinutes(5)).build());
        String newPassword = UUID.randomUUID().toString();
        auth.resetPassword(user.getEmail(), otp, newPassword);
        assertAccess(first.getToken(), 401);
        assertThatThrownBy(() -> auth.refreshToken(first.getRefreshToken()))
                .isInstanceOf(ResponseStatusException.class);
        assertAccess(login(newPassword).getToken(), 200);
    }

    @Test void legacyAccessTokenCanBeReplacedUsingAnActiveRefreshTokenAfterUpgrade() throws Exception {
        AuthResponse session = login(password);
        String legacyToken = Jwts.builder().setSubject(user.getEmail()).claim("userId", user.getId())
                .claim("token_type", "ACCESS").setIssuedAt(new Date())
                .setExpiration(new Date(System.currentTimeMillis() + 86400000L))
                .signWith(Keys.hmacShaKeyFor(jwtSecret.getBytes(StandardCharsets.UTF_8)), SignatureAlgorithm.HS256)
                .compact();
        assertAccess(legacyToken, 401);
        var refreshed = auth.refreshToken(session.getRefreshToken());
        assertAccess((String) refreshed.get("token"), 200);
    }

    private AuthResponse login(String rawPassword) {
        LoginRequest request = new LoginRequest();
        request.setEmail(user.getEmail());
        request.setPassword(rawPassword);
        return auth.login(request);
    }

    private void assertAccess(String token, int expectedStatus) throws Exception {
        SecurityContextHolder.clearContext();
        mvc.perform(get("/api/v1/blocks").header("Authorization", "Bearer " + token))
                .andExpect(status().is(expectedStatus));
    }
}
