package com.adamasorho.mindapax_backend.service.impl;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.Set;
import java.security.SecureRandom; // Added import
import java.util.stream.Collectors; // Added import
import java.util.stream.IntStream;  // Added import

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.stereotype.Service;

import com.adamasorho.mindapax_backend.dto.UserDTO;
import com.adamasorho.mindapax_backend.jpaSpecification.ProfessionalSpecification;
import com.adamasorho.mindapax_backend.mapper.UserMapper;
import com.adamasorho.mindapax_backend.model.Connection;
import com.adamasorho.mindapax_backend.model.Professional;
import com.adamasorho.mindapax_backend.model.enums.ConnectionStatus;
import com.adamasorho.mindapax_backend.model.enums.ProfessionalStatus;
import com.adamasorho.mindapax_backend.model.enums.Specialization;
import com.adamasorho.mindapax_backend.repository.ConnectionRepository;
import com.adamasorho.mindapax_backend.repository.ProfessionalRepository;
import com.adamasorho.mindapax_backend.service.ProfessionalService;
import com.adamasorho.mindapax_backend.service.ZoomService;

import jakarta.persistence.EntityNotFoundException;
import jakarta.transaction.Transactional;

@Service
@Transactional
public class ProfessionalServiceImpl implements ProfessionalService {
  private static final Logger logger = LoggerFactory.getLogger(ProfessionalServiceImpl.class);

  private final ProfessionalRepository professionalRepository;
  private final ConnectionRepository connectionRepository;
  private final UserMapper userMapper;
  private final ZoomService zoomService;

  @Autowired
  public ProfessionalServiceImpl(
      ProfessionalRepository professionalRepository,
      ConnectionRepository connectionRepository,
      UserMapper userMapper,
      ZoomService zoomService) {
    this.professionalRepository = professionalRepository;
    this.connectionRepository = connectionRepository;
    this.userMapper = userMapper;
    this.zoomService = zoomService;
  }

  private String generateRandomPassword(int length) {
      final String CHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
      SecureRandom random = new SecureRandom();
      return IntStream.range(0, length)
          .map(i -> random.nextInt(CHARS.length()))
          .mapToObj(randomIndex -> String.valueOf(CHARS.charAt(randomIndex)))
          .collect(Collectors.joining());
  }

  @Override
  public Page<UserDTO> getConnectedUsers(Long professionalId, Pageable pageable) {
    Professional professional = professionalRepository.findById(professionalId)
            .orElseThrow(() -> new EntityNotFoundException("Professional not found with ID: " + professionalId));

    Page<Connection> connections = connectionRepository.findByProfessionalAndStatus(
            professional, ConnectionStatus.ACCEPTED, pageable);

    return connections.map(connection -> userMapper.toDTO(connection.getUser()));
  }

  @Override
  public Professional createProfessional(Professional professional) {
    return professionalRepository.save(professional);
  }

  @Override
  public Professional getProfessionalById(Long id) {
    return professionalRepository.findById(id)
      .orElseThrow(() -> new EntityNotFoundException("Professional not found with ID: " + id));
  }

  @Override
  public Page<Professional> getProfessionals(String firstName, String lastName, Specialization specialization, 
      Integer experience, LocalDate availabilityDate, ProfessionalStatus status, 
      Set<GrantedAuthority> authorities, Pageable pageable) {
    if (!authorities.contains(new SimpleGrantedAuthority("ROLE_ADMIN")) && status != ProfessionalStatus.ACTIVE) {
      logger.warn("Non-admin user attempted to access non-active professionals. User authorities: {}", authorities);
      throw new AccessDeniedException("Only ACTIVE professionals are visible to regular users.");
    }
    
    Specification<Professional> spec = Specification
            .where(ProfessionalSpecification.hasFirstName(firstName))
            .and(ProfessionalSpecification.hasLastName(lastName))
            .and(ProfessionalSpecification.hasSpecialization(specialization))
            .and(ProfessionalSpecification.hasExperienceGreaterThanOrEqual(experience))
            .and(ProfessionalSpecification.isAvailableOn(availabilityDate))
            .and(ProfessionalSpecification.hasStatus(status));

    return professionalRepository.findAll(spec, pageable);
  }

