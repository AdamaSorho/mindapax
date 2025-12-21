package com.adamasorho.mindapax_backend.service.impl;

import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.security.InvalidKeyException;
import java.security.SecureRandom;
import java.time.Duration;
import java.time.Instant;

import org.apache.commons.codec.binary.Base32;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.adamasorho.mindapax_backend.dto.twofactor.TwoFactorSetupResponse;
import com.adamasorho.mindapax_backend.model.User;
import com.adamasorho.mindapax_backend.repository.UserRepository;
import com.adamasorho.mindapax_backend.service.TwoFactorService;

import com.eatthepath.otp.TimeBasedOneTimePasswordGenerator;

import jakarta.persistence.EntityNotFoundException;
import jakarta.validation.constraints.NotNull;
@Service
@Transactional
public class TwoFactorServiceImpl implements TwoFactorService {

  private static final String OTP_ALGORITHM = "HmacSHA1";
  private static final int SECRET_SIZE = 20; // bytes
  private static final Duration OTP_PERIOD = Duration.ofSeconds(30);
  private static final int OTP_WINDOW = 1; // one step before/after
  private static final String ISSUER = "Mindapax";

  private final UserRepository userRepository;
  private final SecureRandom secureRandom = new SecureRandom();
  private final TimeBasedOneTimePasswordGenerator totpGenerator;
  private final Base32 base32 = new Base32();

  public TwoFactorServiceImpl(UserRepository userRepository) {
    this.userRepository = userRepository;
    this.totpGenerator = new TimeBasedOneTimePasswordGenerator(OTP_PERIOD, 6, OTP_ALGORITHM);
  }

  @Override
  public TwoFactorSetupResponse initiateSetup(@NotNull User user) {
    if (user.getId() == null) {
      throw new EntityNotFoundException("User must be persisted before enabling 2FA");
    }

    if (user.getTwoFactorSecret() == null || user.getTwoFactorSecret().isBlank()) {
      user.setTwoFactorSecret(generateSecret());
      userRepository.save(user);
    }

    final String accountName = user.getEmail();
    final String otpauthUrl = buildOtpAuthUrl(accountName, user.getTwoFactorSecret());

    return TwoFactorSetupResponse.builder()
        .secret(user.getTwoFactorSecret())
        .otpauthUrl(otpauthUrl)
        .issuer(ISSUER)
        .accountName(accountName)
        .build();
  }

  @Override
  public boolean verifyCode(User user, String code) {
    if (user == null || user.getTwoFactorSecret() == null || user.getTwoFactorSecret().isBlank()) {
      return false;
    }
    final String sanitized = code == null ? "" : code.trim();
    if (sanitized.length() != 6 || !sanitized.chars().allMatch(Character::isDigit)) {
      return false;
    }

    final byte[] keyBytes = base32.decode(user.getTwoFactorSecret());
    final var key = new javax.crypto.spec.SecretKeySpec(keyBytes, OTP_ALGORITHM);
    final Instant now = Instant.now();

    try {
      final int provided = Integer.parseInt(sanitized);
      for (int i = -OTP_WINDOW; i <= OTP_WINDOW; i++) {
        final Instant timestamp = now.plus(OTP_PERIOD.multipliedBy(i));
        final int expected = totpGenerator.generateOneTimePassword(key, timestamp);
        if (expected == provided) {
          return true;
        }
      }
    } catch (NumberFormatException | InvalidKeyException ex) {
      return false;
    }
    return false;
  }

  @Override
  public void enableTwoFactor(User user) {
    user.setTwoFactorEnabled(true);
    userRepository.save(user);
  }

  @Override
  public void disableTwoFactor(User user) {
    user.setTwoFactorEnabled(false);
    user.setTwoFactorSecret(null);
    userRepository.save(user);
  }

  private String generateSecret() {
    final byte[] bytes = new byte[SECRET_SIZE];
    secureRandom.nextBytes(bytes);
    return base32.encodeAsString(bytes).replace("=", "").replace(" ", "");
  }

  private String buildOtpAuthUrl(String accountName, String secret) {
    final String label = URLEncoder.encode(ISSUER + ":" + accountName, StandardCharsets.UTF_8);
    final String issuerParam = URLEncoder.encode(ISSUER, StandardCharsets.UTF_8);
    final String secretParam = URLEncoder.encode(secret, StandardCharsets.UTF_8);
    return String.format("otpauth://totp/%s?secret=%s&issuer=%s&period=%d", label, secretParam, issuerParam,
        OTP_PERIOD.toSeconds());
  }
}
