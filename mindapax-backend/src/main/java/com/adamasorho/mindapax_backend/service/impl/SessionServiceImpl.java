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
import com.adamasorho.mindapax_backend.model.Professional;
import com.adamasorho.mindapax_backend.model.Session;
import com.adamasorho.mindapax_backend.model.User;
import com.adamasorho.mindapax_backend.model.enums.SessionStatus;
import com.adamasorho.mindapax_backend.repository.ProfessionalRepository;
import com.adamasorho.mindapax_backend.repository.SessionRepository;
import com.adamasorho.mindapax_backend.repository.UserRepository;
import com.adamasorho.mindapax_backend.service.SessionService;

import jakarta.persistence.EntityNotFoundException;
// import lombok.AllArgsConstructor; // Lombok not used if specific constructor is present

import org.slf4j.Logger; // Added Logger
import org.slf4j.LoggerFactory; // Added LoggerFactory
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.transaction.annotation.Transactional;

@Service
public class SessionServiceImpl implements SessionService {
  private static final Logger logger = LoggerFactory.getLogger(SessionServiceImpl.class); // Added logger instance

  private final SessionRepository sessionRepository;
  private final SessionMapper mapper;
  private final UserRepository userRepository;
  private final ProfessionalRepository professionalRepository;

  public SessionServiceImpl(SessionRepository sessionRepository, SessionMapper mapper, UserRepository userRepository, ProfessionalRepository professionalRepository) {
    this.sessionRepository = sessionRepository;
    this.mapper = mapper;
    this.userRepository = userRepository;
    this.professionalRepository = professionalRepository;
  }

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
      Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
      // is professional
      if (authentication.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_PROFESSIONAL"))) {
          return getSessionsFromProfessional(userId, date, filter, status, pageable);
      } else {
          return getSessionsFromClient(userId, date, filter, status, pageable);
      }
}

private Page<Session> getSessionsFromProfessional(Long professionalId, LocalDateTime date, 
  SessionTimeFilter filter, SessionStatus status, Pageable pageable) {
    if (filter == SessionTimeFilter.PAST) {
      return (status != null)
              ? sessionRepository.findByProfessionalIdAndStartTimeBeforeAndStatus(professionalId, date, status, pageable)
              : sessionRepository.findByProfessionalIdAndStartTimeBefore(professionalId, date, pageable);
  } else {
      return (status != null)
              ? sessionRepository.findByProfessionalIdAndStartTimeGreaterThanEqualAndStatus(professionalId, date, status, pageable)
              : sessionRepository.findByProfessionalIdAndStartTimeGreaterThanEqual(professionalId, date, pageable);
  }
}

private Page<Session> getSessionsFromClient(Long clientId, LocalDateTime date, 
  SessionTimeFilter filter, SessionStatus status, Pageable pageable) {
  if (filter == SessionTimeFilter.PAST) {
    return (status != null)
            ? sessionRepository.findByUserIdAndStartTimeBeforeAndStatus(clientId, date, status, pageable)
              : sessionRepository.findByUserIdAndStartTimeBefore(clientId, date, pageable);
  } else {
      return (status != null)
              ? sessionRepository.findByUserIdAndStartTimeGreaterThanEqualAndStatus(clientId, date, status, pageable)
              : sessionRepository.findByUserIdAndStartTimeGreaterThanEqual(clientId, date, pageable);
  }
}

  @Override
  @Transactional
  public SessionDTO scheduleSessionByProfessional(SessionDTO sessionDto) {
    Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
    String professionalEmail = authentication.getName(); // This is usually the email

    Professional professional = professionalRepository.findByUserEmail(professionalEmail)
        .orElseThrow(() -> {
            logger.error("Professional not found for email: {}", professionalEmail);
            return new EntityNotFoundException("Professional not found for email: " + professionalEmail);
        });


    User clientUser = userRepository.findById(sessionDto.getUserId())
        .orElseThrow(() -> {
            logger.error("User (client) not found with ID: {}", sessionDto.getUserId());
            return new EntityNotFoundException("User (client) not found with ID: " + sessionDto.getUserId());
        });

    // Create a new Session entity
    Session session = new Session();

    // Manually map fields from DTO
    session.setStartTime(sessionDto.getStartTime());
    session.setDurationMinutes(sessionDto.getDurationMinutes()); 
    session.setMode(sessionDto.getMode());
    session.setNotes(sessionDto.getNotes());
    // If DTO can carry a status, map it, otherwise default is fine
    if (sessionDto.getStatus() != null) {
        session.setStatus(sessionDto.getStatus());
    } else {
        session.setStatus(SessionStatus.SCHEDULED);
    }

    // Set the professional and user fields
    session.setProfessional(professional); // Use the re-fetched, managed instance
    session.setUser(clientUser);         // Use the re-fetched, managed instance

    // If status wasn't in DTO or needs override:
    session.setStatus(SessionStatus.SCHEDULED); // Explicitly set/override status

    // Save the Session entity
    Session savedSession = sessionRepository.save(session);


    // Return the saved Session mapped back to a SessionDTO
    return mapper.toDTO(savedSession);
  }
}
