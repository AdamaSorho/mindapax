package com.adamasorho.mindapax_backend.dto.request;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class ForgotPasswordRequest {
  @NotBlank(message = "Email is required")
  @Email(message = "Email is not valid")
  private String email;
}
