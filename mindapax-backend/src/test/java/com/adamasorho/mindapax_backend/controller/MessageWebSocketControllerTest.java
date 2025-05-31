package com.adamasorho.mindapax_backend.controller;

import com.adamasorho.mindapax_backend.dto.MessageDTO;
import com.adamasorho.mindapax_backend.mapper.MessageMapper;
import com.adamasorho.mindapax_backend.model.Message;
import com.adamasorho.mindapax_backend.service.MessageService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith; // Added
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension; // Added
import org.springframework.messaging.simp.SimpMessagingTemplate;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq; // Added
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class) // Added
public class MessageWebSocketControllerTest {

    @Mock
    private MessageService messageService;

    @Mock
    private MessageMapper messageMapper;

    @Mock
    private SimpMessagingTemplate simpMessagingTemplate;

    @InjectMocks
    private MessageWebSocketController messageWebSocketController;

    // @BeforeEach // setUp can be removed if not strictly needed or kept for clarity
    // public void setUp() {
    //     // MockitoAnnotations.openMocks(this); // Not needed with @ExtendWith
    // }

    @Test
    public void testSendMessage_routesToCorrectTopic() { // Renamed for clarity
        // 1. Create a sample input MessageDTO
        MessageDTO inputMessageDTO = new MessageDTO();
        inputMessageDTO.setConversationId(1L); // Use Long for ID
        inputMessageDTO.setContent("Hello from test");
        inputMessageDTO.setSenderId(100L); // Use senderId

        // 2. Mock Message returned by service
        Message messageFromService = new Message();
        // Populate messageFromService if any fields are used by mapper or later logic
        // For this test, primarily its presence is important.

        // 3. Mock MessageDTO returned by mapper (this is what's sent over WebSocket)
        MessageDTO mappedDtoForTopic = new MessageDTO();
        mappedDtoForTopic.setConversationId(1L); // Crucial for topic destination
        mappedDtoForTopic.setContent("Hello from test"); // Match input or transformed
        mappedDtoForTopic.setSenderId(100L);
        // Set other fields if they are expected in the DTO sent over WebSocket

        // 4. Mock service and mapper methods
        // Service now takes MessageDTO and returns Message
        when(messageService.sendMessage(any(MessageDTO.class))).thenReturn(messageFromService);
        // Mapper takes Message and returns MessageDTO
        when(messageMapper.toDTO(any(Message.class))).thenReturn(mappedDtoForTopic);

        // 5. Call the sendMessage method
        MessageDTO resultDTO = messageWebSocketController.sendMessage(inputMessageDTO);

        // 6. Verify interactions
        // Verify messageService.sendMessage was called with the input DTO
        verify(messageService, times(1)).sendMessage(inputMessageDTO);
        // Verify messageMapper.toDTO was called with the message returned by the service
        verify(messageMapper, times(1)).toDTO(messageFromService);
        // Verify SimpMessagingTemplate.convertAndSend was called with the correct topic and payload
        verify(simpMessagingTemplate, times(1)).convertAndSend(
                eq("/topic/messages/1"), // Dynamic topic based on conversationId
                eq(mappedDtoForTopic)
        );

        // 7. Assert the returned DTO is the one from the mapper
        assertEquals(mappedDtoForTopic, resultDTO);
    }
}
