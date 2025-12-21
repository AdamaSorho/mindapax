package com.adamasorho.mindapax_backend.controller;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

import com.adamasorho.mindapax_backend.dto.twofactor.TwoFactorCodeRequest;
import com.adamasorho.mindapax_backend.dto.twofactor.TwoFactorSetupResponse;
import com.adamasorho.mindapax_backend.dto.twofactor.TwoFactorStatusResponse;
import com.adamasorho.mindapax_backend.model.User;
import com.adamasorho.mindapax_backend.security.CustomUserDetails;
import com.adamasorho.mindapax_backend.service.TwoFactorService;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;

@RestController
@RequestMapping("/api/v1/auth/2fa")
@RequiredArgsConstructor
public class TwoFactorController {

  private final TwoFactorService twoFactorService;

  @GetMapping("/status")
  public TwoFactorStatusResponse status(@AuthenticationPrincipal CustomUserDetails principal) {
    final User user = principal.getUser();
    return TwoFactorStatusResponse.builder()
        .enabled(user.isTwoFactorEnabled())
        .secretPresent(user.getTwoFactorSecret() != null && !user.getTwoFactorSecret().isBlank())
        .build();
  }

  @PostMapping("/setup")
  public TwoFactorSetupResponse setup(@AuthenticationPrincipal CustomUserDetails principal) {
    final User user = principal.getUser();
    if (user.isTwoFactorEnabled()) {
      throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Two-factor authentication already enabled");
    }
    return twoFactorService.initiateSetup(user);
  }

  @PostMapping("/enable")
  public ResponseEntity<Void> enable(@AuthenticationPrincipal CustomUserDetails principal,
      @Valid @RequestBody TwoFactorCodeRequest request) {
    final User user = principal.getUser();
    if (user.getTwoFactorSecret() == null) {
      throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Two-factor setup required before enabling");
    }
    if (!twoFactorService.verifyCode(user, request.getCode())) {
      throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Invalid two-factor code");
    }
    twoFactorService.enableTwoFactor(user);
    return ResponseEntity.noContent().build();
  }

  @PostMapping("/disable")
  public ResponseEntity<Void> disable(@AuthenticationPrincipal CustomUserDetails principal,
      @Valid @RequestBody TwoFactorCodeRequest request) {
    final User user = principal.getUser();
    if (!user.isTwoFactorEnabled()) {
      throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Two-factor authentication is not enabled");
    }
    if (!twoFactorService.verifyCode(user, request.getCode())) {
      throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Invalid two-factor code");
    }
    twoFactorService.disableTwoFactor(user);
    return ResponseEntity.noContent().build();
  }
}
