package com.adamasorho.mindapax_backend.service;

import java.time.LocalDateTime;
import java.util.List;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

import com.adamasorho.mindapax_backend.dto.SessionDTO;
import com.adamasorho.mindapax_backend.dto.SessionTimeFilter;
import com.adamasorho.mindapax_backend.model.Session;
import com.adamasorho.mindapax_backend.model.enums.SessionStatus;

public interface SessionService {
  SessionDTO createSession(SessionDTO dto);
    SessionDTO getSessionById(Long id);
    List<SessionDTO> getAllSessions();
    List<SessionDTO> getSessionsByUserId(Long userId);
    SessionDTO updateSessionStatus(Long id, SessionDTO dto);
    void deleteSession(Long id);
    Page<Session> getSessionsByUserAndTime(Long userId,
    LocalDateTime date,
    SessionTimeFilter filter,
    SessionStatus status,
    Pageable pageable);
}
