package com.adamasorho.mindapax_backend.service.impl;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;

import com.adamasorho.mindapax_backend.model.Conversation;
import com.adamasorho.mindapax_backend.model.Professional;
import com.adamasorho.mindapax_backend.model.User;
import com.adamasorho.mindapax_backend.repository.ConversationRepository;
import com.adamasorho.mindapax_backend.service.ConversationService;
import com.adamasorho.mindapax_backend.service.ProfessionalService;
import com.adamasorho.mindapax_backend.service.UserService;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class ConversationServiceImpl implements ConversationService {

    private final ConversationRepository conversationRepository;
    private final UserService userService;
    private final ProfessionalService professionalService;

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
    public Page<Conversation> getConversationsByUser(Long userId, Pageable pageable) {
        return conversationRepository.findByUserIdOrProfessionalId(userId, userId, pageable);
    }
}
