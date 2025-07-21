package com.adamasorho.mindapax_backend.service.impl;

import com.adamasorho.mindapax_backend.dto.MessageDTO;
import com.adamasorho.mindapax_backend.dto.response.ConversationResponse;
import com.adamasorho.mindapax_backend.mapper.ConversationMapper;
import com.adamasorho.mindapax_backend.mapper.MessageMapper;
import com.adamasorho.mindapax_backend.model.Conversation;
import com.adamasorho.mindapax_backend.model.Message;
import com.adamasorho.mindapax_backend.model.User;
import com.adamasorho.mindapax_backend.model.Professional;
import com.adamasorho.mindapax_backend.repository.ConversationRepository;
import com.adamasorho.mindapax_backend.repository.MessageRepository;
import com.adamasorho.mindapax_backend.service.UserService;
import com.adamasorho.mindapax_backend.service.ProfessionalService;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;

import java.time.LocalDateTime;
import java.util.Collections;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
public class ConversationServiceImplTest {

    @Mock
    private ConversationRepository conversationRepository;

    @Mock
    private MessageRepository messageRepository;

    @Mock
    private ConversationMapper conversationMapper;

    @Mock
    private MessageMapper messageMapper;

    @Mock
    private UserService userService; // Keep if startOrGetConversation is tested, or remove

    @Mock
    private ProfessionalService professionalService; // Keep if startOrGetConversation is tested, or remove

    @InjectMocks
    private ConversationServiceImpl conversationService;

    private User testUser;
    private Professional testProfessional;
    private Conversation testConversation;
    private Message testLastMessage;
    private ConversationResponse testConversationResponse;
    private MessageDTO testMessageDTO;
    private Pageable pageable;
    private Long userId = 1L;

    @BeforeEach
    void setUp() {
        testUser = new User();
        testUser.setId(userId);

        testProfessional = new Professional();
        testProfessional.setId(2L);
        testProfessional.setUser(new User()); // Professional has an associated User

        testConversation = new Conversation();
        testConversation.setId(10L);
        testConversation.setUser(testUser);
        testConversation.setProfessional(testProfessional);

        testLastMessage = new Message();
        testLastMessage.setId(100L);
        testLastMessage.setContent("Hello World");
        testLastMessage.setTimestamp(LocalDateTime.now());
        testLastMessage.setConversation(testConversation);
        testLastMessage.setSender(testUser);

        testConversationResponse = new ConversationResponse();
        testConversationResponse.setId(testConversation.getId());
        // Assume other fields are mapped by conversationMapper

        testMessageDTO = new MessageDTO();
        testMessageDTO.setId(testLastMessage.getId());
        testMessageDTO.setContent(testLastMessage.getContent());
        testMessageDTO.setTimestamp(testLastMessage.getTimestamp());
        testMessageDTO.setConversationId(testConversation.getId());
        testMessageDTO.setSenderId(testUser.getId());

        pageable = PageRequest.of(0, 10);
    }

    @Test
    void getConversationsByUser_successPath_withLastMessage() {
        // Arrange
        Page<Conversation> conversationPage = new PageImpl<>(Collections.singletonList(testConversation), pageable, 1);

        when(conversationRepository.findByUserIdOrProfessionalId(userId, userId, pageable)).thenReturn(conversationPage);
        when(conversationMapper.toDTO(testConversation)).thenReturn(testConversationResponse);
        when(messageRepository.findTopByConversationOrderByTimestampDesc(testConversation)).thenReturn(Optional.of(testLastMessage));
        when(messageMapper.toDTO(testLastMessage)).thenReturn(testMessageDTO);

        // Act
        Page<ConversationResponse> resultPage = conversationService.getConversationsByUser(userId, pageable);

        // Assert
        assertNotNull(resultPage);
        assertEquals(1, resultPage.getContent().size());
        ConversationResponse firstResponse = resultPage.getContent().get(0);

        assertNotNull(firstResponse.getLastMessage());
        assertEquals(testMessageDTO.getId(), firstResponse.getLastMessage().getId());
        assertEquals(testMessageDTO.getContent(), firstResponse.getLastMessage().getContent());

        verify(conversationRepository, times(1)).findByUserIdOrProfessionalId(userId, userId, pageable);
        verify(conversationMapper, times(1)).toDTO(testConversation);
        verify(messageRepository, times(1)).findTopByConversationOrderByTimestampDesc(testConversation);
        verify(messageMapper, times(1)).toDTO(testLastMessage);
    }

