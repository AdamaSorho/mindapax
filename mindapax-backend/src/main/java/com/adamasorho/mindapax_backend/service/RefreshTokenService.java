package com.adamasorho.mindapax_backend.service;

import java.util.Optional;

import com.adamasorho.mindapax_backend.model.RefreshToken;
import com.adamasorho.mindapax_backend.model.User;

public interface RefreshTokenService {
  RefreshToken createRefreshToken(User user);
  Optional<RefreshToken> findByToken(String token);
  void deleteByUser(User user);
  RefreshToken verifyExpiration(RefreshToken token);
}
