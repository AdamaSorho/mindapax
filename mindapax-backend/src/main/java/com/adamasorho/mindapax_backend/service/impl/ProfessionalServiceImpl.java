package com.adamasorho.mindapax_backend.service.impl;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.Set;

import org.slf4j.Logger; // Added import
import org.slf4j.LoggerFactory; // Added import
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
import com.adamasorho.mindapax_backend.service.ZoomService; // Added import

import jakarta.persistence.EntityNotFoundException;
import jakarta.transaction.Transactional;

@Service
@Transactional
public class ProfessionalServiceImpl implements ProfessionalService {
  private static final Logger logger = LoggerFactory.getLogger(ProfessionalServiceImpl.class); // Added logger

  private final ProfessionalRepository professionalRepository;
  private final ConnectionRepository connectionRepository;
  private final UserMapper userMapper;
  private final ZoomService zoomService; // Added ZoomService field

  @Autowired
  public ProfessionalServiceImpl(
      ProfessionalRepository professionalRepository,
      ConnectionRepository connectionRepository,
      UserMapper userMapper,
      ZoomService zoomService) { // Added ZoomService to constructor
    this.professionalRepository = professionalRepository;
    this.connectionRepository = connectionRepository;
    this.userMapper = userMapper;
    this.zoomService = zoomService; // Assigned ZoomService
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
      .orElseThrow(() -> new EntityNotFoundException("Professional not found with ID: " + id)); // Enhanced message
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
  public Professional updateProfessional(Long id, Professional professional) {
    Professional existing = professionalRepository.findById(id)
            .orElseThrow(() -> new EntityNotFoundException("Professional not found with ID: " + id)); // Enhanced message

    existing.setBio(professional.getBio());
    existing.setCertifications(professional.getCertifications());
    existing.setSpecialization(professional.getSpecialization());
    existing.setHourlyRate(professional.getHourlyRate());
    // Consider other fields that might be updatable by the professional themselves

    return professionalRepository.save(existing);
  }

  @Override
  public void deleteProfessional(Long id) {
    if (!professionalRepository.existsById(id)) {
        throw new EntityNotFoundException("Professional not found with ID: " + id); // Enhanced message
    }
    professionalRepository.deleteById(id);
  }

  @Override
  public void updateProfessionalStatus(Long professionalId, ProfessionalStatus status, String rejectionNote, Set<GrantedAuthority> authorities) {
    // Admin role check for ACTIVE status
    if (!authorities.contains(new SimpleGrantedAuthority("ROLE_ADMIN")) && status == ProfessionalStatus.ACTIVE) {
        logger.warn("Non-admin user attempted to set professional status to ACTIVE for ID: {}. User authorities: {}", professionalId, authorities);
        throw new AccessDeniedException("Only ADMIN can set ACTIVE status.");
    }
    // Consider adding more role checks if other status transitions need to be restricted.

    Professional professional = this.getProfessionalById(professionalId); // Uses enhanced message if not found

    // Logic for creating Zoom meeting ID if status is changing to ACTIVE
    if (status == ProfessionalStatus.ACTIVE && professional.getStatus() != ProfessionalStatus.ACTIVE && professional.getZoomMeetingId() == null) {
        // Check current status to ensure this logic only runs when transitioning TO ACTIVE
        // and if they don't already have a zoomMeetingId
        try {
            String professionalFullName = professional.getUser().getFirstName() + " " + professional.getUser().getLastName();
            logger.info("Professional {} {} (ID: {}) is being approved. Attempting to create Zoom meeting.",
                        professional.getUser().getFirstName(), professional.getUser().getLastName(), professionalId);
            String meetingId = zoomService.createPermanentMeetingForProfessional(professionalFullName);
            professional.setZoomMeetingId(meetingId);
            logger.info("Successfully created and set Zoom Meeting ID {} for professional {} {} (ID: {})",
                        meetingId, professional.getUser().getFirstName(), professional.getUser().getLastName(), professionalId);
        } catch (Exception e) {
            // Log the error. Decide if the approval process should halt or continue.
            // For now, log and continue with status update. Professional will not have a meeting ID.
            logger.error("Failed to create Zoom meeting for professional {} {} (ID: {}): {}. Professional status will be updated without a Zoom ID.",
                         professional.getUser().getFirstName(), professional.getUser().getLastName(), professionalId, e.getMessage(), e);
            // Potentially, you might want to throw a specific application exception here
            // or set a flag on the professional indicating Zoom setup failed.
        }
    }

    professional.setStatus(status);
    if (status == ProfessionalStatus.REJECTED || status == ProfessionalStatus.PENDING) {
         professional.setRejectionNote(rejectionNote);
    } else {
         professional.setRejectionNote(null); // Clear rejection note if status is not REJECTED/PENDING
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
