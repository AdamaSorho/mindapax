package com.adamasorho.mindapax_backend.repository;

import java.util.Optional;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import com.adamasorho.mindapax_backend.model.Conversation; // Added import
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.adamasorho.mindapax_backend.model.Message;

@Repository
public interface MessageRepository extends JpaRepository<Message, Long> {

     Page<Message> findByConversationId(Long conversationId, Pageable pageable);

     Optional<Message> findTopByConversationIdOrderByTimestampDesc(Long conversationId);

     Optional<Message> findTopByConversationOrderByTimestampDesc(Conversation conversation); // Added method
}
