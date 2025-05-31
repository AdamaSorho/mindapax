package com.adamasorho.mindapax_backend.service.impl;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import java.time.LocalDateTime; // Added import
import jakarta.persistence.EntityNotFoundException; // Added import
import org.springframework.stereotype.Service;

import com.adamasorho.mindapax_backend.dto.MessageDTO; // Added import
import com.adamasorho.mindapax_backend.mapper.MessageMapper; // Added import
import com.adamasorho.mindapax_backend.model.Conversation; // Added import
import com.adamasorho.mindapax_backend.model.Message;
import com.adamasorho.mindapax_backend.model.User; // Added import
import com.adamasorho.mindapax_backend.repository.ConversationRepository; // Added import
import com.adamasorho.mindapax_backend.repository.MessageRepository;
import com.adamasorho.mindapax_backend.repository.UserRepository; // Added import
import com.adamasorho.mindapax_backend.service.MessageService;


@Service
public class MessageServiceImpl implements MessageService {
  private final MessageRepository messageRepository;
  private final ConversationRepository conversationRepository; // Added field
  private final UserRepository userRepository; // Added field
  private final MessageMapper messageMapper; // Added field

  public MessageServiceImpl(
      MessageRepository messageRepository,
      ConversationRepository conversationRepository,
      UserRepository userRepository,
      MessageMapper messageMapper) {
    this.messageRepository = messageRepository;
    this.conversationRepository = conversationRepository;
    this.userRepository = userRepository;
    this.messageMapper = messageMapper;
  }

  @Override
  public Message sendMessage(MessageDTO messageDto) { // Signature changed
    Message messageEntity = messageMapper.toEntity(messageDto);

    Conversation conversation = conversationRepository.findById(messageDto.getConversationId())
        .orElseThrow(() -> new EntityNotFoundException("Conversation not found with ID: " + messageDto.getConversationId()));
    messageEntity.setConversation(conversation);

    User sender = userRepository.findById(messageDto.getSenderId())
        .orElseThrow(() -> new EntityNotFoundException("Sender (User) not found with ID: " + messageDto.getSenderId()));
    messageEntity.setSender(sender);

    messageEntity.setTimestamp(LocalDateTime.now()); // Set timestamp
    // isRead is false by default for new messages, or handled by mapper if DTO carries it.

    return messageRepository.save(messageEntity);
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
