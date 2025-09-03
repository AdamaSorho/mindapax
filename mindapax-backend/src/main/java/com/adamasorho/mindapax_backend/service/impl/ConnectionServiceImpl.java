package com.adamasorho.mindapax_backend.service.impl;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.adamasorho.mindapax_backend.model.Connection;
import com.adamasorho.mindapax_backend.model.Professional;
import com.adamasorho.mindapax_backend.model.User;
import com.adamasorho.mindapax_backend.model.enums.ConnectionStatus;
import com.adamasorho.mindapax_backend.repository.ConnectionRepository;
import com.adamasorho.mindapax_backend.service.ConnectionService;
import com.adamasorho.mindapax_backend.service.ConversationService;
import com.adamasorho.mindapax_backend.service.ProfessionalService;
import com.adamasorho.mindapax_backend.service.UserService;

import jakarta.persistence.EntityNotFoundException;

@Service
public class ConnectionServiceImpl implements ConnectionService {
  private final ConnectionRepository connectionRepository;
  private final UserService userService;
  private final ProfessionalService professionalService;
  private final ConversationService conversationService;

  @Autowired
  public ConnectionServiceImpl(ConnectionRepository connectionRepository, UserService userService, 
      ProfessionalService professionalService, ConversationService conversationService) {
    this.connectionRepository = connectionRepository;
    this.userService = userService;
    this.professionalService = professionalService;
    this.conversationService = conversationService;
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
  public Connection transferConnection(Long connectionId, Long targetProfessionalId, String reason) {
    Connection connection = this.getConnectionById(connectionId);
    Professional target = professionalService.getProfessionalById(targetProfessionalId);
    connection.setProfessional(target);
    connection.setStatus(ConnectionStatus.TRANSFERRED);
    if (reason != null && !reason.trim().isEmpty()) {
      connection.setTransferReason(reason.trim());
    }
    // Optionally, start a conversation with the new professional
    conversationService.startOrGetConversation(connection.getUser().getId(), target.getId());
    return connectionRepository.save(connection);
  }
}
