package com.adamasorho.mindapax_backend.mapper;

import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.Mappings;

import com.adamasorho.mindapax_backend.dto.SessionDTO;
import com.adamasorho.mindapax_backend.model.Session;

@Mapper(componentModel = "spring")
public interface SessionMapper {
  @Mappings({
    @Mapping(target = "userId", source = "user.id"),
    @Mapping(target = "professionalId", source = "professional.id"),
    @Mapping(target = "professionalName", expression = "java(session.getProfessional().getUser().getFirstName() + \" \" + session.getProfessional().getUser().getLastName())"),
    @Mapping(target = "professionalSpecialization", source = "professional.specialization"),
    // No explicit mapping needed for durationMinutes if field names match in Session and SessionDTO for toDTO
    // and if no transformation is needed. MapStruct handles it by convention.
    // If we needed to rename: @Mapping(target = "durationInMins", source = "durationMinutes")
  })
  SessionDTO toDTO(Session session); // durationMinutes will be mapped automatically

  @Mappings({
    @Mapping(target = "user", ignore = true),
    @Mapping(target = "professional", ignore = true),
    // No explicit mapping needed for durationMinutes if field names match for toEntity
    // entity.setDurationMinutes(dto.getDurationMinutes()); will be handled by MapStruct.
    // If we needed to rename: @Mapping(target = "durationMinutes", source = "durationInMinsDTO")
  })
  Session toEntity(SessionDTO sessionDTO); // durationMinutes will be mapped automatically
}
