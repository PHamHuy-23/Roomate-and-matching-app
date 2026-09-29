package com.roommate.hub.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
@Table(name = "users")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class User {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true, length = 100)
    private String email;

    @Column(nullable = false, length = 255)
    private String passwordHash;

    @Column(nullable = false, length = 100)
    private String fullName;

    @Column(nullable = false, length = 10)
    private String gender; // MALE, FEMALE

    @Column(length = 20)
    private String phone;

    @Column(length = 255)
    private String avatarUrl;

    @Column(name = "birth_date")
    private LocalDate birthDate;

    @Column(length = 150)
    private String university;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private Role role; // ROLE_USER, ROLE_ADMIN

    @CreationTimestamp
    @Column(updatable = false)
    private LocalDateTime createdAt;

    @Column(name = "status", nullable = false)
    @Builder.Default
    private String status = "ACTIVE"; // Mặc định tài khoản mới tạo là ACTIVE

    @Column(name = "password_changed_at")
    private LocalDateTime passwordChangedAt;

    @Column(name = "logged_out_at")
    private LocalDateTime loggedOutAt;

    /** Timestamp của lần đăng nhập thành công gần nhất.
     *  JwtAuthenticationFilter dùng trường này để vô hiệu hóa
     *  mọi access token được phát hành trước mốc này (từ phiên đăng nhập cũ),
     *  KHÔNG xóa loggedOutAt để mốc thu hồi logout không bị mất.
     */
    @Column(name = "last_login_at")
    private LocalDateTime lastLoginAt;

    public enum Role {
        ROLE_USER, ROLE_ADMIN
    }
}