  @Override
  public Professional updateProfessional(Long id, Professional professionalUpdates) { // Renamed for clarity
    Professional existing = professionalRepository.findById(id)
            .orElseThrow(() -> new EntityNotFoundException("Professional not found with ID: " + id));

    existing.setBio(professionalUpdates.getBio());
    // Ensure certifications are handled correctly (e.g., clearing old ones if needed or merging)
    // This might require more complex logic depending on desired behavior.
    // For simplicity, assuming replacement or that DTO handles this.
    if (professionalUpdates.getCertifications() != null) {
        existing.getCertifications().clear();
        existing.getCertifications().addAll(professionalUpdates.getCertifications());
        existing.getCertifications().forEach(cert -> cert.setProfessional(existing)); // Ensure bidirectional link
    }
    existing.setSpecialization(professionalUpdates.getSpecialization());
    existing.setHourlyRate(professionalUpdates.getHourlyRate());
    existing.setYearsOfExperience(professionalUpdates.getYearsOfExperience()); // Added years of experience

    return professionalRepository.save(existing);
  }

  @Override
  public void deleteProfessional(Long id) {
    if (!professionalRepository.existsById(id)) {
        throw new EntityNotFoundException("Professional not found with ID: " + id);
    }
    professionalRepository.deleteById(id);
  }

  @Override
  public void updateProfessionalStatus(Long professionalId, ProfessionalStatus status, String rejectionNote, Set<GrantedAuthority> authorities) {
    if (!authorities.contains(new SimpleGrantedAuthority("ROLE_ADMIN")) && status == ProfessionalStatus.ACTIVE) {
        logger.warn("Non-admin user attempted to set professional status to ACTIVE for ID: {}. User authorities: {}", professionalId, authorities);
        throw new AccessDeniedException("Only ADMIN can set ACTIVE status.");
    }

    Professional professional = this.getProfessionalById(professionalId);

    if (status == ProfessionalStatus.ACTIVE && professional.getStatus() != ProfessionalStatus.ACTIVE && professional.getZoomMeetingId() == null) {
        try {
            String professionalFullName = professional.getUser().getFirstName() + " " + professional.getUser().getLastName();

            String generatedPassword = generateRandomPassword(10);
            logger.info("Generated Zoom meeting password for professional {} {} (ID: {})",
                        professional.getUser().getFirstName(), professional.getUser().getLastName(), professionalId);

            logger.info("Professional {} {} (ID: {}) is being approved. Attempting to create Zoom meeting with password.",
                        professional.getUser().getFirstName(), professional.getUser().getLastName(), professionalId);

            String meetingId = zoomService.createPermanentMeetingForProfessional(professionalFullName, generatedPassword);
            professional.setZoomMeetingId(meetingId);
            professional.setZoomMeetingPassword(generatedPassword); // Store the generated password

            logger.info("Successfully created Zoom meeting (ID: {}) and password, and set them for professional {} {} (ID: {})",
                        meetingId, professional.getUser().getFirstName(), professional.getUser().getLastName(), professionalId);
        } catch (Exception e) {
            logger.error("Failed to create Zoom meeting for professional {} {} (ID: {}): {}. Professional status will be updated without a Zoom ID/password.",
                         professional.getUser().getFirstName(), professional.getUser().getLastName(), professionalId, e.getMessage(), e);
        }
    }

    professional.setStatus(status);
    if (status == ProfessionalStatus.REJECTED || status == ProfessionalStatus.PENDING) {
         professional.setRejectionNote(rejectionNote);
    } else {
         professional.setRejectionNote(null);
    }
    professional.setStatusUpdatedAt(LocalDateTime.now());
    professionalRepository.save(professional);
    logger.info("Updated status for professional ID: {} to {}. Rejection note: '{}'", professionalId, status, professional.getRejectionNote());
  }

  @Override
  public Page<Professional> findProfessionalsByStatus(ProfessionalStatus status, Set<GrantedAuthority> authorities, Pageable pageable) {
    if (!authorities.contains(new SimpleGrantedAuthority("ROLE_ADMIN")) && status != ProfessionalStatus.ACTIVE) {
      logger.warn("Non-admin user attempted to find professionals by non-active status: {}. User authorities: {}", status, authorities);
      throw new AccessDeniedException("Only ACTIVE professionals are visible to regular users.");
    }
    return professionalRepository.findByStatus(status, pageable);
  }
}
