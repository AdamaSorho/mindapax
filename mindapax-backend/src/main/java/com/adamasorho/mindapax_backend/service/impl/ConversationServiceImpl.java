package com.adamasorho.mindapax_backend.service.impl;

import java.util.List; // Added import
import java.util.stream.Collectors; // Added import
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl; // Added import
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;

import com.adamasorho.mindapax_backend.dto.response.ConversationResponse; // Added import
import com.adamasorho.mindapax_backend.mapper.ConversationMapper; // Added import
import com.adamasorho.mindapax_backend.mapper.MessageMapper; // Added import
import com.adamasorho.mindapax_backend.model.Conversation;
import com.adamasorho.mindapax_backend.model.Message; // Added import
import com.adamasorho.mindapax_backend.model.Professional;
import com.adamasorho.mindapax_backend.model.User;
import com.adamasorho.mindapax_backend.repository.ConversationRepository;
import com.adamasorho.mindapax_backend.repository.MessageRepository; // Added import
import com.adamasorho.mindapax_backend.service.ConversationService;
import com.adamasorho.mindapax_backend.service.ProfessionalService;
import com.adamasorho.mindapax_backend.service.UserService;


@Service
public class ConversationServiceImpl implements ConversationService {

    private final ConversationRepository conversationRepository;
    private final UserService userService;
    private final ProfessionalService professionalService;
    private final MessageRepository messageRepository;         // Added field
    private final ConversationMapper conversationMapper;     // Added field
    private final MessageMapper messageMapper;               // Added field

    public ConversationServiceImpl(
            ConversationRepository conversationRepository,
            UserService userService,
            ProfessionalService professionalService,
            MessageRepository messageRepository,
            ConversationMapper conversationMapper,
            MessageMapper messageMapper) {
        this.conversationRepository = conversationRepository;
        this.userService = userService;
        this.professionalService = professionalService;
        this.messageRepository = messageRepository;
        this.conversationMapper = conversationMapper;
        this.messageMapper = messageMapper;
    }

    @Override
    public Conversation startOrGetConversation(Long userId, Long professionalId) {
        User user = userService.getUserById(userId);
        Professional professional = professionalService.getProfessionalById(professionalId);

        return conversationRepository
                .findByUserIdAndProfessionalId(userId, professionalId)
                .orElseGet(() -> {
                    Conversation conversation = new Conversation();
                    conversation.setUser(user);
                    conversation.setProfessional(professional);
                    return conversationRepository.save(conversation);
                });
    }

    @Override
    public Page<ConversationResponse> getConversationsByUser(Long userId, Pageable pageable) {
        Page<Conversation> conversationPage = conversationRepository.findByUserIdOrProfessionalId(userId, userId, pageable);

        List<ConversationResponse> dtos = conversationPage.getContent().stream()
                .map(conversationEntity -> {
                    ConversationResponse conversationDto = conversationMapper.toDTO(conversationEntity);

                    // Fetch and set the last message
                    Message lastMessageEntity = messageRepository
                            .findTopByConversationOrderByTimestampDesc(conversationEntity)
                            .orElse(null);

                    if (lastMessageEntity != null) {
                        conversationDto.setLastMessage(messageMapper.toDTO(lastMessageEntity));
                    }
                    return conversationDto;
                })
                .collect(Collectors.toList());

        return new PageImpl<>(dtos, pageable, conversationPage.getTotalElements());
    }
}
