package com.adamasorho.mindapax_backend.service.impl;

import java.security.SecureRandom;
import java.time.OffsetDateTime;
import java.util.Base64;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import com.adamasorho.mindapax_backend.model.PasswordResetToken;
import com.adamasorho.mindapax_backend.model.User;
import com.adamasorho.mindapax_backend.repository.PasswordResetTokenRepository;
import com.adamasorho.mindapax_backend.repository.UserRepository;
import com.adamasorho.mindapax_backend.service.PasswordResetService;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

import jakarta.transaction.Transactional;

@Service
@RequiredArgsConstructor
@Slf4j
@Transactional
public class PasswordResetServiceImpl implements PasswordResetService {

  private final UserRepository userRepository;
  private final PasswordResetTokenRepository tokenRepository;
  private final PasswordEncoder passwordEncoder;

  @Value("${mindapax.password-reset.expiration-minutes:30}")
  private long expirationMinutes;

  private static final SecureRandom RANDOM = new SecureRandom();

  @Override
  public void initiateReset(String email) {
    userRepository.findByEmail(email).ifPresentOrElse(user -> {
      tokenRepository.deleteByUser(user);
      final String tokenValue = generateToken();
      PasswordResetToken token = new PasswordResetToken();
      token.setToken(tokenValue);
      token.setUser(user);
      token.setExpiresAt(OffsetDateTime.now().plusMinutes(expirationMinutes));
      tokenRepository.save(token);
      log.info("Password reset token generated for {}: {}", email, tokenValue);
      // TODO: integrate with email provider to deliver token/link
    }, () -> log.info("Password reset requested for non-existent email: {}", email));
  }

  @Override
  public void resetPassword(String token, String newPassword) {
    PasswordResetToken resetToken = tokenRepository.findByToken(token)
        .orElseThrow(() -> new ResponseStatusException(HttpStatus.BAD_REQUEST, "Invalid reset token"));
    if (resetToken.isUsed()) {
      throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Reset token already used");
    }
    if (resetToken.getExpiresAt().isBefore(OffsetDateTime.now())) {
      throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Reset token expired");
    }
    User user = resetToken.getUser();
    user.setPassword(passwordEncoder.encode(newPassword));
    userRepository.save(user);
    resetToken.setUsed(true);
    tokenRepository.save(resetToken);
  }

  private String generateToken() {
    byte[] buffer = new byte[32];
    RANDOM.nextBytes(buffer);
    return Base64.getUrlEncoder().withoutPadding().encodeToString(buffer);
  }
}
