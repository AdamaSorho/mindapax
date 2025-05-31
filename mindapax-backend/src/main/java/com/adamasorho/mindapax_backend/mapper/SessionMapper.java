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
    @Mapping(target = "professionalId", source = "professional.id")
  })
  SessionDTO toDTO(Session session);

  @Mappings({
    @Mapping(target = "user", ignore = true),
    @Mapping(target = "professional", ignore = true)
  })
  Session toEntity(SessionDTO sessionDTO);
}
