package com.roommate.hub.config;

import com.roommate.hub.repository.RefreshTokenRepository;
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
    private final RefreshTokenRepository refreshTokenRepository;

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
                            // Bind access to a persisted grant, not second-resolution JWT timestamps.
                            // Old JWTs without this claim must refresh or log in again after upgrade.
                            Long grantId = jwtUtils.extractRefreshTokenId(token);
                            if (grantId == null) return;
                            boolean activeGrant = refreshTokenRepository
                                    .findFirstByUserIdAndRevokedFalseOrderByIdDesc(user.getId())
                                    .filter(grant -> grantId.equals(grant.getId()) && grant.isActive())
                                    .isPresent();
                            if (!activeGrant) return;

                            var auth = new UsernamePasswordAuthenticationToken(user.getEmail(), null,
                                    List.of(new SimpleGrantedAuthority(user.getRole().name())));
                            SecurityContextHolder.getContext().setAuthentication(auth);
                        });
            }
        }
        chain.doFilter(request, response);
    }
}
