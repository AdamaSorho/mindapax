package com.adamasorho.mindapax_backend.mapper;


import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.Mappings;

import com.adamasorho.mindapax_backend.dto.UserDTO;
import com.adamasorho.mindapax_backend.dto.request.AuthRequest;
import com.adamasorho.mindapax_backend.model.User;

@Mapper(componentModel = "spring")
public interface UserMapper {
  UserDTO toDTO(User user);
  
  @Mappings({
    @Mapping(target = "agreeTerms", ignore = true),
    @Mapping(target = "sessions", ignore = true),
    @Mapping(target = "password", ignore = true),
  })
  User toEntity(UserDTO userDTO);

  @Mappings({
    @Mapping(target = "id", ignore = true),
    @Mapping(target = "location", ignore = true),
    @Mapping(target = "sessions", ignore = true),
    @Mapping(target = "phone", ignore = true),
  })
  User toEntity(AuthRequest authRequest);
}
