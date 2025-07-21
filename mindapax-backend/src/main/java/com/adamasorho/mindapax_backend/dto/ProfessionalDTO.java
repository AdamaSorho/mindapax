package com.adamasorho.mindapax_backend.dto;

import java.time.LocalDateTime;
import java.util.List;

import com.adamasorho.mindapax_backend.model.enums.ProfessionalStatus;
import com.adamasorho.mindapax_backend.model.enums.Specialization;

import lombok.Data;

@Data
public class ProfessionalDTO {
  private Long id;
  private String bio;
  private Specialization specialization;
  private Integer experienceYears;
  private Double hourlyRate;
  private UserDTO user;
  private ProfessionalStatus status;
  private String rejectionNote;
  private String resumeUrl;
  private String resumeFileUrl;
  private List <CertificationDTO> certifications;
  private LocalDateTime createdAt;
  private LocalDateTime statusUpdatedAt;
  private Integer rating;
  private boolean verified;
}
