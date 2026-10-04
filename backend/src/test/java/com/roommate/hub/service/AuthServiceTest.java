package com.roommate.hub.service;

import com.roommate.hub.config.JwtUtils;
import com.roommate.hub.dto.AuthResponse;
import com.roommate.hub.dto.LoginRequest;
import com.roommate.hub.dto.RegisterRequest;
import com.roommate.hub.entity.AuthOtp;
import com.roommate.hub.entity.RefreshToken;
import com.roommate.hub.entity.User;
import com.roommate.hub.repository.AuthOtpRepository;
import com.roommate.hub.repository.RefreshTokenRepository;
import com.roommate.hub.repository.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.server.ResponseStatusException;

import java.time.LocalDateTime;
import java.util.Map;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class AuthServiceTest {

    @Mock
    private UserRepository userRepository;

    @Mock
    private PasswordEncoder passwordEncoder;

    @Mock
    private JwtUtils jwtUtils;

    @Mock
    private AuthOtpRepository authOtpRepository;

    @Mock
    private RefreshTokenRepository refreshTokenRepository;

    @Mock
    private EmailService emailService;

    @Mock
    private OtpAttemptService otpAttemptService;

    @Mock
    private TokenRevocationService tokenRevocationService;

    @InjectMocks
    private AuthService authService;

    private User sampleUser;

    @BeforeEach
    void setUp() {
        sampleUser = User.builder()
                .id(1L)
                .email("quochuy@example.com")
                .passwordHash("encoded_secret_pass")
                .fullName("Phạm Quốc Huy")
                .gender("MALE")
                .phone("0901234567")
                .role(User.Role.ROLE_USER)
                .status("ACTIVE")
                .build();

        lenient().when(refreshTokenRepository.save(any(RefreshToken.class))).thenAnswer(inv -> {
            RefreshToken rt = inv.getArgument(0);
            if (rt.getId() == null) {
                rt.setId(100L);
            }
            return rt;
        });

        lenient().when(passwordEncoder.encode(anyString())).thenAnswer(inv -> "encoded_" + inv.getArgument(0));
        lenient().when(passwordEncoder.matches(anyString(), anyString())).thenAnswer(inv -> {
            String raw = inv.getArgument(0);
            String encoded = inv.getArgument(1);
            return encoded != null && (encoded.equals("encoded_" + raw) || encoded.equals(raw));
        });
    }

    @Test
    @DisplayName("P1: login() trả phone lấy chính xác từ User entity và cấp Refresh Token")
    void login_ShouldReturnPhoneFromUserEntity() {
        LoginRequest req = new LoginRequest();
        req.setEmail("quochuy@example.com");
        req.setPassword("secret_pass");

        when(userRepository.findByEmail("quochuy@example.com")).thenReturn(Optional.of(sampleUser));
        when(jwtUtils.generateToken("quochuy@example.com", 1L, 100L)).thenReturn("jwt-sample-token");

        AuthResponse res = authService.login(req);

        assertThat(res).isNotNull();
        assertThat(res.getToken()).isEqualTo("jwt-sample-token");
        assertThat(res.getRefreshToken()).isNotNull();
        assertThat(res.getUserId()).isEqualTo(1L);
        assertThat(res.getEmail()).isEqualTo("quochuy@example.com");
        assertThat(res.getFullName()).isEqualTo("Phạm Quốc Huy");
        assertThat(res.getGender()).isEqualTo("MALE");
        assertThat(res.getRole()).isEqualTo("ROLE_USER");
        assertThat(res.getPhone()).isEqualTo("0901234567");
        verify(userRepository, times(1)).findByEmail("quochuy@example.com");
    }

    @Test
    @DisplayName("P1: register() trả lại đúng phone vừa đăng ký và cấp Refresh Token")
    void register_ShouldReturnExactPhoneProvided() {
        RegisterRequest req = new RegisterRequest();
        req.setEmail("newuser@example.com");
        req.setPassword("pass123");
        req.setFullName("Nguyễn Văn A");
        req.setGender("MALE");
        req.setPhone("0987654321");

        when(userRepository.existsByEmail("newuser@example.com")).thenReturn(false);
        when(jwtUtils.generateToken(eq("newuser@example.com"), any(), eq(100L))).thenReturn("jwt-registered-token");
        when(userRepository.save(any(User.class))).thenAnswer(invocation -> {
            User u = invocation.getArgument(0);
            u.setId(2L);
            return u;
        });

        AuthResponse res = authService.register(req);

        assertThat(res).isNotNull();
        assertThat(res.getToken()).isEqualTo("jwt-registered-token");
        assertThat(res.getRefreshToken()).isNotNull();
        assertThat(res.getEmail()).isEqualTo("newuser@example.com");
        assertThat(res.getFullName()).isEqualTo("Nguyễn Văn A");
        assertThat(res.getPhone()).isEqualTo("0987654321");
        verify(userRepository, times(1)).save(any(User.class));
    }

    @Test
    @DisplayName("register() ném ngoại lệ khi email đã tồn tại")
    void register_WhenEmailExists_ShouldThrowException() {
        RegisterRequest req = new RegisterRequest();
        req.setEmail("quochuy@example.com");

        when(userRepository.existsByEmail("quochuy@example.com")).thenReturn(true);

        assertThatThrownBy(() -> authService.register(req))
                .isInstanceOf(ResponseStatusException.class)
                .satisfies(ex -> assertThat(((ResponseStatusException) ex).getStatusCode()).isEqualTo(HttpStatus.CONFLICT))
                .hasMessageContaining("Email đã được đăng ký!");

        verify(userRepository, never()).save(any());
    }

    @Test
    @DisplayName("login() ném ngoại lệ khi mật khẩu sai")
    void login_WhenPasswordMismatch_ShouldThrowException() {
        LoginRequest req = new LoginRequest();
        req.setEmail("quochuy@example.com");
        req.setPassword("wrong_pass");

        when(userRepository.findByEmail("quochuy@example.com")).thenReturn(Optional.of(sampleUser));

        assertThatThrownBy(() -> authService.login(req))
                .isInstanceOf(RuntimeException.class)
                .hasMessageContaining("Email hoặc mật khẩu không chính xác!");
    }

    @Test
    @DisplayName("login() ném ngoại lệ khi tài khoản bị khóa")
    void login_WhenAccountLocked_ShouldThrowForbidden() {
        User lockedUser = User.builder()
                .id(99L)
                .email("locked@example.com")
                .passwordHash("pass")
                .fullName("Banned User")
                .gender("MALE")
                .status("BANNED")
                .role(User.Role.ROLE_USER)
                .build();

        LoginRequest req = new LoginRequest();
        req.setEmail("locked@example.com");
        req.setPassword("pass");

        when(userRepository.findByEmail("locked@example.com")).thenReturn(Optional.of(lockedUser));

        assertThatThrownBy(() -> authService.login(req))
                .isInstanceOf(org.springframework.web.server.ResponseStatusException.class)
                .hasMessageContaining("Tài khoản của bạn đã bị khóa");
    }

    @Test
    @DisplayName("refreshToken() ném ngoại lệ khi không có token hợp lệ")
    void refreshToken_WhenNoValidToken_ShouldThrowUnauthorized() {
        assertThatThrownBy(() -> authService.refreshToken(null, null))
                .isInstanceOf(org.springframework.web.server.ResponseStatusException.class)
                .hasMessageContaining("Refresh Token");
    }

    @Test
    @DisplayName("refreshToken() từ chối khi truyền vào access token JWT")
    void refreshToken_WhenAccessTokenPassed_ShouldThrowUnauthorized() {
        when(jwtUtils.isAccessToken("eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.access.token")).thenReturn(true);

        assertThatThrownBy(() -> authService.refreshToken("eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.access.token", null))
                .isInstanceOf(ResponseStatusException.class)
                .hasMessageContaining("Access token không thể dùng để làm mới phiên");
    }

    @Test
    @DisplayName("refreshToken() xoay vòng token thành công với pessimistic lock khi refresh token hợp lệ")
    void refreshToken_WhenValid_ShouldRotateToken() {
        RefreshToken rt = RefreshToken.builder()
                .id(1L)
                .user(sampleUser)
                .token("valid_rt_string")
                .revoked(false)
                .createdAt(LocalDateTime.now())
                .expiresAt(LocalDateTime.now().plusDays(5))
                .build();
        when(refreshTokenRepository.findByTokenForUpdate(anyString())).thenReturn(Optional.of(rt));
        when(jwtUtils.generateToken(sampleUser.getEmail(), sampleUser.getId(), 100L)).thenReturn("new_access_token");

        Map<String, Object> response = authService.refreshToken("valid_rt_string");

        assertThat(response).isNotNull();
        assertThat(response.get("accessToken")).isEqualTo("new_access_token");
        assertThat(response.get("refreshToken")).isNotNull();
        assertThat(rt.isRevoked()).isTrue();
        verify(refreshTokenRepository, times(1)).save(rt);
    }

    @Test
    @DisplayName("refreshToken() phát hiện token reuse khi token đã bị thu hồi và hủy toàn bộ phiên qua TokenRevocationService")
    void refreshToken_WhenTokenAlreadyRevoked_ShouldDetectReuseAndRevokeAll() {
        RefreshToken revokedRt = RefreshToken.builder()
                .id(1L)
                .user(sampleUser)
                .token("stolen_revoked_rt")
                .revoked(true)
                .createdAt(LocalDateTime.now().minusDays(1))
                .expiresAt(LocalDateTime.now().plusDays(5))
                .build();
        when(refreshTokenRepository.findByTokenForUpdate(anyString())).thenReturn(Optional.of(revokedRt));

        assertThatThrownBy(() -> authService.refreshToken("stolen_revoked_rt"))
                .isInstanceOf(ResponseStatusException.class)
                .satisfies(ex -> assertThat(((ResponseStatusException) ex).getStatusCode()).isEqualTo(HttpStatus.UNAUTHORIZED))
                .hasMessageContaining("Cảnh báo bảo mật: Refresh token đã bị thu hồi trước đó");

        verify(tokenRevocationService, times(1)).revokeAllUserTokens(sampleUser);
    }

    @Test
    @DisplayName("refreshToken() ném ngoại lệ UNAUTHORIZED khi token được cấp trước thời điểm đổi mật khẩu")
    void refreshToken_WhenTokenIssuedBeforePasswordChanged_ShouldThrowUnauthorized() {
        sampleUser.setPasswordChangedAt(LocalDateTime.now());
        RefreshToken rt = RefreshToken.builder()
                .id(1L)
                .user(sampleUser)
                .token("valid_rt_format")
                .revoked(false)
                .createdAt(LocalDateTime.now().minusHours(2))
                .expiresAt(LocalDateTime.now().plusDays(5))
                .build();
        when(refreshTokenRepository.findByTokenForUpdate(anyString())).thenReturn(Optional.of(rt));

        assertThatThrownBy(() -> authService.refreshToken("valid_rt_format", null))
                .isInstanceOf(ResponseStatusException.class)
                .satisfies(ex -> assertThat(((ResponseStatusException) ex).getStatusCode()).isEqualTo(HttpStatus.UNAUTHORIZED))
                .hasMessageContaining("mật khẩu đã được thay đổi");
    }

    @Test
    @DisplayName("changePassword() trả lỗi 404 khi tài khoản không tồn tại, không thu hồi phiên")
    void changePassword_WhenUserMissing_ShouldThrowNotFoundWithoutMutation() {
        when(userRepository.findByEmail("missing@example.test")).thenReturn(Optional.empty());

        assertThatThrownBy(() -> authService.changePassword("missing@example.test", "test-old", "test-new"))
                .isInstanceOf(com.roommate.hub.exception.ResourceNotFoundException.class);

        verify(userRepository, never()).save(any());
        verifyNoInteractions(passwordEncoder, tokenRevocationService);
    }

    @Test
    @DisplayName("changePassword() trả lỗi 400 khi mật khẩu hiện tại sai, giữ dữ liệu và phiên")
    void changePassword_WhenOldPasswordWrong_ShouldThrowBadRequestWithoutMutation() {
        when(userRepository.findByEmail(sampleUser.getEmail())).thenReturn(Optional.of(sampleUser));

        assertThatThrownBy(() -> authService.changePassword(sampleUser.getEmail(), "wrong-test-password", "test-new"))
                .isExactlyInstanceOf(IllegalArgumentException.class)
                .hasMessage("Mật khẩu hiện tại không chính xác!");

        assertThat(sampleUser.getPasswordHash()).isEqualTo("encoded_secret_pass");
        assertThat(sampleUser.getPasswordChangedAt()).isNull();
        verify(userRepository, never()).save(any());
        verifyNoInteractions(tokenRevocationService);
    }

    @Test
    @DisplayName("changePassword() thu hồi toàn bộ refresh token qua TokenRevocationService sau khi đổi mật khẩu")
    void changePassword_ShouldRevokeAllRefreshTokens() {
        when(userRepository.findByEmail("quochuy@example.com")).thenReturn(Optional.of(sampleUser));

        authService.changePassword("quochuy@example.com", "secret_pass", "new_pass_123");

        verify(tokenRevocationService, times(1)).revokeAllUserTokens(sampleUser);
    }

    @Test
    @DisplayName("logout() thu hồi token và phiên người dùng qua TokenRevocationService")
    void logout_ShouldRevokeTokens() {
        RefreshToken rt = RefreshToken.builder()
                .id(1L)
                .token("hash")
                .user(sampleUser)
                .build();
        when(refreshTokenRepository.findByToken(anyString())).thenReturn(Optional.of(rt));
        when(userRepository.findByEmail("quochuy@example.com")).thenReturn(Optional.of(sampleUser));

        authService.logout("raw_refresh_token", "quochuy@example.com");

        verify(tokenRevocationService, times(1)).revokeToken(rt);
        verify(tokenRevocationService, times(1)).revokeAllUserTokens(sampleUser);
        assertThat(sampleUser.getLoggedOutAt()).isNotNull();
        verify(userRepository, times(1)).save(sampleUser);
    }

    @Test
    @DisplayName("forgotPassword() trả về thành công mà không lộ email khi email không tồn tại (chống account enumeration)")
    void forgotPassword_WhenEmailDoesNotExist_ShouldReturnSilentlyWithoutError() {
        when(userRepository.findByEmail("nonexistent@example.com")).thenReturn(Optional.empty());

        authService.forgotPassword("nonexistent@example.com");

        verify(emailService, never()).sendPasswordResetOtp(anyString(), anyString());
        verify(emailService, times(1)).simulateDeliveryDelay();
        ArgumentCaptor<AuthOtp> captor = ArgumentCaptor.forClass(AuthOtp.class);
        verify(authOtpRepository, times(1)).save(captor.capture());
        assertThat(captor.getValue().isUsed()).isTrue();
    }

    @Test
    @DisplayName("forgotPassword() ném TOO_MANY_REQUESTS khi vi phạm cooldown 60 giây")
    void forgotPassword_WhenCooldownActive_ShouldThrowTooManyRequests() {
        AuthOtp recentOtp = AuthOtp.builder()
                .email("quochuy@example.com")
                .otpCode("encoded_111222")
                .type(AuthOtp.OtpType.PASSWORD_RESET)
                .createdAt(LocalDateTime.now().minusSeconds(10))
                .build();
        when(authOtpRepository.findTopByEmailAndTypeOrderByCreatedAtDesc("quochuy@example.com", AuthOtp.OtpType.PASSWORD_RESET))
                .thenReturn(Optional.of(recentOtp));

        assertThatThrownBy(() -> authService.forgotPassword("quochuy@example.com"))
                .isInstanceOf(ResponseStatusException.class)
                .satisfies(ex -> assertThat(((ResponseStatusException) ex).getStatusCode()).isEqualTo(HttpStatus.TOO_MANY_REQUESTS))
                .hasMessageContaining("Vui lòng đợi");
    }

    @Test
    @DisplayName("forgotPassword() ném TOO_MANY_REQUESTS khi vượt quá 5 lần trong 1 giờ")
    void forgotPassword_WhenHourlyLimitExceeded_ShouldThrowTooManyRequests() {
        when(authOtpRepository.countByEmailAndTypeAndCreatedAtAfter(eq("quochuy@example.com"), eq(AuthOtp.OtpType.PASSWORD_RESET), any()))
                .thenReturn(5L);

        assertThatThrownBy(() -> authService.forgotPassword("quochuy@example.com"))
                .isInstanceOf(ResponseStatusException.class)
                .satisfies(ex -> assertThat(((ResponseStatusException) ex).getStatusCode()).isEqualTo(HttpStatus.TOO_MANY_REQUESTS))
                .hasMessageContaining("quá 5 lần");
    }

    @Test
    @DisplayName("forgotPassword() lưu OTP đã hash vào DB và gửi OTP plaintext qua EmailService khi email tồn tại")
    void forgotPassword_WhenEmailExists_ShouldSucceed() {
        when(userRepository.findByEmail("quochuy@example.com")).thenReturn(Optional.of(sampleUser));
        authService.forgotPassword("quochuy@example.com");

        ArgumentCaptor<AuthOtp> otpCaptor = ArgumentCaptor.forClass(AuthOtp.class);
        verify(authOtpRepository, times(1)).save(otpCaptor.capture());
        assertThat(otpCaptor.getValue().getOtpCode()).startsWith("encoded_");
        assertThat(otpCaptor.getValue().getType()).isEqualTo(AuthOtp.OtpType.PASSWORD_RESET);

        verify(emailService, times(1)).sendPasswordResetOtp(eq("quochuy@example.com"), anyString());
    }

    @Test
    @DisplayName("resetPassword() ghi nhận số lần thử sai qua OtpAttemptService và ném BadRequest")
    void resetPassword_WhenWrongOtp_ShouldRecordFailedAttemptAndThrowBadRequest() {
        AuthOtp activeOtp = AuthOtp.builder()
                .email("quochuy@example.com")
                .otpCode("encoded_123456")
                .type(AuthOtp.OtpType.PASSWORD_RESET)
                .expiresAt(LocalDateTime.now().plusMinutes(15))
                .used(false)
                .failedAttempts(0)
                .build();
        when(authOtpRepository.findTopByEmailAndTypeAndUsedFalseOrderByCreatedAtDesc(eq("quochuy@example.com"), eq(AuthOtp.OtpType.PASSWORD_RESET)))
                .thenReturn(Optional.of(activeOtp));
        when(otpAttemptService.recordFailedAttempt(activeOtp)).thenReturn(1);

        assertThatThrownBy(() -> authService.resetPassword("quochuy@example.com", "999999", "newPassword123"))
                .isInstanceOf(org.springframework.web.server.ResponseStatusException.class)
                .hasMessageContaining("Mã xác nhận không chính xác! Bạn còn 4 lần thử.");

        verify(otpAttemptService, times(1)).recordFailedAttempt(activeOtp);
    }

    @Test
    @DisplayName("resetPassword() khóa mã và ném TOO_MANY_REQUESTS khi OtpAttemptService trả về >= 5 lần sai")
    void resetPassword_WhenExceedsMaxFailedAttempts_ShouldLockOtp() {
        AuthOtp activeOtp = AuthOtp.builder()
                .email("quochuy@example.com")
                .otpCode("encoded_123456")
                .type(AuthOtp.OtpType.PASSWORD_RESET)
                .expiresAt(LocalDateTime.now().plusMinutes(15))
                .used(false)
                .failedAttempts(4)
                .build();
        when(authOtpRepository.findTopByEmailAndTypeAndUsedFalseOrderByCreatedAtDesc(eq("quochuy@example.com"), eq(AuthOtp.OtpType.PASSWORD_RESET)))
                .thenReturn(Optional.of(activeOtp));
        when(otpAttemptService.recordFailedAttempt(activeOtp)).thenReturn(5);

        assertThatThrownBy(() -> authService.resetPassword("quochuy@example.com", "999999", "newPassword123"))
                .isInstanceOf(ResponseStatusException.class)
                .satisfies(ex -> assertThat(((ResponseStatusException) ex).getStatusCode()).isEqualTo(HttpStatus.TOO_MANY_REQUESTS))
                .hasMessageContaining("vô hiệu hóa vì lý do bảo mật");

        verify(otpAttemptService, times(1)).recordFailedAttempt(activeOtp);
    }

    @Test
    @DisplayName("resetPassword() thành công khi đúng OTP, đánh dấu OTP đã dùng qua OtpAttemptService và thu hồi refresh token qua TokenRevocationService")
    void resetPassword_WhenValidOtp_ShouldUpdatePassword() {
        AuthOtp activeOtp = AuthOtp.builder()
                .email("quochuy@example.com")
                .otpCode("encoded_123456")
                .type(AuthOtp.OtpType.PASSWORD_RESET)
                .expiresAt(LocalDateTime.now().plusMinutes(15))
                .used(false)
                .failedAttempts(0)
                .build();
        when(authOtpRepository.findTopByEmailAndTypeAndUsedFalseOrderByCreatedAtDesc(eq("quochuy@example.com"), eq(AuthOtp.OtpType.PASSWORD_RESET)))
                .thenReturn(Optional.of(activeOtp));
        when(userRepository.findByEmail("quochuy@example.com")).thenReturn(Optional.of(sampleUser));

        authService.resetPassword("quochuy@example.com", "123456", "newPassword123");

        assertThat(sampleUser.getPasswordHash()).isEqualTo("encoded_newPassword123");
        assertThat(sampleUser.getPasswordChangedAt()).isNotNull();
        verify(userRepository, times(1)).save(sampleUser);
        verify(otpAttemptService, times(1)).markUsed(activeOtp);
        verify(tokenRevocationService, times(1)).revokeAllUserTokens(sampleUser);
    }

    @Test
    @DisplayName("sendEmailVerification() trả về thành công mà không lộ tài khoản khi email không tồn tại (chống account enumeration)")
    void sendEmailVerification_WhenNonExistent_ShouldReturnSilentlyWithoutError() {
        when(userRepository.findByEmail("nonexistent@example.com")).thenReturn(Optional.empty());

        authService.sendEmailVerification("nonexistent@example.com");

        verify(emailService, never()).sendVerificationOtp(anyString(), anyString());
        verify(emailService, times(1)).simulateDeliveryDelay();
        ArgumentCaptor<AuthOtp> captor = ArgumentCaptor.forClass(AuthOtp.class);
        verify(authOtpRepository, times(1)).save(captor.capture());
        assertThat(captor.getValue().isUsed()).isTrue();
    }

    @Test
    @DisplayName("verifyEmail() ném ngoại lệ khi mã xác minh giả mạo")
    void verifyEmail_WhenWrongOtp_ShouldThrowBadRequest() {
        when(authOtpRepository.findTopByEmailAndTypeAndUsedFalseOrderByCreatedAtDesc(eq("quochuy@example.com"), eq(AuthOtp.OtpType.EMAIL_VERIFICATION)))
                .thenReturn(Optional.empty());

        assertThatThrownBy(() -> authService.verifyEmail("quochuy@example.com", "000000"))
                .isInstanceOf(org.springframework.web.server.ResponseStatusException.class)
                .hasMessageContaining("Mã xác nhận");
    }

    @Test
    @DisplayName("verifyEmail() ném ngoại lệ FORBIDDEN khi tài khoản đã bị admin khóa")
    void verifyEmail_WhenAccountLocked_ShouldThrowForbidden() {
        sampleUser.setStatus("LOCKED");
        AuthOtp activeOtp = AuthOtp.builder()
                .email("quochuy@example.com")
                .otpCode("encoded_654321")
                .type(AuthOtp.OtpType.EMAIL_VERIFICATION)
                .expiresAt(LocalDateTime.now().plusMinutes(15))
                .used(false)
                .failedAttempts(0)
                .build();
        when(authOtpRepository.findTopByEmailAndTypeAndUsedFalseOrderByCreatedAtDesc(eq("quochuy@example.com"), eq(AuthOtp.OtpType.EMAIL_VERIFICATION)))
                .thenReturn(Optional.of(activeOtp));
        when(userRepository.findByEmail("quochuy@example.com")).thenReturn(Optional.of(sampleUser));

        assertThatThrownBy(() -> authService.verifyEmail("quochuy@example.com", "654321"))
                .isInstanceOf(org.springframework.web.server.ResponseStatusException.class)
                .satisfies(ex -> assertThat(((org.springframework.web.server.ResponseStatusException) ex).getStatusCode())
                        .isEqualTo(org.springframework.http.HttpStatus.FORBIDDEN));
    }

    @Test
    @DisplayName("verifyEmail() thành công khi mã xác minh khớp và kích hoạt trạng thái ACTIVE")
    void verifyEmail_WhenValid_ShouldSetActive() {
        sampleUser.setStatus("PENDING");
        AuthOtp activeOtp = AuthOtp.builder()
                .email("quochuy@example.com")
                .otpCode("encoded_654321")
                .type(AuthOtp.OtpType.EMAIL_VERIFICATION)
                .expiresAt(LocalDateTime.now().plusMinutes(15))
                .used(false)
                .failedAttempts(0)
                .build();
        when(authOtpRepository.findTopByEmailAndTypeAndUsedFalseOrderByCreatedAtDesc(eq("quochuy@example.com"), eq(AuthOtp.OtpType.EMAIL_VERIFICATION)))
                .thenReturn(Optional.of(activeOtp));
        when(userRepository.findByEmail("quochuy@example.com")).thenReturn(Optional.of(sampleUser));

        authService.verifyEmail("quochuy@example.com", "654321");

        assertThat(sampleUser.getStatus()).isEqualTo("ACTIVE");
        verify(otpAttemptService, times(1)).markUsed(activeOtp);
        verify(userRepository, times(1)).save(sampleUser);
    }

    @Test
    @DisplayName("forgotPassword() áp dụng rate limit cả với email không tồn tại (chống dò quét qua 429)")
    void forgotPassword_WhenNonExistentEmailExceedsLimit_ShouldThrowTooManyRequests() {
        when(authOtpRepository.countByEmailAndTypeAndCreatedAtAfter(eq("attacker_target@example.com"), eq(AuthOtp.OtpType.PASSWORD_RESET), any()))
                .thenReturn(5L);

        assertThatThrownBy(() -> authService.forgotPassword("attacker_target@example.com"))
                .isInstanceOf(ResponseStatusException.class)
                .satisfies(ex -> assertThat(((ResponseStatusException) ex).getStatusCode()).isEqualTo(HttpStatus.TOO_MANY_REQUESTS));
    }

    @Test
    @DisplayName("login() ghi nhận lastLoginAt khi đăng nhập, KHÔNG xóa loggedOutAt để bảo toàn mốc thu hồi")
    void login_WhenPreviouslyLoggedOut_ShouldSetLastLoginAtWithoutClearingLoggedOutAt() {
        LocalDateTime logoutTime = LocalDateTime.now().minusMinutes(5);
        sampleUser.setLoggedOutAt(logoutTime);
        when(userRepository.findByEmail("quochuy@example.com")).thenReturn(Optional.of(sampleUser));
        when(jwtUtils.generateToken("quochuy@example.com", 1L, 100L)).thenReturn("new-jwt-token");

        LoginRequest req = new LoginRequest();
        req.setEmail("quochuy@example.com");
        req.setPassword("secret_pass");

        AuthResponse res = authService.login(req);

        assertThat(res).isNotNull();
        // loggedOutAt phải được giữ nguyên để filter vẫn có thể từ chối các token bị đánh cắp từ trước logout
        assertThat(sampleUser.getLoggedOutAt()).isEqualTo(logoutTime);
        // Audit timestamp is real; the JWT is tied to a new persisted grant.
        assertThat(sampleUser.getLastLoginAt()).isNotNull();
        assertThat(sampleUser.getLastLoginAt()).isBeforeOrEqualTo(LocalDateTime.now());
        assertThat(sampleUser.getLastLoginAt()).isAfter(logoutTime);
        verify(userRepository, atLeastOnce()).save(sampleUser);
    }

    @Test
    @DisplayName("login() ghi nhận thời gian thực và giữ nguyên lịch sử đổi mật khẩu")
    void login_ShouldSetRealLastLoginAtWithoutRewritingPasswordHistory() {
        sampleUser.setLoggedOutAt(LocalDateTime.now().minusMinutes(2));
        LocalDateTime passwordChangedAt = LocalDateTime.now().plusSeconds(1);
        sampleUser.setPasswordChangedAt(passwordChangedAt);
        when(userRepository.findByEmail("quochuy@example.com")).thenReturn(Optional.of(sampleUser));
        when(jwtUtils.generateToken("quochuy@example.com", 1L, 100L)).thenReturn("token");

        LoginRequest req = new LoginRequest();
        req.setEmail("quochuy@example.com");
        req.setPassword("secret_pass");

        LocalDateTime before = LocalDateTime.now();
        authService.login(req);
        LocalDateTime after = LocalDateTime.now();

        assertThat(sampleUser.getLastLoginAt()).isNotNull();
        assertThat(sampleUser.getLastLoginAt()).isAfterOrEqualTo(before);
        assertThat(sampleUser.getLastLoginAt()).isBeforeOrEqualTo(after);
        assertThat(sampleUser.getPasswordChangedAt()).isEqualTo(passwordChangedAt);
    }

    @Test
    @DisplayName("forgotPassword() gọi invalidateAllActiveByEmailAndType để vô hiệu hóa toàn bộ OTP active cũ atomically")
    void forgotPassword_ShouldInvalidateAllPreviousActiveOtpsAtomically() {
        when(userRepository.findByEmail("quochuy@example.com")).thenReturn(Optional.of(sampleUser));

        authService.forgotPassword("quochuy@example.com");

        verify(authOtpRepository, times(1)).invalidateAllActiveByEmailAndType("quochuy@example.com", AuthOtp.OtpType.PASSWORD_RESET);
    }

    @Test
    @DisplayName("forgotPassword() propagate exception khi EmailService SMTP thất bại để Spring rollback transaction (OTP không được lưu)")
    void forgotPassword_WhenEmailServiceFails_ShouldPropagateExceptionAndRollback() {
        when(userRepository.findByEmail("quochuy@example.com")).thenReturn(Optional.of(sampleUser));
        doThrow(new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE, "SMTP down"))
                .when(emailService).sendPasswordResetOtp(eq("quochuy@example.com"), anyString());

        // Exception phải được propagate để transaction rollback; OTP không được commit
        assertThatThrownBy(() -> authService.forgotPassword("quochuy@example.com"))
                .isInstanceOf(ResponseStatusException.class)
                .satisfies(ex -> assertThat(((ResponseStatusException) ex).getStatusCode())
                        .isEqualTo(HttpStatus.SERVICE_UNAVAILABLE));
    }

    @Test
    @DisplayName("forgotPassword() gọi acquirePgAdvisoryLock để đồng bộ đa replica")
    void forgotPassword_ShouldAcquirePgAdvisoryLock() {
        when(userRepository.findByEmail("quochuy@example.com")).thenReturn(Optional.of(sampleUser));

        authService.forgotPassword("quochuy@example.com");

        verify(authOtpRepository, times(1)).acquirePgAdvisoryLock("otp:forgot:quochuy@example.com");
    }

    @Test
    @DisplayName("sendEmailVerification() gọi acquirePgAdvisoryLock để đồng bộ đa replica")
    void sendEmailVerification_ShouldAcquirePgAdvisoryLock() {
        when(userRepository.findByEmail("quochuy@example.com")).thenReturn(Optional.of(sampleUser));

        authService.sendEmailVerification("quochuy@example.com");

        verify(authOtpRepository, times(1)).acquirePgAdvisoryLock("otp:verify:quochuy@example.com");
    }
}
