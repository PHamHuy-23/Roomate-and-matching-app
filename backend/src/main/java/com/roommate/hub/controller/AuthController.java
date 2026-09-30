package com.roommate.hub.controller;

import com.roommate.hub.dto.AuthResponse;
import com.roommate.hub.dto.ChangePasswordRequest;
import com.roommate.hub.dto.LoginRequest;
import com.roommate.hub.dto.RegisterRequest;
import com.roommate.hub.service.AuthService;
import com.roommate.hub.service.IpRateLimitService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/v1/auth")
@RequiredArgsConstructor
public class AuthController {

    private final AuthService authService;
    private final IpRateLimitService ipRateLimitService;

    /** Trích xuất IP thực của client, ưu tiên X-Forwarded-For khi đứng sau reverse proxy. */
    private String extractClientIp(HttpServletRequest request) {
        String forwarded = request.getHeader("X-Forwarded-For");
        if (forwarded != null && !forwarded.isBlank()) {
            return forwarded.split(",")[0].trim();
        }
        return request.getRemoteAddr();
    }

    @PostMapping("/register")
    public ResponseEntity<AuthResponse> register(@Valid @RequestBody RegisterRequest request) {
        return ResponseEntity.ok(authService.register(request));
    }

    @PostMapping("/login")
    public ResponseEntity<AuthResponse> login(
            @Valid @RequestBody LoginRequest request,
            HttpServletRequest httpRequest) {
        ipRateLimitService.checkAndIncrement(extractClientIp(httpRequest), "login");
        return ResponseEntity.ok(authService.login(request));
    }

    @PutMapping("/change-password")
    public ResponseEntity<Map<String, String>> changePassword(
            @Valid @RequestBody ChangePasswordRequest request,
            Authentication authentication) {
        if (authentication == null || !authentication.isAuthenticated()) {
            throw new org.springframework.web.server.ResponseStatusException(org.springframework.http.HttpStatus.UNAUTHORIZED);
        }
        authService.changePassword(authentication.getName(), request.getOldPassword(), request.getNewPassword());
        return ResponseEntity.ok(Map.of("message", "Đổi mật khẩu thành công!"));
    }

    @PostMapping("/logout")
    public ResponseEntity<Map<String, String>> logout(
            @RequestBody(required = false) Map<String, String> body,
            Authentication authentication) {
        String refreshToken = body != null ? body.get("refreshToken") : null;
        String email = (authentication != null && authentication.isAuthenticated()) ? authentication.getName() : null;
        authService.logout(refreshToken, email);
        return ResponseEntity.ok(Map.of("message", "Đăng xuất thành công"));
    }

    @PostMapping("/refresh-token")
    public ResponseEntity<Map<String, Object>> refreshToken(
            @RequestBody(required = false) Map<String, String> body) {
        String token = body != null ? (body.get("refreshToken") != null ? body.get("refreshToken") : body.get("token")) : null;
        Map<String, Object> result = authService.refreshToken(token);
        return ResponseEntity.ok(result);
    }

    @PostMapping("/forgot-password")
    public ResponseEntity<Map<String, String>> forgotPassword(
            @RequestBody Map<String, String> body,
            HttpServletRequest request) {
        // IP rate limit: chặn kẻ tấn công dùng vô số email khác nhau để gây tải BCrypt/DB
        ipRateLimitService.checkAndIncrement(extractClientIp(request), "forgot-password");
        String email = body != null ? body.get("email") : null;
        authService.forgotPassword(email);
        return ResponseEntity.ok(Map.of("message", "Mã xác nhận khôi phục mật khẩu đã được gửi đến email."));
    }

    @PostMapping("/send-verification-email")
    public ResponseEntity<Map<String, String>> sendVerificationEmail(
            @RequestBody Map<String, String> body,
            HttpServletRequest request) {
        // IP rate limit: chặn spam 5 email/giờ tới từng tài khoản từ nhiều IP khác nhau
        ipRateLimitService.checkAndIncrement(extractClientIp(request), "send-verification-email");
        String email = body != null ? body.get("email") : null;
        authService.sendEmailVerification(email);
        return ResponseEntity.ok(Map.of("message", "Mã xác minh đã được gửi đến email."));
    }

    @PostMapping("/reset-password")
    public ResponseEntity<Map<String, String>> resetPassword(@RequestBody Map<String, String> body) {
        String email = body != null ? body.get("email") : null;
        String code = body != null ? body.get("code") : null;
        String newPassword = body != null ? body.get("newPassword") : null;
        authService.resetPassword(email, code, newPassword);
        return ResponseEntity.ok(Map.of("message", "Đặt lại mật khẩu thành công!"));
    }

    @PostMapping("/verify-email")
    public ResponseEntity<Map<String, String>> verifyEmail(@RequestBody Map<String, String> body) {
        String email = body != null ? body.get("email") : null;
        String code = body != null ? body.get("code") : null;
        authService.verifyEmail(email, code);
        return ResponseEntity.ok(Map.of("message", "Xác minh email thành công!"));
    }
}
