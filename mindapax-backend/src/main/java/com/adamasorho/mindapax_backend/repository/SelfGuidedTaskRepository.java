package com.adamasorho.mindapax_backend.repository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

import com.adamasorho.mindapax_backend.model.SelfGuidedGoal;
import com.adamasorho.mindapax_backend.model.SelfGuidedTask;
import com.adamasorho.mindapax_backend.model.User;

public interface SelfGuidedTaskRepository extends JpaRepository<SelfGuidedTask, Long> {
    List<SelfGuidedTask> findByGoal(SelfGuidedGoal goal);
    List<SelfGuidedTask> findByGoalAndDateBetween(SelfGuidedGoal goal, LocalDate start, LocalDate end);
    Optional<SelfGuidedTask> findByIdAndGoal_User(Long id, User user);
}
