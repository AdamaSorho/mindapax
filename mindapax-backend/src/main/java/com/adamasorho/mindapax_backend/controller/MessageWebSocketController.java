package com.adamasorho.mindapax_backend.controller;

import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.simp.SimpMessagingTemplate;
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
    private final SimpMessagingTemplate simpMessagingTemplate;

    @MessageMapping("/chat") // maps to /app/chat
    public MessageDTO sendMessage(@Valid MessageDTO messageDTO) {
      Message message = messageService.sendMessage(messageDTO); // Changed this line
      MessageDTO savedMessageDTO = messageMapper.toDTO(message);
      // propagate clientTag back to the client if provided
      savedMessageDTO.setClientTag(messageDTO.getClientTag());
      simpMessagingTemplate.convertAndSend("/topic/messages/" + savedMessageDTO.getConversationId(), savedMessageDTO);
      return savedMessageDTO;
    }
}
