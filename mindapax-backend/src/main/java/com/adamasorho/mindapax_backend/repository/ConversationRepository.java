package com.adamasorho.mindapax_backend.repository;

import java.util.Optional;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.adamasorho.mindapax_backend.model.Conversation;

@Repository
public interface ConversationRepository extends JpaRepository<Conversation, Long> {
  Optional<Conversation> findByUserIdAndProfessionalId(Long userId, Long professionalId);
  Page<Conversation> findByUserIdOrProfessionalId(Long userId, Long professionalId, Pageable pageable);
}
