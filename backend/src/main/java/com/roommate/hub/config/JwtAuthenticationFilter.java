package com.roommate.hub.config;

import com.roommate.hub.entity.User;
import com.roommate.hub.repository.UserRepository;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;
import java.io.IOException;
import java.util.List;

@Component
@RequiredArgsConstructor
public class JwtAuthenticationFilter extends OncePerRequestFilter {
    private final JwtUtils jwtUtils;
    private final UserRepository userRepository;

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain chain)
            throws ServletException, IOException {
        String header = request.getHeader("Authorization");
        if (header != null && header.startsWith("Bearer ")) {
            String token = header.substring(7);
            if (jwtUtils.validateToken(token) && jwtUtils.isAccessToken(token)) {
                String email = jwtUtils.extractEmail(token);
                userRepository.findByEmail(email).filter(user -> "ACTIVE".equalsIgnoreCase(user.getStatus()))
                        .ifPresent(user -> {
                            java.util.Date issuedAt = jwtUtils.extractIssuedAt(token);

                            // 1. Từ chối token phát hành trước lần thay mật khẩu gần nhất
                            if (user.getPasswordChangedAt() != null && issuedAt != null) {
                                java.time.Instant changedInstant = user.getPasswordChangedAt()
                                        .atZone(java.time.ZoneId.systemDefault())
                                        .toInstant();
                                if (issuedAt.toInstant().getEpochSecond() <= changedInstant.getEpochSecond()) {
                                    return; // Token revoked due to password change or reset
                                }
                            }

                            // 2. Từ chối token từ phiên đăng nhập cũ (issuedAt <= lastLoginAt).
                            //    login() đặt lastLoginAt = now()-1s; token mới phát hành tại giây hiện tại
                            //    sẽ có issuedAt > lastLoginAt và được chấp nhận.
                            //    Token từ phiên trước (issuedAt <= lastLoginAt) bị từ chối kể cả khi
                            //    cùng giây với lastLoginAt, loại bỏ cửa sổ 1 giây còn sót lại với so sánh (<).
                            if (user.getLastLoginAt() != null && issuedAt != null) {
                                java.time.Instant lastLoginInstant = user.getLastLoginAt()
                                        .atZone(java.time.ZoneId.systemDefault())
                                        .toInstant();
                                if (issuedAt.toInstant().getEpochSecond() <= lastLoginInstant.getEpochSecond()) {
                                    return; // Token từ phiên đăng nhập trước, bị vô hiệu hóa
                                }
                            }

                            // 3. Từ chối token của phiên hiện tại nếu người dùng đã logout.
                            //    Chỉ áp dụng khi người dùng chưa đăng nhập lại sau logout
                            //    (tức là loggedOutAt > lastLoginAt hoặc lastLoginAt chưa được đặt).
                            if (user.getLoggedOutAt() != null && issuedAt != null) {
                                boolean reloggedInAfterLogout = user.getLastLoginAt() != null
                                        && user.getLastLoginAt().isAfter(user.getLoggedOutAt());
                                if (!reloggedInAfterLogout) {
                                    java.time.Instant logoutInstant = user.getLoggedOutAt()
                                            .atZone(java.time.ZoneId.systemDefault())
                                            .toInstant();
                                    if (issuedAt.toInstant().getEpochSecond() <= logoutInstant.getEpochSecond()) {
                                        return; // Token revoked due to logout
                                    }
                                }
                            }

                            var auth = new UsernamePasswordAuthenticationToken(user.getEmail(), null,
                                    List.of(new SimpleGrantedAuthority(user.getRole().name())));
                            SecurityContextHolder.getContext().setAuthentication(auth);
                        });
            }
        }
        chain.doFilter(request, response);
    }
}
