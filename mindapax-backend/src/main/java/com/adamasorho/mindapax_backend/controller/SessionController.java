package com.adamasorho.mindapax_backend.controller;

import java.time.LocalDateTime;
import java.util.List;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.web.PageableDefault;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.adamasorho.mindapax_backend.dto.SessionDTO;
import com.adamasorho.mindapax_backend.dto.SessionTimeFilter;
import com.adamasorho.mindapax_backend.mapper.SessionMapper;
import com.adamasorho.mindapax_backend.model.Session;
import com.adamasorho.mindapax_backend.model.enums.SessionStatus;
import com.adamasorho.mindapax_backend.service.SessionService;

import lombok.AllArgsConstructor;

@RestController
@RequestMapping("/api/v1/sessions")
@AllArgsConstructor
public class SessionController {
  private final SessionService serviceService;
  private final SessionMapper sessionMapper;

  @PostMapping
  public ResponseEntity<SessionDTO> create(@RequestBody SessionDTO dto) {
    return ResponseEntity.ok(serviceService.createSession(dto));
  }

  @GetMapping("/{id}")
  public ResponseEntity<SessionDTO> get(@PathVariable Long id) {
    return ResponseEntity.ok(serviceService.getSessionById(id));
  }

  @GetMapping
  public ResponseEntity<List<SessionDTO>> getAll() {
    return ResponseEntity.ok(serviceService.getAllSessions());
  }

  @GetMapping("/user/{userId}")
  public ResponseEntity<List<SessionDTO>> getByUser(@PathVariable Long userId) {
    return ResponseEntity.ok(serviceService.getSessionsByUserId(userId));
  }

  @PutMapping("/{id}/status")
  public ResponseEntity<SessionDTO> updateStatus(@PathVariable Long id, @RequestBody SessionDTO dto) {
    return ResponseEntity.ok(serviceService.updateSessionStatus(id, dto));
  }

  @DeleteMapping("/{id}")
  public ResponseEntity<Void> delete(@PathVariable Long id) {
    serviceService.deleteSession(id);
    return ResponseEntity.noContent().build();
  }

  @GetMapping("/api/sessions/by-user")
public ResponseEntity<Page<SessionDTO>> getSessionsByUser(
      @RequestParam Long userId,
      @RequestParam(required = false)
      @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime date,
      @RequestParam SessionTimeFilter filter,
      @RequestParam(required = false) SessionStatus status,
      @PageableDefault(size = 10) Pageable pageable) {

  LocalDateTime effectiveDate = (date != null) ? date : LocalDateTime.now();

  Page<Session> sessions = serviceService.getSessionsByUserAndTime(userId, effectiveDate, filter, status, pageable);
  Page<SessionDTO> dtos = sessions.map(sessionMapper::toDTO);

  return ResponseEntity.ok(dtos);
}

  @PostMapping("/professional/schedule")
  @PreAuthorize("hasRole('PROFESSIONAL')")
  public ResponseEntity<SessionDTO> scheduleByProfessional(@RequestBody SessionDTO sessionDto) {
      SessionDTO createdSession = serviceService.scheduleSessionByProfessional(sessionDto);
      return ResponseEntity.status(HttpStatus.CREATED).body(createdSession);
  }
}
