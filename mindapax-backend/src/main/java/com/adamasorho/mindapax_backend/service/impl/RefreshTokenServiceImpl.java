package com.adamasorho.mindapax_backend.service.impl;

import java.util.Optional;
import java.util.UUID;
import java.util.Date;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import com.adamasorho.mindapax_backend.model.RefreshToken;
import com.adamasorho.mindapax_backend.model.User;
import com.adamasorho.mindapax_backend.repository.RefreshTokenRepository;
import com.adamasorho.mindapax_backend.service.RefreshTokenService;

import jakarta.transaction.Transactional;

@Service
@Transactional
public class RefreshTokenServiceImpl implements RefreshTokenService {
    @Value("${app.jwt.refresh-token.expiration-ms}")
    private Long refreshTokenDurationMs; // Example: 7 days = 604800000 ms
    @Value("${app.jwt.refresh-token.remember-me-expiration-ms:${app.jwt.refresh-token.expiration-ms}}")
    private Long rememberMeRefreshTokenDurationMs;

    private final RefreshTokenRepository refreshTokenRepository;

    public RefreshTokenServiceImpl(RefreshTokenRepository refreshTokenRepository) {
        this.refreshTokenRepository = refreshTokenRepository;
    }

    @Override
    public RefreshToken createRefreshToken(User user) {
        return createRefreshToken(user, false);
    }

    @Override
    public RefreshToken createRefreshToken(User user, boolean rememberMe) {
        Optional<RefreshToken> previousToken = refreshTokenRepository.findByUser(user);
        previousToken.ifPresent(refreshTokenRepository::delete);

        RefreshToken refreshToken = new RefreshToken();
        refreshToken.setUser(user);
        refreshToken.setToken(UUID.randomUUID().toString()); // generate random secure token
        long duration = rememberMe ? rememberMeRefreshTokenDurationMs : refreshTokenDurationMs;
        refreshToken.setExpiryDate(new Date(System.currentTimeMillis() + duration));
        refreshToken.setRememberMe(rememberMe);
        return refreshTokenRepository.save(refreshToken);
    }

    public Optional<RefreshToken> findByToken(String token) {
        return refreshTokenRepository.findByToken(token);
    }

    public RefreshToken verifyExpiration(RefreshToken token) {
        if (token.getExpiryDate().before(new Date())) {
            refreshTokenRepository.delete(token);
            throw new ResponseStatusException(
                HttpStatus.UNAUTHORIZED,
                "Refresh token expired. Please login again."
            );
        }
        return token;
    }

    public void deleteByUser(User user) {
        refreshTokenRepository.deleteByUser(user);
    }
}
