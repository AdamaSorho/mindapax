package com.adamasorho.mindapax_backend.repository;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

import com.adamasorho.mindapax_backend.model.AssistantPreferences;
import com.adamasorho.mindapax_backend.model.User;

public interface AssistantPreferencesRepository extends JpaRepository<AssistantPreferences, Long> {
    Optional<AssistantPreferences> findByUser(User user);
}

