package com.roommate.hub.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;

@Entity
@Table(name = "auth_otps", indexes = {
        @Index(name = "idx_auth_otps_email_type", columnList = "email, type")
})
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AuthOtp {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 100)
    private String email;

    @Column(name = "otp_code", nullable = false, length = 255)
    private String otpCode;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 30)
    private OtpType type;

    @Column(name = "expires_at", nullable = false)
    private LocalDateTime expiresAt;

    @Column(nullable = false)
    @Builder.Default
    private boolean used = false;

    @Column(name = "failed_attempts", nullable = false)
    @Builder.Default
    private int failedAttempts = 0;

    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    public void incrementFailedAttempts() {
        this.failedAttempts++;
        if (this.failedAttempts >= 5) {
            this.used = true;
        }
    }

    public boolean isExpired() {
        return LocalDateTime.now().isAfter(expiresAt);
    }

    public boolean isValid(String inputCode) {
        return !used && !isExpired() && otpCode.equals(inputCode != null ? inputCode.trim() : "");
    }

    public enum OtpType {
        PASSWORD_RESET,
        EMAIL_VERIFICATION
    }
}
