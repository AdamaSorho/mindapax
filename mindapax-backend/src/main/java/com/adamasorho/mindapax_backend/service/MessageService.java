package com.adamasorho.mindapax_backend.service;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

import com.adamasorho.mindapax_backend.dto.MessageDTO;
import com.adamasorho.mindapax_backend.model.Message;

public interface MessageService {
  Message sendMessage(MessageDTO messageDto);
  Page<Message> getMessageHistory(Long conversationId, Pageable pageable);
  Message getLastMessage(Long conversationId);
  int markConversationAsRead(Long conversationId, Long readerUserId);
}
