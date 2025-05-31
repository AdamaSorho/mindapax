package com.adamasorho.mindapax_backend.service;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

import com.adamasorho.mindapax_backend.model.Message;

public interface MessageService {
  Message sendMessage(Message message);
  Page<Message> getMessageHistory(Long conversationId, Pageable pageable);
  Message getLastMessage(Long conversationId);
}
