package com.roommate.hub.service;

import com.roommate.hub.config.JwtUtils;
import com.roommate.hub.dto.AuthResponse;
import com.roommate.hub.dto.LoginRequest;
import com.roommate.hub.dto.RegisterRequest;
import com.roommate.hub.entity.AuthOtp;
import com.roommate.hub.entity.RefreshToken;
import com.roommate.hub.entity.User;
import com.roommate.hub.exception.ResourceNotFoundException;
import com.roommate.hub.repository.AuthOtpRepository;
import com.roommate.hub.repository.RefreshTokenRepository;
import com.roommate.hub.repository.UserRepository;
import com.roommate.hub.validation.PasswordPolicy;
import jakarta.validation.Validator;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.time.Duration;
import java.time.LocalDateTime;
import java.util.Map;
import java.util.Locale;
import java.util.Optional;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Slf4j
public class AuthService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtUtils jwtUtils;
    private final AuthOtpRepository authOtpRepository;
    private final EmailService emailService;
    private final RefreshTokenRepository refreshTokenRepository;
    private final OtpAttemptService otpAttemptService;
    private final TokenRevocationService tokenRevocationService;
    private final Validator validator;

    @org.springframework.beans.factory.annotation.Autowired(required = false)
    private org.springframework.transaction.support.TransactionTemplate transactionTemplate;

    private <T> T runInTransaction(org.springframework.transaction.support.TransactionCallback<T> action) {
        if (transactionTemplate != null) {
            return transactionTemplate.execute(action);
        }
        return action.doInTransaction(null);
    }

    @Transactional
    public AuthResponse register(RegisterRequest req) {
        // Keep non-HTTP callers subject to the same constraints before any DB write.
        validator.validate(req).stream().sorted(java.util.Comparator.comparing(v -> v.getPropertyPath().toString()))
                .findFirst().ifPresent(v -> { throw new IllegalArgumentException(v.getMessage()); });
        String normalizedEmail = req.getEmail().trim().toLowerCase(Locale.ROOT);
        if (userRepository.existsByEmail(normalizedEmail)) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Email đã được đăng ký!");
        }

        User user = User.builder()
                .email(normalizedEmail)
                .passwordHash(passwordEncoder.encode(req.getPassword()))
                .fullName(req.getFullName())
                .gender(req.getGender().toUpperCase(Locale.ROOT))
                .phone(req.getPhone())
                .birthDate(req.getBirthDate())
                .university(req.getUniversity())
                .role(User.Role.ROLE_USER)
                .build();

        userRepository.save(user);

        Map<String, Object> rtData = createRefreshToken(user);
        String rawRefreshToken = (String) rtData.get("rawToken");
        String token = createAccessToken(user, rtData);
        return AuthResponse.builder()
                .token(token)
                .refreshToken(rawRefreshToken)
                .userId(user.getId())
                .email(user.getEmail())
                .fullName(user.getFullName())
                .gender(user.getGender())
                .birthDate(user.getBirthDate())
                .university(user.getUniversity())
                .role(user.getRole().name())
                .phone(user.getPhone())
                .avatarUrl(user.getAvatarUrl())
                .build();
    }

    @Transactional
    public AuthResponse login(LoginRequest req) {
        String normalizedEmail = req.getEmail().trim().toLowerCase();
        User user = userRepository.findByEmail(normalizedEmail)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Email hoặc mật khẩu không chính xác!"));

        if (!matchesExistingPassword(req.getPassword(), user.getPasswordHash())) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Email hoặc mật khẩu không chính xác!");
        }

        if (!"ACTIVE".equalsIgnoreCase(user.getStatus())) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Tài khoản của bạn đã bị khóa hoặc chưa được kích hoạt!");
        }

        // Timestamps are audit data; grant revocation distinguishes old and new sessions.
        user.setLastLoginAt(LocalDateTime.now());
        userRepository.save(user);

        // Mỗi lần đăng nhập mới tạo một phiên duy nhất. Refresh token cũ không còn
        // được phép cấp access token mới sau khi người dùng đăng nhập lại.
        tokenRevocationService.revokeAllUserTokens(user);
        Map<String, Object> rtData = createRefreshToken(user);
        String rawRefreshToken = (String) rtData.get("rawToken");
        String token = createAccessToken(user, rtData);
        return AuthResponse.builder()
                .token(token)
                .refreshToken(rawRefreshToken)
                .userId(user.getId())
                .email(user.getEmail())
                .fullName(user.getFullName())
                .gender(user.getGender())
                .birthDate(user.getBirthDate())
                .university(user.getUniversity())
                .role(user.getRole().name())
                .phone(user.getPhone())
                .avatarUrl(user.getAvatarUrl())
                .build();
    }

    @Transactional
    public void changePassword(String email, String oldPassword, String newPassword) {
        PasswordPolicy.requireValid(newPassword);
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new ResourceNotFoundException("Người dùng không tồn tại!"));

        if (!matchesExistingPassword(oldPassword, user.getPasswordHash())) {
            throw new IllegalArgumentException("Mật khẩu hiện tại không chính xác!");
        }

        user.setPasswordHash(passwordEncoder.encode(newPassword));
        user.setPasswordChangedAt(LocalDateTime.now());
        userRepository.save(user);

        tokenRevocationService.revokeAllUserTokens(user);
    }

    private boolean matchesExistingPassword(String password, String hash) {
        // Do not apply the new minimum to legacy accounts, but never pass oversized input to BCrypt.
        return password != null
                && password.getBytes(StandardCharsets.UTF_8).length <= PasswordPolicy.MAX_UTF8_BYTES
                && passwordEncoder.matches(password, hash);
    }

    @Transactional
    public void logout(String refreshTokenString, String authenticatedEmail) {
        User user = null;
        if (refreshTokenString != null && !refreshTokenString.isBlank()) {
            String tokenHash = hashToken(refreshTokenString.trim());
            Optional<RefreshToken> rtOpt = refreshTokenRepository.findByToken(tokenHash);
            if (rtOpt.isPresent()) {
                RefreshToken token = rtOpt.get();
                tokenRevocationService.revokeToken(token);
                user = token.getUser();
            }
        }
        if (authenticatedEmail != null && !authenticatedEmail.isBlank()) {
            Optional<User> uOpt = userRepository.findByEmail(authenticatedEmail.trim().toLowerCase());
            if (uOpt.isPresent()) {
                user = uOpt.get();
            }
        }
        if (user != null) {
            user.setLoggedOutAt(LocalDateTime.now());
            userRepository.save(user);
            tokenRevocationService.revokeAllUserTokens(user);
        }
    }

    @Transactional
    public String refreshToken(String token, String authenticatedEmail) {
        Map<String, Object> result = refreshToken(token);
        return (String) result.get("token");
    }

    @Transactional(noRollbackFor = {ResponseStatusException.class})
    public Map<String, Object> refreshToken(String refreshTokenString) {
        if (refreshTokenString == null || refreshTokenString.isBlank()) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Vui lòng cung cấp Refresh Token hợp lệ!");
        }

        String trimmed = refreshTokenString.trim();
        // Phân tách rõ ràng: Từ chối Access Token truyền vào endpoint refresh
        if (trimmed.startsWith("ey") && jwtUtils.isAccessToken(trimmed)) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Access token không thể dùng để làm mới phiên. Vui lòng cung cấp Refresh Token!");
        }

        String tokenHash = hashToken(trimmed);

        // Chống race condition: Dùng Pessimistic Write Lock serialize các request đồng thời
        RefreshToken tokenEntity = refreshTokenRepository.findByTokenForUpdate(tokenHash)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Refresh token không tồn tại hoặc không hợp lệ!"));

        User user = tokenEntity.getUser();

        // Phát hiện lạm dụng / tấn công phát lại (Token Reuse Detection):
        // Nếu một token đã thu hồi được dùng lại, có thể chuỗi token đã bị lộ -> thu hồi toàn bộ phiên của tài khoản
        // noRollbackFor commits revocation even when this method throws UNAUTHORIZED.
        if (tokenEntity.isRevoked()) {
            tokenRevocationService.revokeAllUserTokens(user);
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Cảnh báo bảo mật: Refresh token đã bị thu hồi trước đó. Toàn bộ phiên đăng nhập đã bị hủy để bảo vệ tài khoản!");
        }

        if (tokenEntity.isExpired()) {
            tokenRevocationService.revokeToken(tokenEntity);
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Refresh token đã hết hạn. Vui lòng đăng nhập lại!");
        }

        if (!"ACTIVE".equalsIgnoreCase(user.getStatus())) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Tài khoản của bạn đã bị khóa hoặc không hoạt động!");
        }

        if (user.getPasswordChangedAt() != null && tokenEntity.getCreatedAt() != null) {
            if (tokenEntity.getCreatedAt().isBefore(user.getPasswordChangedAt())) {
                tokenRevocationService.revokeToken(tokenEntity);
                throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Phiên đăng nhập đã hết hiệu lực do mật khẩu đã được thay đổi. Vui lòng đăng nhập lại!");
            }
        }

        // Xoay vòng Refresh Token (Refresh Token Rotation):
        // Thu hồi token cũ và sinh một refresh token mới duy nhất
        tokenEntity.setRevoked(true);
        refreshTokenRepository.save(tokenEntity);

        Map<String, Object> newRtData = createRefreshToken(user);
        String newRawRefreshToken = (String) newRtData.get("rawToken");
        String newAccessToken = createAccessToken(user, newRtData);

        return Map.of(
                "token", newAccessToken,
                "accessToken", newAccessToken,
                "refreshToken", newRawRefreshToken,
                "message", "Token đã được làm mới thành công"
        );
    }

    private Map<String, Object> createRefreshToken(User user) {
        String rawToken = UUID.randomUUID().toString().replace("-", "")
                + UUID.randomUUID().toString().replace("-", "");
        String tokenHash = hashToken(rawToken);
        RefreshToken rt = RefreshToken.builder()
                .user(user)
                .token(tokenHash)
                .expiresAt(LocalDateTime.now().plusDays(7))
                .revoked(false)
                .build();
        rt = refreshTokenRepository.save(rt);
        return Map.of("rawToken", rawToken, "entity", rt);
    }

    private String createAccessToken(User user, Map<String, Object> refreshTokenData) {
        RefreshToken grant = (RefreshToken) refreshTokenData.get("entity");
        return jwtUtils.generateToken(user.getEmail(), user.getId(), grant.getId());
    }

    private String hashToken(String rawToken) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] encodedHash = digest.digest(rawToken.getBytes(StandardCharsets.UTF_8));
            StringBuilder hexString = new StringBuilder(2 * encodedHash.length);
            for (byte b : encodedHash) {
                String hex = Integer.toHexString(0xff & b);
                if (hex.length() == 1) {
                    hexString.append('0');
                }
                hexString.append(hex);
            }
            return hexString.toString();
        } catch (NoSuchAlgorithmException e) {
            throw new RuntimeException("SHA-256 algorithm not available", e);
        }
    }

    private final SecureRandom secureRandom = new SecureRandom();
    private static final int STRIPED_LOCK_SIZE = 128;
    private final Object[] emailLocks = new Object[STRIPED_LOCK_SIZE];
    {
        for (int i = 0; i < STRIPED_LOCK_SIZE; i++) {
            emailLocks[i] = new Object();
        }
    }

    private Object getEmailLock(String email) {
        int hash = Math.abs(email.hashCode() % STRIPED_LOCK_SIZE);
        return emailLocks[hash];
    }

    private String generateOtp() {
        return String.format("%06d", secureRandom.nextInt(1_000_000));
    }

    private void tryAcquireAdvisoryLock(String key) {
        try {
            authOtpRepository.acquirePgAdvisoryLock(key);
        } catch (Exception ignored) {
            // H2 in tests or non-Postgres databases do not support pg_advisory_xact_lock;
            // fall back cleanly to JVM striped lock
        }
    }

    /** Thời gian phản hồi tối thiểu (ms) cho cả hai nhánh real/fake email trong các endpoint OTP.
     *  Đảm bảo kẻ tấn công không thể phân biệt email tồn tại / không tồn tại qua độ trễ.
     *  Giá trị 800ms đủ lớn để bao phủ hầu hết các cuộc gọi SMTP thực tế (&lt;500ms P95).
     */
    private static final long OTP_RESPONSE_TARGET_MS = 800L;

    /**
     * Chạy {@code action} bên trong JVM lock, đo thời gian tổng,
     * sau đó pad thêm sleep để tổng đạt ít nhất {@link #OTP_RESPONSE_TARGET_MS} ms.
     * Nếu action ném exception (ví dụ SMTP 503 hay rate-limit 429),
     * exception được giữ lại và rethrow SAU KHI đã pad — đảm bảo
     * phân phối độ trễ đồng đều giữa nhánh thành công và lỗi.
     */
    private void paddedOtpOperation(String emailLockKey, Runnable action) {
        long start = System.currentTimeMillis();
        RuntimeException caught = null;
        synchronized (getEmailLock(emailLockKey)) {
            try {
                action.run();
            } catch (RuntimeException e) {
                caught = e;
            }
        }
        long elapsed = System.currentTimeMillis() - start;
        if (elapsed < OTP_RESPONSE_TARGET_MS) {
            try {
                Thread.sleep(OTP_RESPONSE_TARGET_MS - elapsed);
            } catch (InterruptedException ie) {
                Thread.currentThread().interrupt();
            }
        }
        if (caught != null) throw caught;
    }

    public void forgotPassword(String email) {
        if (email == null || email.isBlank()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Email không được để trống!");
        }
        String normalizedEmail = email.trim().toLowerCase();

        paddedOtpOperation(normalizedEmail, () ->
            runInTransaction(status -> {
                tryAcquireAdvisoryLock("otp:forgot:" + normalizedEmail);

                // Luôn áp dụng Rate Limit (cooldown 60s và giới hạn 5 lần/giờ) cho mọi email dù tồn tại hay không (chống account enumeration)
                enforceOtpRateLimit(normalizedEmail, AuthOtp.OtpType.PASSWORD_RESET);

                String rawOtp = generateOtp();
                String hashedOtp = passwordEncoder.encode(rawOtp);

                Optional<User> userOpt = userRepository.findByEmail(normalizedEmail);
                if (userOpt.isEmpty() || "LOCKED".equalsIgnoreCase(userOpt.get().getStatus()) || "BANNED".equalsIgnoreCase(userOpt.get().getStatus())) {
                    // Chống dò quét tài khoản (Account Enumeration Prevention - OWASP):
                    // Lưu AuthOtp đã dùng (used=true) để ghi nhận rate limit/cooldown cho email này
                    // và tiêu tốn cùng lượng thời gian tính toán DB/BCrypt như với email thật.
                    AuthOtp dummyOtp = AuthOtp.builder()
                            .email(normalizedEmail)
                            .otpCode(hashedOtp)
                            .type(AuthOtp.OtpType.PASSWORD_RESET)
                            .expiresAt(LocalDateTime.now())
                            .used(true)
                            .failedAttempts(5)
                            .build();
                    authOtpRepository.save(dummyOtp);
                    log.info("[FORGOT_PASSWORD] Yêu cầu đặt lại mật khẩu cho email không tồn tại hoặc bị khóa: {}", maskEmail(normalizedEmail));

                    // Giả lập độ trễ SMTP và kiểm tra mail service readiness để chống dò quét tài khoản (Account Enumeration)
                    emailService.simulateDeliveryDelay();
                } else {
                    AuthOtp otpEntity = AuthOtp.builder()
                            .email(normalizedEmail)
                            .otpCode(hashedOtp)
                            .type(AuthOtp.OtpType.PASSWORD_RESET)
                            .expiresAt(LocalDateTime.now().plusMinutes(15))
                            .used(false)
                            .failedAttempts(0)
                            .build();
                    authOtpRepository.save(otpEntity);

                    // Gửi email đồng bộ trong transaction: nếu SMTP thất bại, transaction rollback và không lưu OTP/rate-limit sai lệch
                    emailService.sendPasswordResetOtp(normalizedEmail, rawOtp);
                }
                return null;
            })
        );
    }

    @Transactional(noRollbackFor = {ResponseStatusException.class})
    public void resetPassword(String email, String code, String newPassword) {
        // Reject invalid passwords BEFORE consuming an OTP or changing credentials/tokens.
        PasswordPolicy.requireValid(newPassword);
        if (email == null || email.isBlank()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Email không được để trống!");
        }
        if (code == null || !code.matches("[0-9]{6}")) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Mã xác nhận gồm 6 chữ số không hợp lệ!");
        }
        String normalizedEmail = email.trim().toLowerCase();
        AuthOtp otpEntity = validateAndConsumeOtp(normalizedEmail, code, AuthOtp.OtpType.PASSWORD_RESET);

        User user = userRepository.findByEmail(normalizedEmail)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Không tìm thấy tài khoản với email này!"));

        user.setPasswordHash(passwordEncoder.encode(newPassword));
        user.setPasswordChangedAt(LocalDateTime.now());
        userRepository.save(user);

        tokenRevocationService.revokeAllUserTokens(user);
    }

    public void sendEmailVerification(String email) {
        if (email == null || email.isBlank()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Email không được để trống!");
        }
        String normalizedEmail = email.trim().toLowerCase();

        paddedOtpOperation(normalizedEmail, () ->
            runInTransaction(status -> {
                tryAcquireAdvisoryLock("otp:verify:" + normalizedEmail);

                // Luôn áp dụng Rate Limit cho mọi email
                enforceOtpRateLimit(normalizedEmail, AuthOtp.OtpType.EMAIL_VERIFICATION);

                String rawOtp = generateOtp();
                String hashedOtp = passwordEncoder.encode(rawOtp);

                Optional<User> userOpt = userRepository.findByEmail(normalizedEmail);
                if (userOpt.isEmpty() || "LOCKED".equalsIgnoreCase(userOpt.get().getStatus()) || "BANNED".equalsIgnoreCase(userOpt.get().getStatus())) {
                    // Chống dò quét tài khoản (Account Enumeration Prevention - OWASP)
                    AuthOtp dummyOtp = AuthOtp.builder()
                            .email(normalizedEmail)
                            .otpCode(hashedOtp)
                            .type(AuthOtp.OtpType.EMAIL_VERIFICATION)
                            .expiresAt(LocalDateTime.now())
                            .used(true)
                            .failedAttempts(5)
                            .build();
                    authOtpRepository.save(dummyOtp);
                    log.info("[SEND_VERIFICATION] Yêu cầu gửi mã cho email không tồn tại hoặc bị khóa: {}", maskEmail(normalizedEmail));

                    // Giả lập độ trễ SMTP và kiểm tra mail service readiness để chống dò quét tài khoản
                    emailService.simulateDeliveryDelay();
                } else {
                    AuthOtp otpEntity = AuthOtp.builder()
                            .email(normalizedEmail)
                            .otpCode(hashedOtp)
                            .type(AuthOtp.OtpType.EMAIL_VERIFICATION)
                            .expiresAt(LocalDateTime.now().plusMinutes(15))
                            .used(false)
                            .failedAttempts(0)
                            .build();
                    authOtpRepository.save(otpEntity);

                    emailService.sendVerificationOtp(normalizedEmail, rawOtp);
                }
                return null;
            })
        );
    }

    @Transactional(noRollbackFor = {ResponseStatusException.class})
    public void verifyEmail(String email, String code) {
        if (email == null || email.isBlank() || code == null || code.trim().length() < 6) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Mã xác minh gồm 6 chữ số không hợp lệ!");
        }
        String normalizedEmail = email.trim().toLowerCase();
        AuthOtp otpEntity = validateAndConsumeOtp(normalizedEmail, code, AuthOtp.OtpType.EMAIL_VERIFICATION);

        User user = userRepository.findByEmail(normalizedEmail)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Không tìm thấy người dùng!"));

        if ("LOCKED".equalsIgnoreCase(user.getStatus()) || "BANNED".equalsIgnoreCase(user.getStatus())) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Tài khoản đã bị quản trị viên khóa, không thể kích hoạt lại bằng xác minh email!");
        }

        user.setStatus("ACTIVE");
        userRepository.save(user);
    }

    private void enforceOtpRateLimit(String email, AuthOtp.OtpType type) {
        // Giới hạn tần suất gửi: tối đa 5 yêu cầu trong 1 giờ
        long recentCount = authOtpRepository.countByEmailAndTypeAndCreatedAtAfter(
                email, type, LocalDateTime.now().minusHours(1));
        if (recentCount >= 5) {
            throw new ResponseStatusException(HttpStatus.TOO_MANY_REQUESTS, "Bạn đã yêu cầu gửi mã quá 5 lần trong 1 giờ. Vui lòng thử lại sau!");
        }

        // Thời gian chờ tối thiểu giữa 2 lần gửi liên tiếp (Cooldown 60 giây)
        authOtpRepository.findTopByEmailAndTypeOrderByCreatedAtDesc(email, type).ifPresent(latest -> {
            if (latest.getCreatedAt() != null) {
                long secondsSince = Duration.between(latest.getCreatedAt(), LocalDateTime.now()).getSeconds();
                if (secondsSince < 60) {
                    long wait = 60 - secondsSince;
                    throw new ResponseStatusException(HttpStatus.TOO_MANY_REQUESTS, "Vui lòng đợi " + wait + " giây trước khi yêu cầu mã mới!");
                }
            }
        });

        // Hủy hiệu lực toàn bộ các mã OTP chưa dùng trước đó cùng loại
        authOtpRepository.invalidateAllActiveByEmailAndType(email, type);
    }

    private AuthOtp validateAndConsumeOtp(String email, String inputCode, AuthOtp.OtpType type) {
        AuthOtp otpEntity = authOtpRepository
                .findTopByEmailAndTypeAndUsedFalseOrderByCreatedAtDesc(email, type)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.BAD_REQUEST, "Mã xác nhận không tồn tại hoặc đã hết hạn!"));

        if (otpEntity.isExpired()) {
            otpAttemptService.markUsed(otpEntity);
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Mã xác nhận đã hết hạn, vui lòng yêu cầu mã mới!");
        }

        if (!passwordEncoder.matches(inputCode.trim(), otpEntity.getOtpCode())) {
            int failedAttempts = otpAttemptService.recordFailedAttempt(otpEntity);
            int remaining = 5 - failedAttempts;
            if (remaining <= 0) {
                throw new ResponseStatusException(HttpStatus.TOO_MANY_REQUESTS, "Bạn đã nhập sai mã quá 5 lần. Mã xác nhận đã bị vô hiệu hóa vì lý do bảo mật!");
            }
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Mã xác nhận không chính xác! Bạn còn " + remaining + " lần thử.");
        }

        otpAttemptService.markUsed(otpEntity);
        return otpEntity;
    }

    private String maskEmail(String email) {
        if (email == null || !email.contains("@")) {
            return "***";
        }
        int atIndex = email.indexOf('@');
        if (atIndex <= 2) {
            return "**@" + email.substring(atIndex + 1);
        }
        return email.substring(0, 2) + "***@" + email.substring(atIndex + 1);
    }
}
