package com.adamasorho.mindapax_backend.service;

import com.adamasorho.mindapax_backend.dto.notification.NotificationPayload;

public interface NotificationPublisher {
  void publishToUser(Long userId, NotificationPayload payload);
}
