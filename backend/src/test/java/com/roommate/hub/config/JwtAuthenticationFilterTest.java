package com.roommate.hub.config;

import com.roommate.hub.entity.User;
import com.roommate.hub.repository.UserRepository;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.core.context.SecurityContextHolder;

import java.io.IOException;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.util.Date;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class JwtAuthenticationFilterTest {

    @Mock
    private JwtUtils jwtUtils;

    @Mock
    private UserRepository userRepository;

    @Mock
    private HttpServletRequest request;

    @Mock
    private HttpServletResponse response;

    @Mock
    private FilterChain filterChain;

    @InjectMocks
    private JwtAuthenticationFilter filter;

    private User sampleUser;

    @BeforeEach
    void setUp() {
        SecurityContextHolder.clearContext();
        sampleUser = User.builder()
                .id(1L)
                .email("quochuy@example.com")
                .role(User.Role.ROLE_USER)
                .status("ACTIVE")
                .build();
    }

    @AfterEach
    void tearDown() {
        SecurityContextHolder.clearContext();
    }

    @Test
    @DisplayName("doFilterInternal() xác thực thành công khi token hợp lệ và phiên hoạt động bình thường")
    void doFilter_WhenValidToken_ShouldAuthenticate() throws ServletException, IOException {
        when(request.getHeader("Authorization")).thenReturn("Bearer valid_jwt");
        when(jwtUtils.validateToken("valid_jwt")).thenReturn(true);
        when(jwtUtils.isAccessToken("valid_jwt")).thenReturn(true);
        when(jwtUtils.extractEmail("valid_jwt")).thenReturn("quochuy@example.com");
        when(jwtUtils.extractIssuedAt("valid_jwt")).thenReturn(new Date());
        when(userRepository.findByEmail("quochuy@example.com")).thenReturn(Optional.of(sampleUser));

        filter.doFilterInternal(request, response, filterChain);

        assertThat(SecurityContextHolder.getContext().getAuthentication()).isNotNull();
        assertThat(SecurityContextHolder.getContext().getAuthentication().getName()).isEqualTo("quochuy@example.com");
        verify(filterChain).doFilter(request, response);
    }

    @Test
    @DisplayName("doFilterInternal() từ chối token khi token được cấp trước thời điểm logout")
    void doFilter_WhenTokenIssuedBeforeLogout_ShouldReject() throws ServletException, IOException {
        LocalDateTime logoutTime = LocalDateTime.now();
        sampleUser.setLoggedOutAt(logoutTime);

        // Token issued 10 seconds before logout
        Date issuedAt = Date.from(logoutTime.minusSeconds(10).atZone(ZoneId.systemDefault()).toInstant());

        when(request.getHeader("Authorization")).thenReturn("Bearer stale_jwt");
        when(jwtUtils.validateToken("stale_jwt")).thenReturn(true);
        when(jwtUtils.isAccessToken("stale_jwt")).thenReturn(true);
        when(jwtUtils.extractEmail("stale_jwt")).thenReturn("quochuy@example.com");
        when(jwtUtils.extractIssuedAt("stale_jwt")).thenReturn(issuedAt);
        when(userRepository.findByEmail("quochuy@example.com")).thenReturn(Optional.of(sampleUser));

        filter.doFilterInternal(request, response, filterChain);

        assertThat(SecurityContextHolder.getContext().getAuthentication()).isNull();
        verify(filterChain).doFilter(request, response);
    }

    @Test
    @DisplayName("doFilterInternal() từ chối token khi token được cấp trong cùng giây với logout")
    void doFilter_WhenTokenIssuedSameSecondAsLogout_ShouldReject() throws ServletException, IOException {
        LocalDateTime logoutTime = LocalDateTime.now();
        sampleUser.setLoggedOutAt(logoutTime);

        // Token issued in same second as logout
        Date issuedAt = Date.from(logoutTime.atZone(ZoneId.systemDefault()).toInstant());

        when(request.getHeader("Authorization")).thenReturn("Bearer same_second_jwt");
        when(jwtUtils.validateToken("same_second_jwt")).thenReturn(true);
        when(jwtUtils.isAccessToken("same_second_jwt")).thenReturn(true);
        when(jwtUtils.extractEmail("same_second_jwt")).thenReturn("quochuy@example.com");
        when(jwtUtils.extractIssuedAt("same_second_jwt")).thenReturn(issuedAt);
        when(userRepository.findByEmail("quochuy@example.com")).thenReturn(Optional.of(sampleUser));

        filter.doFilterInternal(request, response, filterChain);

        assertThat(SecurityContextHolder.getContext().getAuthentication()).isNull();
        verify(filterChain).doFilter(request, response);
    }

    @Test
    @DisplayName("doFilterInternal() chấp nhận token mới được cấp sau thời điểm logout")
    void doFilter_WhenTokenIssuedAfterLogout_ShouldAuthenticate() throws ServletException, IOException {
        LocalDateTime logoutTime = LocalDateTime.now().minusMinutes(5);
        sampleUser.setLoggedOutAt(logoutTime);

        // Token issued now (after logout)
        Date issuedAt = new Date();

        when(request.getHeader("Authorization")).thenReturn("Bearer fresh_jwt");
        when(jwtUtils.validateToken("fresh_jwt")).thenReturn(true);
        when(jwtUtils.isAccessToken("fresh_jwt")).thenReturn(true);
        when(jwtUtils.extractEmail("fresh_jwt")).thenReturn("quochuy@example.com");
        when(jwtUtils.extractIssuedAt("fresh_jwt")).thenReturn(issuedAt);
        when(userRepository.findByEmail("quochuy@example.com")).thenReturn(Optional.of(sampleUser));

        filter.doFilterInternal(request, response, filterChain);

        assertThat(SecurityContextHolder.getContext().getAuthentication()).isNotNull();
        assertThat(SecurityContextHolder.getContext().getAuthentication().getName()).isEqualTo("quochuy@example.com");
        verify(filterChain).doFilter(request, response);
    }
}
