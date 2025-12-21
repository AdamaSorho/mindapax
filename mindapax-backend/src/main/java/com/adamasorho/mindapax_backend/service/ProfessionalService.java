package com.adamasorho.mindapax_backend.service;

import java.time.LocalDate;
import java.util.Set;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.security.core.GrantedAuthority;

import com.adamasorho.mindapax_backend.dto.UserDTO;
import com.adamasorho.mindapax_backend.model.Professional;
import com.adamasorho.mindapax_backend.model.enums.ProfessionalStatus;
import com.adamasorho.mindapax_backend.model.enums.Specialization;

public interface ProfessionalService {
  Page<UserDTO> getConnectedUsers(Long professionalId, Pageable pageable);
  Professional createProfessional(Professional professional);
  Professional getProfessionalById(Long id);
  Page<Professional> getProfessionals(
    String firstName,
    String lastName,
    Specialization specialization,
    Integer experience,
    LocalDate availabilityDate,
    Boolean availableOnly,
    ProfessionalStatus status,
    boolean excludeConnected,
    Long requesterUserId,
    Set<GrantedAuthority> authorities,
    Pageable pageable);
  Professional updateProfessional(Long id, Professional professional);
  void deleteProfessional(Long id);
  void updateProfessionalStatus(Long professionalId, ProfessionalStatus status, String rejectionNote, Set<GrantedAuthority> authorities);
  Page<Professional> findProfessionalsByStatus(ProfessionalStatus status, Set<GrantedAuthority> authorities, Pageable pageable);
}
