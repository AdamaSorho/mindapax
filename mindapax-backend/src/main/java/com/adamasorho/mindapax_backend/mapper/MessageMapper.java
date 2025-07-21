package com.adamasorho.mindapax_backend.mapper;

import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.Mappings;

import com.adamasorho.mindapax_backend.dto.MessageDTO;
import com.adamasorho.mindapax_backend.model.Message;

@Mapper(componentModel = "spring")
public interface MessageMapper {
  @Mappings({
      @Mapping(target = "sessionId", ignore = true),
      @Mapping(target = "conversationId", source = "conversation.id"),
      @Mapping(target = "senderId", source = "sender.id"),
      @Mapping(target = "read", source = "isRead")
  })
  MessageDTO toDTO(Message message);

  @Mappings({
      @Mapping(target = "conversation", ignore = true),
      @Mapping(target = "sender", ignore = true),
      @Mapping(target = "isRead", source = "read")
  })
  Message toEntity(MessageDTO messageDTO);
}
