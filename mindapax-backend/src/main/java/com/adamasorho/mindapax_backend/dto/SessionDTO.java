package com.adamasorho.mindapax_backend.dto;

import java.time.LocalDateTime;

import com.adamasorho.mindapax_backend.model.enums.SessionMode;
import com.adamasorho.mindapax_backend.model.enums.SessionStatus;

import jakarta.validation.constraints.Min; // Added Min import
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull; // Added NotNull import
import lombok.Data;

@Data
public class SessionDTO {
  private Long id;
  private Long userId; // For scheduleByProfessional, this is the client's ID
  private Long professionalId; // This might be populated in responses
  private LocalDateTime startTime;

  @NotNull(message = "Duration cannot be null")
  @Min(value = 15, message = "Duration must be at least 15 minutes")
  private Integer durationMinutes;

  @NotNull(message = "Mode cannot be null")
  private SessionMode mode;
  private SessionStatus status;
  private String notes;

  private String professionalName;
  private String professionalSpecialization;
}
