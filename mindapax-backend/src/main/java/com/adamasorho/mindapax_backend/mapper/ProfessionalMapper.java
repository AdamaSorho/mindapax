package com.adamasorho.mindapax_backend.mapper;

import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.Mappings;

import com.adamasorho.mindapax_backend.dto.ProfessionalDTO;
import com.adamasorho.mindapax_backend.model.Professional;

@Mapper(componentModel = "spring", uses = {UserMapper.class, CertificationMapper.class, AvailabilityMapper.class})
public interface ProfessionalMapper {
  
  @Mappings({
    @Mapping(target = "experienceYears", source = "yearsOfExperience"),
    @Mapping(target = "resumeUrl", source = "resumeFilePath"),
  })
  ProfessionalDTO toDTO(Professional professional);
  
  @Mappings({
    @Mapping(target = "sessions", ignore = true),
    @Mapping(target = "certifications", ignore = true),
    @Mapping(target = "resumeFilePath", ignore = true),
    @Mapping(target = "yearsOfExperience", source = "experienceYears"),
    @Mapping(target = "availabilities", ignore = true)
  })
  Professional toEntity(ProfessionalDTO professionalDTO);
}
