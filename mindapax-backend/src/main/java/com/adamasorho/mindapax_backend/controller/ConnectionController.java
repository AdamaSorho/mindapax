package com.adamasorho.mindapax_backend.controller;

import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.adamasorho.mindapax_backend.dto.request.ConnectionRequest;
import com.adamasorho.mindapax_backend.dto.request.TransferConnectionRequest;
import com.adamasorho.mindapax_backend.dto.response.ConnectionResponse;
import com.adamasorho.mindapax_backend.mapper.ConnectionMapper;
import com.adamasorho.mindapax_backend.model.enums.ConnectionStatus;
import com.adamasorho.mindapax_backend.service.ConnectionService;

import jakarta.validation.Valid;
import lombok.AllArgsConstructor;

@RestController
@RequestMapping("/api/v1/connections")
@AllArgsConstructor
public class ConnectionController {
  private final ConnectionService connectionService;
  private final ConnectionMapper connectionMapper;

  @PostMapping("/{userId}")
  public ResponseEntity<ConnectionResponse> requestConnection(
    @PathVariable Long userId, @RequestBody @Valid ConnectionRequest connectionRequest) {

    return ResponseEntity.status(HttpStatus.CREATED)
      .body(connectionMapper.toDTO(
        connectionService.requestConnection(userId, connectionRequest.getProfessionalId())));
  }

  @PutMapping("/{id}/status")
  public ResponseEntity<ConnectionResponse> updateStatus(@PathVariable Long id, @RequestParam ConnectionStatus status) {

    return ResponseEntity.ok(connectionMapper.toDTO(connectionService.updateStutus(id, status)));
  }

  @GetMapping("/{id}")
  public ResponseEntity<ConnectionResponse> getConnection(@PathVariable Long id) {
    return ResponseEntity.ok(connectionMapper.toDTO(connectionService.getConnectionById(id)));
  }

  @GetMapping("/user/{userId}")
  public ResponseEntity<List<ConnectionResponse>> getUserConnections(@PathVariable Long userId) {
    return ResponseEntity.ok(
      connectionService.getUserConnections(userId).stream()
        .map(connectionMapper::toDTO)
        .toList()
    );
  }

  @GetMapping("/professional/{professionalId}")
  public ResponseEntity<List<ConnectionResponse>> getProfessionalConnections(@PathVariable Long professionalId) {
    return ResponseEntity.ok(
      connectionService.getProfessionalConnections(professionalId).stream()
        .map(connectionMapper::toDTO)
        .toList()
    );
  }

  @PutMapping("/{id}/transfer")
  public ResponseEntity<ConnectionResponse> transfer(
      @PathVariable Long id,
      @RequestBody @Valid TransferConnectionRequest request) {
    return ResponseEntity.ok(
        connectionMapper.toDTO(
            connectionService.transferConnection(id, request.getProfessionalId(), request.getReason())));
  }
}
