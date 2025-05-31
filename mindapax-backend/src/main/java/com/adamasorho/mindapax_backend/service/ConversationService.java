package com.adamasorho.mindapax_backend.service;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

import com.adamasorho.mindapax_backend.model.Conversation;

public interface ConversationService {
  Conversation startOrGetConversation(Long userId, Long professionalId);
  Page<Conversation> getConversationsByUser(Long userId, Pageable pageable);
}
