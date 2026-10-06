package com.roommate.hub.config;

import com.roommate.hub.entity.RefreshToken;
import com.roommate.hub.entity.User;
import com.roommate.hub.repository.RefreshTokenRepository;
import com.roommate.hub.repository.UserRepository;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.SignatureAlgorithm;
import io.jsonwebtoken.security.Keys;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.mock.web.MockFilterChain;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;
import org.springframework.security.core.context.SecurityContextHolder;

import java.nio.charset.StandardCharsets;
import java.time.LocalDateTime;
import java.util.Date;
import java.util.Optional;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class JwtAuthenticationFilterTest {
    private static final String TEST_SECRET = "test-only-secret-that-is-at-least-32-chars";
    @Mock UserRepository users;
    @Mock RefreshTokenRepository refreshTokens;
    private final JwtUtils jwtUtils = new JwtUtils(TEST_SECRET);
    private JwtAuthenticationFilter filter;
    private User user;
    private RefreshToken grant;

    @BeforeEach void setUp() {
        SecurityContextHolder.clearContext();
        filter = new JwtAuthenticationFilter(jwtUtils, users, refreshTokens);
        user = User.builder().id(1L).email("session@test.invalid").role(User.Role.ROLE_USER).build();
        grant = RefreshToken.builder().id(100L).user(user).expiresAt(LocalDateTime.now().plusDays(7)).build();
        lenient().when(users.findByEmail(user.getEmail())).thenReturn(Optional.of(user));
    }

    @AfterEach void tearDown() { SecurityContextHolder.clearContext(); }

    @Test void currentActiveGrantAuthenticatesEvenWithSameSecondAuditTimestamps() throws Exception {
        LocalDateTime sameSecond = LocalDateTime.now().withNano(0);
        user.setLastLoginAt(sameSecond);
        user.setLoggedOutAt(sameSecond);
        user.setPasswordChangedAt(sameSecond);
        when(refreshTokens.findFirstByUserIdAndRevokedFalseOrderByIdDesc(1L)).thenReturn(Optional.of(grant));
        request(jwtUtils.generateToken(user.getEmail(), 1L, 100L));
        assertThat(SecurityContextHolder.getContext().getAuthentication()).isNotNull();
        assertThat(SecurityContextHolder.getContext().getAuthentication().getName()).isEqualTo(user.getEmail());
    }

    @Test void tokensIssuedInExactlyTheSameSecondAreDistinguishedByGrant() throws Exception {
        grant.setId(101L);
        when(refreshTokens.findFirstByUserIdAndRevokedFalseOrderByIdDesc(1L)).thenReturn(Optional.of(grant));
        Date issuedAt = new Date(System.currentTimeMillis() / 1000 * 1000);
        String oldToken = signedToken(100L, issuedAt), newToken = signedToken(101L, issuedAt);
        assertThat(jwtUtils.extractIssuedAt(oldToken)).isEqualTo(jwtUtils.extractIssuedAt(newToken));
        request(oldToken);
        assertThat(SecurityContextHolder.getContext().getAuthentication()).isNull();
        request(newToken);
        assertThat(SecurityContextHolder.getContext().getAuthentication()).isNotNull();
    }

    @Test void noActiveGrantAfterLogoutRejectsToken() throws Exception {
        when(refreshTokens.findFirstByUserIdAndRevokedFalseOrderByIdDesc(1L)).thenReturn(Optional.empty());
        request(jwtUtils.generateToken(user.getEmail(), 1L, 100L));
        assertThat(SecurityContextHolder.getContext().getAuthentication()).isNull();
    }

    @Test void expiredGrantRejectsToken() throws Exception {
        grant.setExpiresAt(LocalDateTime.now().minusSeconds(1));
        when(refreshTokens.findFirstByUserIdAndRevokedFalseOrderByIdDesc(1L)).thenReturn(Optional.of(grant));
        request(jwtUtils.generateToken(user.getEmail(), 1L, 100L));
        assertThat(SecurityContextHolder.getContext().getAuthentication()).isNull();
    }

    @Test void grantBelongingToAnotherAccountCannotBeUsed() throws Exception {
        when(refreshTokens.findFirstByUserIdAndRevokedFalseOrderByIdDesc(1L)).thenReturn(Optional.of(grant));
        request(jwtUtils.generateToken(user.getEmail(), 1L, 999L));
        assertThat(SecurityContextHolder.getContext().getAuthentication()).isNull();
    }

    @Test void lockedAccountIsRejectedEvenWithActiveGrant() throws Exception {
        user.setStatus("LOCKED");
        request(jwtUtils.generateToken(user.getEmail(), 1L, 100L));
        assertThat(SecurityContextHolder.getContext().getAuthentication()).isNull();
        verifyNoInteractions(refreshTokens);
    }

    @Test void legacyJwtWithoutGrantMustRefreshOrLogInAgain() throws Exception {
        request(signedToken(null, new Date()));
        assertThat(SecurityContextHolder.getContext().getAuthentication()).isNull();
        verifyNoInteractions(refreshTokens);
    }

    @Test void invalidSignatureIsRejectedBeforeLookingUpAnAccount() throws Exception {
        request("invalid.jwt.signature");
        assertThat(SecurityContextHolder.getContext().getAuthentication()).isNull();
        verifyNoInteractions(users, refreshTokens);
    }

    private void request(String token) throws Exception {
        MockHttpServletRequest request = new MockHttpServletRequest("GET", "/api/v1/blocks");
        request.addHeader("Authorization", "Bearer " + token);
        MockFilterChain chain = new MockFilterChain();
        filter.doFilterInternal(request, new MockHttpServletResponse(), chain);
        assertThat(chain.getRequest()).isSameAs(request);
    }

    private String signedToken(Long grantId, Date issuedAt) {
        return Jwts.builder().setSubject(user.getEmail()).claim("userId", 1L).claim("token_type", "ACCESS")
                .claim("refresh_token_id", grantId).setIssuedAt(issuedAt)
                .setExpiration(new Date(System.currentTimeMillis() + 86400000L))
                .signWith(Keys.hmacShaKeyFor(TEST_SECRET.getBytes(StandardCharsets.UTF_8)), SignatureAlgorithm.HS256)
                .compact();
    }
}
