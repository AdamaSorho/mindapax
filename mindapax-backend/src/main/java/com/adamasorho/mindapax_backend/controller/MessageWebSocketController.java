package com.adamasorho.mindapax_backend.controller;

import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.handler.annotation.SendTo;
import org.springframework.stereotype.Controller;

import com.adamasorho.mindapax_backend.dto.MessageDTO;
import com.adamasorho.mindapax_backend.mapper.MessageMapper;
import com.adamasorho.mindapax_backend.model.Message;
import com.adamasorho.mindapax_backend.service.MessageService;

import jakarta.validation.Valid;
import lombok.AllArgsConstructor;

@Controller
@AllArgsConstructor
public class MessageWebSocketController {

    private final MessageService messageService;
    private final MessageMapper messageMapper;

    @MessageMapping("/chat") // maps to /app/chat
    @SendTo("/topic/messages/{conversationId}") // everyone subscribed gets message
    public MessageDTO sendMessage(@Valid MessageDTO messageDTO) {
      Message message = messageService.sendMessage(messageMapper.toEntity(messageDTO));

      return messageMapper.toDTO(message);
    }
}

