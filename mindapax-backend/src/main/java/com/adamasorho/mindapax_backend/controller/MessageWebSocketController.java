package com.adamasorho.mindapax_backend.controller;

import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Controller;

import com.adamasorho.mindapax_backend.dto.MessageDTO;
import com.adamasorho.mindapax_backend.mapper.MessageMapper;
import com.adamasorho.mindapax_backend.model.Message;
import com.adamasorho.mindapax_backend.service.MessageService;

import io.swagger.v3.oas.annotations.parameters.RequestBody;
import jakarta.validation.Valid;
import lombok.AllArgsConstructor;

@Controller
@AllArgsConstructor
public class MessageWebSocketController {

    private final MessageService messageService;
    private final MessageMapper messageMapper;
    private final SimpMessagingTemplate simpMessagingTemplate;

    @MessageMapping("/chat") // maps to /app/chat
    public MessageDTO sendMessage(@RequestBody @Valid MessageDTO messageDTO) {
      Message message = messageService.sendMessage(messageMapper.toEntity(messageDTO));
      MessageDTO savedMessageDTO = messageMapper.toDTO(message);
      simpMessagingTemplate.convertAndSend("/topic/messages/" + savedMessageDTO.getConversationId(), savedMessageDTO);
      return savedMessageDTO;
    }
}

