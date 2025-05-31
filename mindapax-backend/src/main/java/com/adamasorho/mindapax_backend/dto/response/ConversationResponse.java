package com.adamasorho.mindapax_backend.dto.response;

import java.time.LocalDateTime;

import com.adamasorho.mindapax_backend.dto.MessageDTO;
import com.adamasorho.mindapax_backend.dto.ProfessionalDTO;
import com.adamasorho.mindapax_backend.dto.UserDTO;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class ConversationResponse {
  private Long id;
  private UserDTO user;
  private ProfessionalDTO professional;
  private LocalDateTime createdAt;
  private MessageDTO lastMessage;
}
