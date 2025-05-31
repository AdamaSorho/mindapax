package com.adamasorho.mindapax_backend.service.impl;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import com.adamasorho.mindapax_backend.dto.request.AuthRequest;
import com.adamasorho.mindapax_backend.exception.BadRequestException;
import com.adamasorho.mindapax_backend.mapper.UserMapper;
import com.adamasorho.mindapax_backend.model.Certification;
import com.adamasorho.mindapax_backend.model.Professional;
import com.adamasorho.mindapax_backend.model.User;
import com.adamasorho.mindapax_backend.model.enums.ProfessionalStatus;
import com.adamasorho.mindapax_backend.model.enums.UserRole;
import com.adamasorho.mindapax_backend.service.AuthService;
import com.adamasorho.mindapax_backend.service.FileStorageService;
import com.adamasorho.mindapax_backend.service.UserService;

import jakarta.transaction.Transactional;
import lombok.AllArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@Service
@AllArgsConstructor
@Transactional
@Slf4j
public class AuthServiceImpl implements AuthService {
  private final UserService userService;
  private final FileStorageService fileStorageService;
  private final UserMapper userMapper;

  @Override
  @Transactional
  public User register(AuthRequest authRequest, MultipartFile resume, MultipartFile[] certifications) {
    User user = userService.createUser(userMapper.toEntity(authRequest));
    // If professional, handle professional profile and documents
    if (authRequest.getRole() == UserRole.PROFESSIONAL) {
      handleProfessionalRegistration(user, authRequest, resume, certifications);
    }

    return user;
  }

  private void handleProfessionalRegistration(User user, 
                                            AuthRequest request, 
                                            MultipartFile resume, 
                                            MultipartFile[] certifications) {
        // Validate professional details
        if (request.getProfessionalDetails() == null ||
            request.getProfessionalDetails().getSpecialization() == null ||
            request.getProfessionalDetails().getExperienceYears() == null) {
            throw new BadRequestException("Professional details are required");
        }

        // Validate resume file
        if (resume == null || resume.isEmpty()) {
            throw new BadRequestException("Resume file is required");
        }

        // Validate certification files
        if (certifications == null || certifications.length == 0) {
            throw new BadRequestException("At least one certification file is required");
        }

        // Store resume file
        String resumePath = fileStorageService.storeFile(resume, "resumes");

        // Create professional profile
        Professional professional = Professional.builder()
                .user(user)
                .specialization(request.getProfessionalDetails().getSpecialization())
                .yearsOfExperience(request.getProfessionalDetails().getExperienceYears())
                .resumeFilePath(resumePath)
                .status(ProfessionalStatus.PENDING)
                .certifications(Collections.emptyList()) // Will be populated after saving
                .verified(false) // Professional profiles need verification by admin
                .build();

        user.setProfessional(professional);

        // Store certification files
        List<String> certificationPaths = fileStorageService.storeFiles(certifications, "certifications");
        List<Certification> certificationsList = new ArrayList<>(professional.getCertifications());
        
        // Add certifications
        for (int i = 0; i < certifications.length; i++) {
            MultipartFile file = certifications[i];
            String filePath = certificationPaths.get(i);
            
            Certification certification = Certification.builder()
                    .professional(professional)
                    .filePath(filePath)
                    .fileName(file.getOriginalFilename())
                    .fileType(file.getContentType())
                    .fileSize(file.getSize())
                    .build();
            
            certificationsList.add(certification);
        }
        // Fix for the UnsupportedOperationException
        professional.setCertifications(certificationsList);
      }
}
