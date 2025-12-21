package com.adamasorho.mindapax_backend.service;

import com.adamasorho.mindapax_backend.dto.twofactor.TwoFactorSetupResponse;
import com.adamasorho.mindapax_backend.model.User;

public interface TwoFactorService {
  TwoFactorSetupResponse initiateSetup(User user);

  boolean verifyCode(User user, String code);

  void enableTwoFactor(User user);

  void disableTwoFactor(User user);
}
