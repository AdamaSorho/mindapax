package com.adamasorho.mindapax_backend.service.impl;

import java.time.OffsetDateTime;
import java.time.temporal.ChronoUnit;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.adamasorho.mindapax_backend.dto.notification.NotificationPayload;
import com.adamasorho.mindapax_backend.model.Connection;
import com.adamasorho.mindapax_backend.model.ConnectionTransferLog;
import com.adamasorho.mindapax_backend.model.Professional;
import com.adamasorho.mindapax_backend.model.User;
import com.adamasorho.mindapax_backend.model.enums.ConnectionStatus;
import com.adamasorho.mindapax_backend.model.enums.UserRole;
import com.adamasorho.mindapax_backend.repository.ConnectionRepository;
import com.adamasorho.mindapax_backend.repository.ConnectionTransferLogRepository;
import com.adamasorho.mindapax_backend.service.ConnectionService;
import com.adamasorho.mindapax_backend.service.ConversationService;
import com.adamasorho.mindapax_backend.service.NotificationPublisher;
import com.adamasorho.mindapax_backend.service.ProfessionalService;
import com.adamasorho.mindapax_backend.service.UserService;

import jakarta.persistence.EntityNotFoundException;

@Service
public class ConnectionServiceImpl implements ConnectionService {
  private final ConnectionRepository connectionRepository;
  private final UserService userService;
  private final ProfessionalService professionalService;
  private final ConversationService conversationService;
  private final NotificationPublisher notificationPublisher;
  private final ConnectionTransferLogRepository transferLogRepository;

  private static final int TRANSFER_ALERT_THRESHOLD = 3;
  private static final int TRANSFER_ALERT_WINDOW_DAYS = 7;

  @Autowired
  public ConnectionServiceImpl(ConnectionRepository connectionRepository, UserService userService, 
      ProfessionalService professionalService, ConversationService conversationService,
      NotificationPublisher notificationPublisher,
      ConnectionTransferLogRepository transferLogRepository) {
    this.connectionRepository = connectionRepository;
    this.userService = userService;
    this.professionalService = professionalService;
    this.conversationService = conversationService;
    this.notificationPublisher = notificationPublisher;
    this.transferLogRepository = transferLogRepository;
  }

  @Override
  public Connection getConnectionById(Long id) {
    return connectionRepository.findById(id)
      .orElseThrow(() -> new EntityNotFoundException("Connection not found"));
  }
  
  @Override
  public Connection requestConnection(Long userId, Long professionalId) {
    if (connectionRepository.findByUserIdAndProfessionalId(userId, professionalId).isPresent()) {
      throw new RuntimeException("Connection already exists");
    }

    User user = userService.getUserById(userId);
    Professional professional = professionalService.getProfessionalById(professionalId);

    Connection connection = new Connection();
    connection.setUser(user);
    connection.setProfessional(professional);
    connection.setStatus(ConnectionStatus.PENDING);
    
    return connectionRepository.save(connection);
  }

  @Override
  @Transactional
  public Connection updateStutus(Long connectionId, ConnectionStatus status) {
    Connection connection = this.getConnectionById(connectionId);
    connection.setStatus(status);

    connectionRepository.save(connection);

    if (status == ConnectionStatus.ACCEPTED) {
      conversationService.startOrGetConversation(connection.getUser().getId(), connection.getProfessional().getId());
      final User professionalUser = connection.getProfessional().getUser();
      final String professionalName = professionalUser != null
          ? (professionalUser.getFirstName() + " " + professionalUser.getLastName()).trim()
          : "Your professional";
      notificationPublisher.publishToUser(
          connection.getUser().getId(),
          NotificationPayload.builder()
              .type("connection.accepted")
              .title("Connection accepted")
              .message(String.format("%s accepted your connection request.", professionalName))
              .data(Map.of(
                  "connectionId", connection.getId(),
                  "professionalId", connection.getProfessional().getId(),
                  "professionalName", professionalName))
              .build());
    }

    return connection;
  }

  @Override
  public void deleteConnection(Long userId, Long professionalId) {
    connectionRepository.deleteByUserIdAndProfessionalId(userId, professionalId);
  }

  @Override
  public Connection getConnection(Long userId, Long professionalId) {
    return connectionRepository.findByUserIdAndProfessionalId(userId, professionalId)
      .orElseThrow(() -> new EntityNotFoundException("Connection not found"));
  }

  @Override
  public List<Connection> getUserConnections(Long userId) {
    return connectionRepository.findByUserId(userId);
  }

  @Override
  public List<Connection> getProfessionalConnections(Long professionalId) {
   return connectionRepository.findByProfessionalId(professionalId);
  }
  
