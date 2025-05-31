package com.adamasorho.mindapax_backend.dto;

import java.time.LocalDateTime;

import com.adamasorho.mindapax_backend.model.enums.SessionMode;
import com.adamasorho.mindapax_backend.model.enums.SessionStatus;

import lombok.Data;

@Data
public class SessionDTO {
  private Long id;
  private Long userId;
  private Long professionalId;
  private LocalDateTime startTime;
  private LocalDateTime endTime;
  private SessionMode mode;
  private SessionStatus status;
  private String notes;
}
