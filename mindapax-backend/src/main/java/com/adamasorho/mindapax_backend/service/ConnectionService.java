package com.adamasorho.mindapax_backend.service;

import java.util.List;

import com.adamasorho.mindapax_backend.model.Connection;
import com.adamasorho.mindapax_backend.model.enums.ConnectionStatus;

public interface ConnectionService {
  Connection requestConnection(Long userId, Long professionalId);
  void deleteConnection(Long userId, Long professionalId);
  Connection getConnection(Long userId, Long professionalId);
  Connection getConnectionById(Long id);
  List<Connection> getUserConnections(Long userId);
  List<Connection> getProfessionalConnections(Long professionalId);
  Connection updateStutus(Long connectionId, ConnectionStatus status);
  Connection transferConnection(Long connectionId, Long targetProfessionalId, String reason);
}
