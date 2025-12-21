package com.adamasorho.mindapax_backend.dto.twofactor;

import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class TwoFactorStatusResponse {
  private boolean enabled;
  private boolean secretPresent;
}
