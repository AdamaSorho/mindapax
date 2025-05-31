package com.adamasorho.mindapax_backend.service.impl;

import java.util.Optional;
import java.util.UUID;
import java.util.Date;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

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

    private final RefreshTokenRepository refreshTokenRepository;

    public RefreshTokenServiceImpl(RefreshTokenRepository refreshTokenRepository) {
        this.refreshTokenRepository = refreshTokenRepository;
    }

    public RefreshToken createRefreshToken(User user) {
      Optional<RefreshToken> previousToken = refreshTokenRepository.findByUser(user);
      if (previousToken.isPresent()) {
          refreshTokenRepository.delete(previousToken.get());
      }
        RefreshToken refreshToken = new RefreshToken();
        refreshToken.setUser(user);
        refreshToken.setToken(UUID.randomUUID().toString()); // generate random secure token
        refreshToken.setExpiryDate(new Date(System.currentTimeMillis() + refreshTokenDurationMs));
        return refreshTokenRepository.save(refreshToken);
    }

    public Optional<RefreshToken> findByToken(String token) {
        return refreshTokenRepository.findByToken(token);
    }

    public RefreshToken verifyExpiration(RefreshToken token) {
        if (token.getExpiryDate().before(new Date())) {
            refreshTokenRepository.delete(token);
            throw new RuntimeException("Refresh token expired. Please login again.");
        }
        return token;
    }

    public void deleteByUser(User user) {
        refreshTokenRepository.deleteByUser(user);
    }
}
