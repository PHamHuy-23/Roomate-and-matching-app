package com.roommate.hub.service;

import com.roommate.hub.config.JwtUtils;
import com.roommate.hub.dto.AuthResponse;
import com.roommate.hub.dto.LoginRequest;
import com.roommate.hub.dto.RegisterRequest;
import com.roommate.hub.entity.User;
import com.roommate.hub.repository.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class AuthServiceTest {

    @Mock
    private UserRepository userRepository;

    @Mock
    private PasswordEncoder passwordEncoder;

    @Mock
    private JwtUtils jwtUtils;

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
                .build();
    }

    @Test
    @DisplayName("P1: login() trả phone lấy chính xác từ User entity")
    void login_ShouldReturnPhoneFromUserEntity() {
        LoginRequest req = new LoginRequest();
        req.setEmail("quochuy@example.com");
        req.setPassword("password123");

        when(userRepository.findByEmail("quochuy@example.com")).thenReturn(Optional.of(sampleUser));
        when(passwordEncoder.matches("password123", "encoded_secret_pass")).thenReturn(true);
        when(jwtUtils.generateToken("quochuy@example.com", 1L)).thenReturn("jwt-sample-token");

        AuthResponse res = authService.login(req);

        assertThat(res).isNotNull();
        assertThat(res.getToken()).isEqualTo("jwt-sample-token");
        assertThat(res.getUserId()).isEqualTo(1L);
        assertThat(res.getEmail()).isEqualTo("quochuy@example.com");
        assertThat(res.getFullName()).isEqualTo("Phạm Quốc Huy");
        assertThat(res.getGender()).isEqualTo("MALE");
        assertThat(res.getRole()).isEqualTo("ROLE_USER");
        assertThat(res.getPhone()).isEqualTo("0901234567");
        verify(userRepository, times(1)).findByEmail("quochuy@example.com");
    }

    @Test
    @DisplayName("P1: register() trả lại đúng phone vừa đăng ký")
    void register_ShouldReturnExactPhoneProvided() {
        RegisterRequest req = new RegisterRequest();
        req.setEmail("newuser@example.com");
        req.setPassword("pass123");
        req.setFullName("Nguyễn Văn A");
        req.setGender("MALE");
        req.setPhone("0987654321");

        when(userRepository.existsByEmail("newuser@example.com")).thenReturn(false);
        when(passwordEncoder.encode("pass123")).thenReturn("encoded_pass");
        when(jwtUtils.generateToken(eq("newuser@example.com"), any())).thenReturn("jwt-registered-token");
        when(userRepository.save(any(User.class))).thenAnswer(invocation -> {
            User u = invocation.getArgument(0);
            u.setId(2L);
            return u;
        });

        AuthResponse res = authService.register(req);

        assertThat(res).isNotNull();
        assertThat(res.getToken()).isEqualTo("jwt-registered-token");
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
                .isInstanceOf(RuntimeException.class)
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
        when(passwordEncoder.matches("wrong_pass", "encoded_secret_pass")).thenReturn(false);

        assertThatThrownBy(() -> authService.login(req))
                .isInstanceOf(RuntimeException.class)
                .hasMessageContaining("Email hoặc mật khẩu không chính xác!");
    }
}
