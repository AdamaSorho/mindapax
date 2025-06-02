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
import lombok.AllArgsConstructor; // Keep if other constructors use it, or remove if specific constructor is added
import lombok.extern.slf4j.Slf4j;

import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.transaction.annotation.Transactional;

@Service
@Slf4j
// Consider removing @AllArgsConstructor if you add a specific constructor
public class SessionServiceImpl implements SessionService {
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
    String currentPrincipalName = authentication.getName(); // This is usually the email

    // Fetch the Professional entity based on the email
    // Assuming ProfessionalRepository has a findByUserEmail method.
    // If not, this needs to be added to ProfessionalRepository.
    log.info("Current principal name: {}", currentPrincipalName);
    Professional professional = professionalRepository.findByUserEmail(currentPrincipalName)
        .orElseThrow(() -> new EntityNotFoundException("Professional not found with email: " + currentPrincipalName));

    // Validate that the userId from the DTO corresponds to an existing User
    User user = userRepository.findById(sessionDto.getUserId())
        .orElseThrow(() -> new EntityNotFoundException("User not found with ID: " + sessionDto.getUserId()));

    // Create a new Session entity
    Session session = mapper.toEntity(sessionDto);

    // Set the professional and user fields
    session.setProfessional(professional);
    session.setUser(user);

    // Set the status to SCHEDULED by default
    session.setStatus(SessionStatus.SCHEDULED);
    
    // Explicitly set professionalId and userId in the DTO before mapping,
    // or ensure mapper handles this if toEntity is used.
    // The current mapper.toEntity might ignore professional and user objects if they are complex.
    // It's safer to set them on the entity directly as done above.

    // Save the Session entity
    Session savedSession = sessionRepository.save(session);

    // Return the saved Session mapped back to a SessionDTO
    return mapper.toDTO(savedSession);
  }
}
