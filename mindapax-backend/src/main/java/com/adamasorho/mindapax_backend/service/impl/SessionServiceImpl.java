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

  @Override
  @Transactional
  public SessionDTO scheduleSessionByProfessional(SessionDTO sessionDto) {
    Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
    String professionalEmail = authentication.getName(); // This is usually the email

    Professional professionalFromAuth = professionalRepository.findByUserEmail(professionalEmail)
        .orElseThrow(() -> {
            logger.error("Professional not found for email: {}", professionalEmail);
            return new EntityNotFoundException("Professional not found for email: " + professionalEmail);
        });
    logger.info("Fetched initial professionalFromAuth with ID: {} and User Email: {}", professionalFromAuth.getId(), professionalFromAuth.getUser().getEmail());


    User clientUserFromDto = userRepository.findById(sessionDto.getUserId())
        .orElseThrow(() -> {
            logger.error("User (client) not found with ID: {}", sessionDto.getUserId());
            return new EntityNotFoundException("User (client) not found with ID: " + sessionDto.getUserId());
        });
    logger.info("Fetched initial clientUserFromDto with ID: {}", clientUserFromDto.getId());

    // Re-fetch to ensure managed state and log details
    Professional managedProfessional = professionalRepository.findById(professionalFromAuth.getId())
        .orElseThrow(() -> {
            logger.error("Failed to re-fetch professional with ID: {}", professionalFromAuth.getId());
            return new EntityNotFoundException("Professional not found on re-fetch with ID: " + professionalFromAuth.getId());
        });
    logger.info("Re-fetched managedProfessional with ID: {} and User Email: {}", managedProfessional.getId(), managedProfessional.getUser().getEmail());


    User managedClientUser = userRepository.findById(clientUserFromDto.getId())
        .orElseThrow(() -> {
            logger.error("Failed to re-fetch client user with ID: {}", clientUserFromDto.getId());
            return new EntityNotFoundException("Client user not found on re-fetch with ID: " + clientUserFromDto.getId());
        });
    logger.info("Re-fetched managedClientUser with ID: {}", managedClientUser.getId());

    // Create a new Session entity
    Session session = new Session(); // Create new session instance

    // Manually map fields from DTO
    session.setStartTime(sessionDto.getStartTime());
    session.setEndTime(sessionDto.getEndTime());
    session.setMode(sessionDto.getMode());
    session.setNotes(sessionDto.getNotes());
    // If DTO can carry a status, map it, otherwise default is fine
    if (sessionDto.getStatus() != null) {
        session.setStatus(sessionDto.getStatus());
    } else {
        session.setStatus(SessionStatus.SCHEDULED);
    }

    // Set the professional and user fields
    session.setProfessional(managedProfessional); // Use the re-fetched, managed instance
    session.setUser(managedClientUser);         // Use the re-fetched, managed instance

    // If status wasn't in DTO or needs override:
    session.setStatus(SessionStatus.SCHEDULED); // Explicitly set/override status

    logger.info("Attempting to save session with Professional ID: {} (User ID: {}) and Client User ID: {}",
            session.getProfessional().getId(), session.getProfessional().getUser().getId(), session.getUser().getId());
    if(session.getProfessional().getId() == null) {
        logger.error("CRITICAL: Professional ID is NULL before save for professional email: {}", professionalEmail);
        // Potentially throw an exception here if this condition is unexpected and critical
        throw new IllegalStateException("Professional ID is null before saving session for professional: " + professionalEmail);
    }


    // Save the Session entity
    Session savedSession = sessionRepository.save(session);
    logger.info("Session saved successfully with ID: {}", savedSession.getId());


    // Return the saved Session mapped back to a SessionDTO
    return mapper.toDTO(savedSession);
  }
}
