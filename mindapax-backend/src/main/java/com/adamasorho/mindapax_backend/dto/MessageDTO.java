package com.adamasorho.mindapax_backend.dto;

import java.time.LocalDateTime;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull; // Added import
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
  @NotNull(message = "Sender ID is required") // Changed from @NotBlank
  private Long senderId;
  @NotBlank(message = "Content is required")
  private String content;
  private LocalDateTime timestamp;
  private boolean isRead;
  // Optional client-supplied tag to correlate deliveries over WebSocket; not persisted
  private String clientTag;
}
