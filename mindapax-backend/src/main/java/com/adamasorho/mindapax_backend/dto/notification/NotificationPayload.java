package com.adamasorho.mindapax_backend.dto.notification;

import java.util.Map;

import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class NotificationPayload {
  private String type;
  private String title;
  private String message;
  @Builder.Default
  private Map<String, Object> data = Map.of();
}
