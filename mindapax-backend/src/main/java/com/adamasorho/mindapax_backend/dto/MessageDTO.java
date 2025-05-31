package com.adamasorho.mindapax_backend.dto;

import java.time.LocalDateTime;

import jakarta.validation.constraints.NotBlank;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class MessageDTO {
  private Long id;
  private Long sessionId;
  private Long conversationId;
  @NotBlank(message = "Sender is required")
  private Long senderId;
  @NotBlank(message = "Content is required")
  private String content;
  private LocalDateTime timestamp;
  @NotBlank(message = "isRead is required")
  private boolean isRead;
}
