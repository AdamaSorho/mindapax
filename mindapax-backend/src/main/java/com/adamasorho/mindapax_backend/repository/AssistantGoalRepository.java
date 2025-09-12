package com.adamasorho.mindapax_backend.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;

import com.adamasorho.mindapax_backend.model.AssistantGoal;
import com.adamasorho.mindapax_backend.model.User;

public interface AssistantGoalRepository extends JpaRepository<AssistantGoal, Long> {
    List<AssistantGoal> findByUserOrderByCreatedAtDesc(User user);
}

