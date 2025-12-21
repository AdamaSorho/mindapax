package com.adamasorho.mindapax_backend.dto.twofactor;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;

@Data
@Builder
@AllArgsConstructor
public class TwoFactorSetupResponse {
  private String secret;
  private String otpauthUrl;
  private String issuer;
  private String accountName;
}
