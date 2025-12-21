package com.adamasorho.mindapax_backend.dto.twofactor;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import lombok.Data;

@Data
public class TwoFactorCodeRequest {
  @NotBlank(message = "Two-factor code is required")
  @Pattern(regexp = "^\\d{6}$", message = "Two-factor code must be 6 digits")
  private String code;
}
