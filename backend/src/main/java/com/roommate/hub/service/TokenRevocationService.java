package com.roommate.hub.service;

import com.roommate.hub.entity.RefreshToken;
import com.roommate.hub.entity.User;
import com.roommate.hub.repository.RefreshTokenRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class TokenRevocationService {

    private final RefreshTokenRepository refreshTokenRepository;

    @Transactional
    public void revokeAllUserTokens(User user) {
        refreshTokenRepository.revokeAllByUser(user);
    }

    @Transactional
    public void revokeToken(RefreshToken token) {
        token.setRevoked(true);
        refreshTokenRepository.saveAndFlush(token);
    }
}
