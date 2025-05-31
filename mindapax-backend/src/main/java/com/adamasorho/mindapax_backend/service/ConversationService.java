package com.adamasorho.mindapax_backend.service;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import com.adamasorho.mindapax_backend.dto.response.ConversationResponse; // Added import
import com.adamasorho.mindapax_backend.model.Conversation;


public interface ConversationService {
  Conversation startOrGetConversation(Long userId, Long professionalId);
  Page<ConversationResponse> getConversationsByUser(Long userId, Pageable pageable); // Signature changed
}
