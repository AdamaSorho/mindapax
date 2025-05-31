package com.adamasorho.mindapax_backend.dto.request;

import com.adamasorho.mindapax_backend.model.enums.Specialization;
import com.adamasorho.mindapax_backend.model.enums.UserRole;

import jakarta.validation.constraints.AssertTrue;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@AllArgsConstructor
@NoArgsConstructor
@Builder
public class AuthRequest {
  @NotBlank(message = "First name is required")
  private String firstName;
  @NotBlank(message = "Last name is required")
  private String lastName;
  @Email(message = "Email is not valid")
  @NotBlank(message = "Email is required")
  private String email;
  @NotBlank(message = "Password is required")
  @Size(min = 8, message = "Password must be at least 8 characters")
  private String password;
  @NotBlank(message = "Role is required")
  
  private UserRole role;

  @AssertTrue(message = "You must agree to the terms and conditions")
  private boolean agreeTerms;

  private ProfessionalDetailsDto professionalDetails;

  @Data
  @NoArgsConstructor
  @AllArgsConstructor
  @Builder
  public static class ProfessionalDetailsDto {
      private Specialization specialization;
      private Integer experienceYears;
      // Files will be handled separately in the controller
  }

}
