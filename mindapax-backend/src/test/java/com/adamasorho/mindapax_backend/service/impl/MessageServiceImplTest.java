package com.adamasorho.mindapax_backend.service.impl;

import com.adamasorho.mindapax_backend.dto.MessageDTO;
import com.adamasorho.mindapax_backend.mapper.MessageMapper;
import com.adamasorho.mindapax_backend.model.Conversation;
import com.adamasorho.mindapax_backend.model.Message;
import com.adamasorho.mindapax_backend.model.User;
import com.adamasorho.mindapax_backend.repository.ConversationRepository;
import com.adamasorho.mindapax_backend.repository.MessageRepository;
import com.adamasorho.mindapax_backend.repository.UserRepository;
import jakarta.persistence.EntityNotFoundException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDateTime;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
public class MessageServiceImplTest {

    @Mock
    private MessageRepository messageRepository;

    @Mock
    private ConversationRepository conversationRepository;

    @Mock
    private UserRepository userRepository;

    @Mock
    private MessageMapper messageMapper;

    @InjectMocks
    private MessageServiceImpl messageService;

    private MessageDTO messageDTO;
    private Message messageEntity;
    private Conversation conversation;
    private User sender;

    @BeforeEach
    void setUp() {
        // MockitoAnnotations.openMocks(this); // Not needed with @ExtendWith(MockitoExtension.class)

        messageDTO = new MessageDTO();
        messageDTO.setConversationId(1L);
        messageDTO.setSenderId(1L);
        messageDTO.setContent("Hello");

        conversation = new Conversation();
        conversation.setId(1L);

        sender = new User();
        sender.setId(1L);

        messageEntity = new Message(); // In a real scenario, MessageMapper would create this
        messageEntity.setContent("Hello"); // Assume mapper maps this
    }

    @Test
    void sendMessage_successPath() {
        // Arrange
        when(messageMapper.toEntity(any(MessageDTO.class))).thenReturn(messageEntity);
        when(conversationRepository.findById(1L)).thenReturn(Optional.of(conversation));
        when(userRepository.findById(1L)).thenReturn(Optional.of(sender));
        when(messageRepository.save(any(Message.class))).thenAnswer(invocation -> {
            Message savedMessage = invocation.getArgument(0);
            savedMessage.setId(1L); // Simulate save generating an ID
            savedMessage.setTimestamp(LocalDateTime.now()); // Simulate timestamp set by service
            return savedMessage;
        });

        // Act
        Message result = messageService.sendMessage(messageDTO);

        // Assert
        assertNotNull(result);
        assertEquals(1L, result.getId());
        assertEquals(messageDTO.getContent(), result.getContent());
        assertEquals(conversation, result.getConversation());
        assertEquals(sender, result.getSender());
        assertNotNull(result.getTimestamp());

        verify(messageMapper, times(1)).toEntity(messageDTO);
        verify(conversationRepository, times(1)).findById(1L);
        verify(userRepository, times(1)).findById(1L);
        verify(messageRepository, times(1)).save(messageEntity);

        // Verify that setConversation and setSender were effectively called on messageEntity
        // This is indirectly verified by checking the result's conversation and sender fields
        // and by the fact that messageRepository.save was called with messageEntity
        // which should have had these fields set.
        assertEquals(conversation, messageEntity.getConversation());
        assertEquals(sender, messageEntity.getSender());
    }

    @Test
    void sendMessage_failure_conversationNotFound() {
        // Arrange
        when(messageMapper.toEntity(any(MessageDTO.class))).thenReturn(messageEntity);
        when(conversationRepository.findById(1L)).thenReturn(Optional.empty());

        // Act & Assert
        EntityNotFoundException exception = assertThrows(EntityNotFoundException.class, () -> {
            messageService.sendMessage(messageDTO);
        });
        assertEquals("Conversation not found with ID: 1", exception.getMessage());

        verify(messageMapper, times(1)).toEntity(messageDTO);
        verify(conversationRepository, times(1)).findById(1L);
        verify(userRepository, never()).findById(anyLong());
        verify(messageRepository, never()).save(any(Message.class));
    }

    @Test
    void sendMessage_failure_senderNotFound() {
        // Arrange
        when(messageMapper.toEntity(any(MessageDTO.class))).thenReturn(messageEntity);
        when(conversationRepository.findById(1L)).thenReturn(Optional.of(conversation));
        when(userRepository.findById(1L)).thenReturn(Optional.empty());

        // Act & Assert
        EntityNotFoundException exception = assertThrows(EntityNotFoundException.class, () -> {
            messageService.sendMessage(messageDTO);
        });
        assertEquals("Sender (User) not found with ID: 1", exception.getMessage());

        verify(messageMapper, times(1)).toEntity(messageDTO);
        verify(conversationRepository, times(1)).findById(1L);
        verify(userRepository, times(1)).findById(1L);
        verify(messageRepository, never()).save(any(Message.class));
    }
}
