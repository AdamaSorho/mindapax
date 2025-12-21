package com.adamasorho.mindapax_backend.repository;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.adamasorho.mindapax_backend.model.PasswordResetToken;
import com.adamasorho.mindapax_backend.model.User;

@Repository
public interface PasswordResetTokenRepository extends JpaRepository<PasswordResetToken, Long> {
  Optional<PasswordResetToken> findByToken(String token);
  void deleteByUser(User user);
}
