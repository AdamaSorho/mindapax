package com.adamasorho.mindapax_backend.controller;

import com.adamasorho.mindapax_backend.dto.MessageDTO;
import com.adamasorho.mindapax_backend.mapper.MessageMapper;
import com.adamasorho.mindapax_backend.model.Message;
import com.adamasorho.mindapax_backend.service.MessageService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;
import org.springframework.messaging.simp.SimpMessagingTemplate;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

public class MessageWebSocketControllerTest {

    @Mock
    private MessageService messageService;

    @Mock
    private MessageMapper messageMapper;

    @Mock
    private SimpMessagingTemplate simpMessagingTemplate;

    @InjectMocks
    private MessageWebSocketController messageWebSocketController;

    @BeforeEach
    public void setUp() {
        MockitoAnnotations.openMocks(this);
    }

    @Test
    public void testSendMessage() {
        // 1. Create a sample MessageDTO
        MessageDTO messageDTO = new MessageDTO();
        messageDTO.setConversationId("testConversationId");
        messageDTO.setContent("Hello");
        messageDTO.setSender("testSender");

        // 2. Mock Message and its mapping
        Message message = new Message(); // Assume Message has a default constructor
        MessageDTO mappedMessageDTO = new MessageDTO(); // This will be returned by mapper.toDTO
        mappedMessageDTO.setConversationId("testConversationId");
        mappedMessageDTO.setContent("Hello");
        mappedMessageDTO.setSender("testSender");


        // 3. Mock service and mapper methods
        when(messageMapper.toEntity(any(MessageDTO.class))).thenReturn(message);
        when(messageService.sendMessage(any(Message.class))).thenReturn(message);
        when(messageMapper.toDTO(any(Message.class))).thenReturn(mappedMessageDTO);

        // 4. Call the sendMessage method
        messageWebSocketController.sendMessage(messageDTO);

        // 5. Verify interactions
        verify(messageMapper, times(1)).toEntity(messageDTO);
        verify(messageService, times(1)).sendMessage(message);
        verify(messageMapper, times(1)).toDTO(message);
        verify(simpMessagingTemplate, times(1)).convertAndSend(
                eq("/topic/messages/testConversationId"),
                eq(mappedMessageDTO)
        );
    }
}
