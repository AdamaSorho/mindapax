package com.adamasorho.mindapax_backend.repository;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

import com.adamasorho.mindapax_backend.model.SelfGuidedGoal;
import com.adamasorho.mindapax_backend.model.User;

public interface SelfGuidedGoalRepository extends JpaRepository<SelfGuidedGoal, Long> {
    List<SelfGuidedGoal> findByUser(User user);
    Optional<SelfGuidedGoal> findByIdAndUser(Long id, User user);
}