  @Override
  @Transactional
  public Connection transferConnection(Long connectionId, Long targetProfessionalId, String reason, Boolean escalateToAdmin) {
    Connection connection = this.getConnectionById(connectionId);
    Professional sourceProfessional = connection.getProfessional();
    Professional target = professionalService.getProfessionalById(targetProfessionalId);

    connection.setProfessional(target);
    connection.setStatus(ConnectionStatus.TRANSFERRED);
    if (reason != null && !reason.trim().isEmpty()) {
      connection.setTransferReason(reason.trim());
    }
    conversationService.startOrGetConversation(connection.getUser().getId(), target.getId());
    Connection saved = connectionRepository.save(connection);

    ConnectionTransferLog log = new ConnectionTransferLog();
    log.setConnection(saved);
    log.setFromProfessional(sourceProfessional);
    log.setToProfessional(target);
    log.setUser(saved.getUser());
    log.setReason(reason != null && !reason.trim().isEmpty() ? reason.trim() : null);
    log.setEscalated(Boolean.TRUE.equals(escalateToAdmin));
    log = transferLogRepository.save(log);

    notifyClientOfTransfer(saved, target, reason);

    boolean highTransferRate = exceedsTransferThreshold(sourceProfessional);
    boolean shouldEscalate = log.isEscalated() || highTransferRate;
    if (shouldEscalate) {
      if (!log.isEscalated()) {
        log.setEscalated(true);
        transferLogRepository.save(log);
      }
      notifyAdminsOfTransfer(saved, sourceProfessional, target, reason, highTransferRate);
    }

    return saved;
  }

  private void notifyClientOfTransfer(Connection connection, Professional target, String reason) {
    final User client = connection.getUser();
    final User targetUser = target.getUser();
    final String proName = targetUser != null
        ? (targetUser.getFirstName() + " " + targetUser.getLastName()).trim()
        : "your new professional";
    final String message = reason != null && !reason.trim().isEmpty()
        ? String.format("Your connection has been transferred to %s. Reason: %s", proName, reason.trim())
        : String.format("Your connection has been transferred to %s.", proName);
    notificationPublisher.publishToUser(
        client.getId(),
        NotificationPayload.builder()
            .type("connection.transferred")
            .title("Connection transferred")
            .message(message)
            .data(Map.of(
                "connectionId", connection.getId(),
                "professionalId", target.getId(),
                "professionalName", proName))
            .build());
  }

  private boolean exceedsTransferThreshold(Professional sourceProfessional) {
    if (sourceProfessional == null) return false;
    OffsetDateTime windowStart = OffsetDateTime.now()
        .minus(TRANSFER_ALERT_WINDOW_DAYS, ChronoUnit.DAYS);
    long count = transferLogRepository.countByFromProfessionalAndCreatedAtAfter(sourceProfessional, windowStart);
    return count >= TRANSFER_ALERT_THRESHOLD;
  }

  private void notifyAdminsOfTransfer(
      Connection connection,
      Professional sourceProfessional,
      Professional targetProfessional,
      String reason,
      boolean autoEscalated) {
    List<User> admins = userService.getUsersByRole(UserRole.ADMIN);
    if (admins.isEmpty()) return;

    final String sourceName = sourceProfessional != null && sourceProfessional.getUser() != null
        ? (sourceProfessional.getUser().getFirstName() + " " + sourceProfessional.getUser().getLastName()).trim()
        : "Unknown professional";
    final String targetName = targetProfessional != null && targetProfessional.getUser() != null
        ? (targetProfessional.getUser().getFirstName() + " " + targetProfessional.getUser().getLastName()).trim()
        : "Unknown professional";
    final String clientName = connection.getUser() != null
        ? (connection.getUser().getFirstName() + " " + connection.getUser().getLastName()).trim()
        : "Client";
    final StringBuilder msg = new StringBuilder();
    msg.append(String.format("Connection for %s transferred from %s to %s.",
        clientName, sourceName, targetName));
    if (reason != null && !reason.trim().isEmpty()) {
      msg.append(" Reason: ").append(reason.trim()).append('.');
    }
    if (autoEscalated) {
      msg.append(" (Automatic alert: high transfer activity)");
    }

    Map<String, Object> data = new HashMap<>();
    data.put("connectionId", connection.getId());
    if (connection.getUser() != null) {
      data.put("clientId", connection.getUser().getId());
    }
    if (sourceProfessional != null) {
      data.put("fromProfessionalId", sourceProfessional.getId());
    }
    if (targetProfessional != null) {
      data.put("toProfessionalId", targetProfessional.getId());
    }

    NotificationPayload payload = NotificationPayload.builder()
        .type("connection.transfer.alert")
        .title("Connection transfer alert")
        .message(msg.toString())
        .data(data)
        .build();

    admins.forEach(admin -> notificationPublisher.publishToUser(admin.getId(), payload));
  }
}
