package com.adamasorho.mindapax_backend.mapper;

import org.mapstruct.Mapper;

import com.adamasorho.mindapax_backend.dto.response.ConnectionResponse;
import com.adamasorho.mindapax_backend.model.Connection;

@Mapper(componentModel = "spring", uses = {ProfessionalMapper.class, UserMapper.class})
public interface ConnectionMapper {
  ConnectionResponse toDTO(Connection connection);
}
