package com.roommate.hub.config;

import io.jsonwebtoken.*;
import io.jsonwebtoken.security.Keys;
import org.springframework.stereotype.Component;
import org.springframework.beans.factory.annotation.Value;
import java.nio.charset.StandardCharsets;

import java.security.Key;
import java.util.Date;

@Component
public class JwtUtils {

    // Khóa bí mật tối thiểu 256-bit
    private static final long EXPIRATION_TIME = 86400000L; // 24 giờ

    private final Key key;

    public JwtUtils(@Value("${app.jwt.secret}") String secret) {
        if (secret == null || secret.length() < 32) throw new IllegalStateException("app.jwt.secret phải có ít nhất 32 ký tự");
        this.key = Keys.hmacShaKeyFor(secret.getBytes(StandardCharsets.UTF_8));
    }

    public String generateToken(String email, Long userId) {
        return Jwts.builder()
                .setSubject(email)
                .claim("userId", userId)
                .claim("token_type", "ACCESS")
                .setIssuedAt(new Date())
                .setExpiration(new Date(System.currentTimeMillis() + EXPIRATION_TIME))
                .signWith(key, SignatureAlgorithm.HS256)
                .compact();
    }

    public boolean isAccessToken(String token) {
        try {
            Claims claims = Jwts.parserBuilder().setSigningKey(key).build()
                    .parseClaimsJws(token).getBody();
            Object tokenType = claims.get("token_type");
            return tokenType == null || "ACCESS".equals(tokenType);
        } catch (Exception e) {
            return false;
        }
    }

    public String extractEmail(String token) {
        return Jwts.parserBuilder().setSigningKey(key).build()
                .parseClaimsJws(token).getBody().getSubject();
    }

    public Date extractIssuedAt(String token) {
        try {
            return Jwts.parserBuilder().setSigningKey(key).build()
                    .parseClaimsJws(token).getBody().getIssuedAt();
        } catch (Exception e) {
            return null;
        }
    }

    public boolean validateToken(String token) {
        try {
            Jwts.parserBuilder().setSigningKey(key).build().parseClaimsJws(token);
            return true;
        } catch (JwtException | IllegalArgumentException e) {
            return false;
        }
    }
}
