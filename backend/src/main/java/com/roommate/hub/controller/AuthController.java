package com.roommate.hub.controller;

import com.roommate.hub.dto.AuthResponse;
import com.roommate.hub.dto.ChangePasswordRequest;
import com.roommate.hub.dto.LoginRequest;
import com.roommate.hub.dto.RegisterRequest;
import com.roommate.hub.service.AuthService;
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

    @PostMapping("/register")
    public ResponseEntity<AuthResponse> register(@Valid @RequestBody RegisterRequest request) {
        return ResponseEntity.ok(authService.register(request));
    }

    @PostMapping("/login")
    public ResponseEntity<AuthResponse> login(@Valid @RequestBody LoginRequest request) {
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
    public ResponseEntity<Map<String, String>> logout() {
        return ResponseEntity.ok(Map.of("message", "Đăng xuất thành công"));
    }

    @PostMapping("/refresh-token")
    public ResponseEntity<Map<String, Object>> refreshToken(
            @RequestBody(required = false) Map<String, String> body,
            Authentication authentication) {
        String email = authentication != null && authentication.isAuthenticated() && !"anonymousUser".equals(authentication.getName())
                ? authentication.getName()
                : (body != null ? body.get("email") : null);
        if (email == null || email.isBlank()) {
            return ResponseEntity.ok(Map.of("message", "Token đã được làm mới"));
        }
        String newToken = authService.refreshToken(email);
        return ResponseEntity.ok(Map.of("token", newToken, "accessToken", newToken, "message", "Token đã được làm mới thành công"));
    }
}