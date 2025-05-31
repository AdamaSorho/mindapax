package com.adamasorho.mindapax_backend.service.impl;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.Set;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.stereotype.Service;

import com.adamasorho.mindapax_backend.jpaSpecification.ProfessionalSpecification;
import com.adamasorho.mindapax_backend.model.Professional;
import com.adamasorho.mindapax_backend.model.enums.ProfessionalStatus;
import com.adamasorho.mindapax_backend.model.enums.Specialization;
import com.adamasorho.mindapax_backend.repository.ProfessionalRepository;
import com.adamasorho.mindapax_backend.service.ProfessionalService;

import jakarta.persistence.EntityNotFoundException;
import jakarta.transaction.Transactional;
import lombok.AllArgsConstructor;

@Service
@AllArgsConstructor
@Transactional
public class ProfessionalServiceImpl implements ProfessionalService {
  private final ProfessionalRepository professionalRepository;

  @Override
  public Professional createProfessional(Professional professional) {
    return professionalRepository.save(professional);
  }

  @Override
  public Professional getProfessionalById(Long id) {
    return professionalRepository.findById(id)
      .orElseThrow(() -> new EntityNotFoundException("Professional not found"));
  }

  @Override
  public Page<Professional> getProfessionals(String firstName, String lastName, Specialization specialization, 
      Integer experience, LocalDate availabilityDate, ProfessionalStatus status, 
      Set<GrantedAuthority> authorities, Pageable pageable) {
    if (!authorities.contains(new SimpleGrantedAuthority("ROLE_ADMIN")) && status != ProfessionalStatus.ACTIVE) {
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
            .orElseThrow(() -> new EntityNotFoundException("Professional not found"));

    existing.setBio(professional.getBio());
    existing.setCertifications(professional.getCertifications());
    existing.setSpecialization(professional.getSpecialization());
    existing.setHourlyRate(professional.getHourlyRate());

    return professionalRepository.save(existing);
  }

  @Override
  public void deleteProfessional(Long id) {
    if (!professionalRepository.existsById(id)) {
        throw new EntityNotFoundException("Professional not found");
    }
    professionalRepository.deleteById(id);
  }

  @Override
  public void updateProfessionalStatus(Long professionalId, ProfessionalStatus status, String rejectionNote, Set<GrantedAuthority> authorities) {
    if (!authorities.contains(new SimpleGrantedAuthority("ROLE_ADMIN")) && status == ProfessionalStatus.ACTIVE) {
      throw new AccessDeniedException("Only ADMIN can set ACTIVE status.");
    }

    Professional professional = this.getProfessionalById(professionalId);

    professional.setStatus(status);
    professional.setRejectionNote(rejectionNote);
    professional.setStatusUpdatedAt(LocalDateTime.now());
    professionalRepository.save(professional);
  }

  @Override
  public Page<Professional> findProfessionalsByStatus(ProfessionalStatus status, Set<GrantedAuthority> authorities, Pageable pageable) {
    if (!authorities.contains(new SimpleGrantedAuthority("ROLE_ADMIN")) && status != ProfessionalStatus.ACTIVE) {
      throw new AccessDeniedException("Only ACTIVE professionals are visible to regular users.");
    }
    return professionalRepository.findByStatus(status, pageable);
  }
}
