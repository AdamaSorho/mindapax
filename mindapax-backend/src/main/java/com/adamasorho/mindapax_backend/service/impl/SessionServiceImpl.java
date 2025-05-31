package com.adamasorho.mindapax_backend.service.impl;

import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;

import com.adamasorho.mindapax_backend.dto.SessionDTO;
import com.adamasorho.mindapax_backend.dto.SessionTimeFilter;
import com.adamasorho.mindapax_backend.mapper.SessionMapper;
import com.adamasorho.mindapax_backend.model.Session;
import com.adamasorho.mindapax_backend.model.enums.SessionStatus;
import com.adamasorho.mindapax_backend.repository.SessionRepository;
import com.adamasorho.mindapax_backend.service.SessionService;

import jakarta.persistence.EntityNotFoundException;
import lombok.AllArgsConstructor;

@Service
@AllArgsConstructor
public class SessionServiceImpl implements SessionService {
  private final SessionRepository sessionRepository;
  private final SessionMapper mapper;

  @Override
  public SessionDTO createSession(SessionDTO dto) {
      Session session = mapper.toEntity(dto);
      return mapper.toDTO(sessionRepository.save(session));
  }

  @Override
  public SessionDTO getSessionById(Long id) {
    return mapper.toDTO(sessionRepository.findById(id)
            .orElseThrow(() -> new EntityNotFoundException("Session not found")));
  }

  @Override
  public List<SessionDTO> getAllSessions() {
    return sessionRepository.findAll().stream().map(mapper::toDTO).collect(Collectors.toList());
  }

  @Override
  public List<SessionDTO> getSessionsByUserId(Long userId) {
    return sessionRepository.findAll().stream()
            .filter(s -> s.getUser().getId().equals(userId))
            .map(mapper::toDTO)
            .collect(Collectors.toList());
  }

  @Override
  public SessionDTO updateSessionStatus(Long id, SessionDTO dto) {
    Session session = sessionRepository.findById(id)
            .orElseThrow(() -> new EntityNotFoundException("Session not found"));

    session.setStatus(dto.getStatus());
    return mapper.toDTO(sessionRepository.save(session));
  }

  @Override
  public void deleteSession(Long id) {
    if (!sessionRepository.existsById(id)) {
        throw new EntityNotFoundException("Session not found");
    }
    sessionRepository.deleteById(id);
  }

  @Override
  public Page<Session> getSessionsByUserAndTime(
        Long userId,
        LocalDateTime date,
        SessionTimeFilter filter,
        SessionStatus status,
        Pageable pageable) {

    if (filter == SessionTimeFilter.PAST) {
        return (status != null)
                ? sessionRepository.findByUserIdAndStartTimeBeforeAndStatus(userId, date, status, pageable)
                : sessionRepository.findByUserIdAndStartTimeBefore(userId, date, pageable);
    } else {
        return (status != null)
                ? sessionRepository.findByUserIdAndStartTimeGreaterThanEqualAndStatus(userId, date, status, pageable)
                : sessionRepository.findByUserIdAndStartTimeGreaterThanEqual(userId, date, pageable);
    }
}

}
