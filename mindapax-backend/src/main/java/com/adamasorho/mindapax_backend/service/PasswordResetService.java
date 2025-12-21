package com.adamasorho.mindapax_backend.service;

public interface PasswordResetService {
  void initiateReset(String email);
  void resetPassword(String token, String newPassword);
}
