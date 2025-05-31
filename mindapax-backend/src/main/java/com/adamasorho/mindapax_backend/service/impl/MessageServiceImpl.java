package com.adamasorho.mindapax_backend.service.impl;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;

import com.adamasorho.mindapax_backend.model.Message;
import com.adamasorho.mindapax_backend.repository.MessageRepository;
import com.adamasorho.mindapax_backend.service.MessageService;

import lombok.AllArgsConstructor;

@Service
@AllArgsConstructor
public class MessageServiceImpl implements MessageService {
  private final MessageRepository messageRepository;

  @Override
  public Message sendMessage(Message message) {
    return messageRepository.save(message);
  }


  @Override
  public Page<Message> getMessageHistory(Long conversationId, Pageable pageable) {
    return messageRepository.findByConversationId(conversationId, pageable);
  }

  @Override
  public Message getLastMessage(Long conversationId) {
    return messageRepository.findTopByConversationIdOrderByTimestampDesc(conversationId)
      .orElse(null);
  }
}
