package com.adamasorho.mindapax_backend.dto.response;

import java.time.LocalDateTime;

import com.adamasorho.mindapax_backend.dto.ProfessionalDTO;
import com.adamasorho.mindapax_backend.dto.UserDTO;
import com.adamasorho.mindapax_backend.model.enums.ConnectionStatus;
import com.adamasorho.mindapax_backend.model.enums.Specialization;
import com.adamasorho.mindapax_backend.model.enums.UrgencyStatus;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class ConnectionResponse {
  private Long id;
  private ProfessionalDTO professional;
  private Specialization requestType;
  private String message;
  private UrgencyStatus urgencyStatus;
  private UserDTO user;
  private ConnectionStatus status;
  private String transferReason;
  private LocalDateTime createdAt;
}
