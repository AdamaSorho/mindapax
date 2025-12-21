package com.adamasorho.mindapax_backend.service.impl;

import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;

import com.adamasorho.mindapax_backend.dto.notification.NotificationPayload;
import com.adamasorho.mindapax_backend.service.NotificationPublisher;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class NotificationPublisherImpl implements NotificationPublisher {

  private final SimpMessagingTemplate messagingTemplate;

  @Override
  public void publishToUser(Long userId, NotificationPayload payload) {
    if (userId == null || payload == null) return;
    messagingTemplate.convertAndSend("/topic/users/" + userId, payload);
  }
}
