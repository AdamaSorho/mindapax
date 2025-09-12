package com.adamasorho.mindapax_backend.repository;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

import com.adamasorho.mindapax_backend.model.AssistantContext;
import com.adamasorho.mindapax_backend.model.User;

public interface AssistantContextRepository extends JpaRepository<AssistantContext, Long> {
    Optional<AssistantContext> findByUser(User user);
}

