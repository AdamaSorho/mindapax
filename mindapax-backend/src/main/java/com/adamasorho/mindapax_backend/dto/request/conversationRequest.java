package com.adamasorho.mindapax_backend.dto.request;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class conversationRequest {
  private Long professionalId;
  private Long userId;
}
