package com.adamasorho.mindapax_backend.mapper;

import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.Mappings;

import com.adamasorho.mindapax_backend.dto.response.ConversationResponse;
import com.adamasorho.mindapax_backend.model.Conversation;

@Mapper(componentModel = "spring", uses = {UserMapper.class, ProfessionalMapper.class})
public interface ConversationMapper {
  @Mappings({
    @Mapping(target = "lastMessage", ignore = true),
  })
  ConversationResponse toDTO(Conversation conversation);
}