    @Test
    void getConversationsByUser_successPath_noLastMessage() {
        // Arrange
        Page<Conversation> conversationPage = new PageImpl<>(Collections.singletonList(testConversation), pageable, 1);

        when(conversationRepository.findByUserIdOrProfessionalId(userId, userId, pageable)).thenReturn(conversationPage);
        when(conversationMapper.toDTO(testConversation)).thenReturn(testConversationResponse); // initial DTO
        when(messageRepository.findTopByConversationOrderByTimestampDesc(testConversation)).thenReturn(Optional.empty());

        // Act
        Page<ConversationResponse> resultPage = conversationService.getConversationsByUser(userId, pageable);

        // Assert
        assertNotNull(resultPage);
        assertEquals(1, resultPage.getContent().size());
        ConversationResponse firstResponse = resultPage.getContent().get(0);

        assertNull(firstResponse.getLastMessage());

        verify(conversationRepository, times(1)).findByUserIdOrProfessionalId(userId, userId, pageable);
        verify(conversationMapper, times(1)).toDTO(testConversation);
        verify(messageRepository, times(1)).findTopByConversationOrderByTimestampDesc(testConversation);
        verify(messageMapper, never()).toDTO(any(Message.class)); // Should not be called if no last message
    }

    @Test
    void getConversationsByUser_paginationPropagation() {
        // Arrange
        List<Conversation> conversations = List.of(new Conversation(), new Conversation());
        long totalElements = 25L;
        Pageable requestedPageable = PageRequest.of(2, 5); // Request page 2, size 5
        Page<Conversation> conversationPage = new PageImpl<>(conversations, requestedPageable, totalElements);

        when(conversationRepository.findByUserIdOrProfessionalId(userId, userId, requestedPageable)).thenReturn(conversationPage);

        // Mock mapper calls for each conversation - for simplicity, assume they map and return empty last messages
        when(conversationMapper.toDTO(any(Conversation.class))).thenAnswer(invocation -> {
            Conversation c = invocation.getArgument(0);
            ConversationResponse cr = new ConversationResponse();
            cr.setId(c.getId()); // Just map ID for differentiation if needed
            return cr;
        });
        when(messageRepository.findTopByConversationOrderByTimestampDesc(any(Conversation.class))).thenReturn(Optional.empty());


        // Act
        Page<ConversationResponse> resultPage = conversationService.getConversationsByUser(userId, requestedPageable);

        // Assert
        assertNotNull(resultPage);
        assertEquals(conversations.size(), resultPage.getNumberOfElements()); // Number of elements in the current page
        assertEquals(requestedPageable.getPageNumber(), resultPage.getNumber()); // Current page number
        assertEquals(totalElements, resultPage.getTotalElements()); // Total elements across all pages
        assertEquals(requestedPageable.getPageSize(), resultPage.getSize()); // Page size
        assertEquals((int) Math.ceil((double) totalElements / requestedPageable.getPageSize()), resultPage.getTotalPages()); // Total pages

        verify(conversationRepository, times(1)).findByUserIdOrProfessionalId(userId, userId, requestedPageable);
        verify(conversationMapper, times(conversations.size())).toDTO(any(Conversation.class));
        verify(messageRepository, times(conversations.size())).findTopByConversationOrderByTimestampDesc(any(Conversation.class));
    }
}
