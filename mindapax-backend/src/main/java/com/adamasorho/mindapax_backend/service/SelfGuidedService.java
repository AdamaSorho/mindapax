package com.adamasorho.mindapax_backend.service;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

import com.adamasorho.mindapax_backend.dto.request.DailyCheckInRequest;
import com.adamasorho.mindapax_backend.dto.request.SelfGuidedGoalRequest;
import com.adamasorho.mindapax_backend.dto.request.SelfGuidedGoalUpdateRequest;
import com.adamasorho.mindapax_backend.dto.request.SelfGuidedTaskRequest;
import com.adamasorho.mindapax_backend.dto.request.SelfGuidedTaskUpdateRequest;
import com.adamasorho.mindapax_backend.model.DailyCheckIn;
import com.adamasorho.mindapax_backend.model.SelfGuidedGoal;
import com.adamasorho.mindapax_backend.model.SelfGuidedTask;
import com.adamasorho.mindapax_backend.model.User;
import com.adamasorho.mindapax_backend.model.enums.SelfGuidedDomain;

public interface SelfGuidedService {
    List<SelfGuidedGoal> listGoals(User user, Optional<SelfGuidedDomain> domain, Optional<String> outcome);
    SelfGuidedGoal getGoal(User user, Long id);
    SelfGuidedGoal createGoal(User user, SelfGuidedGoalRequest request);
    SelfGuidedGoal updateGoal(User user, Long id, SelfGuidedGoalUpdateRequest request);
    void deleteGoal(User user, Long id);

    List<SelfGuidedTask> listTasks(User user, Long goalId, LocalDate start, LocalDate end);
    List<SelfGuidedTask> addTasks(User user, Long goalId, List<SelfGuidedTaskRequest> tasks);
    SelfGuidedTask updateTask(User user, Long taskId, SelfGuidedTaskUpdateRequest request);
    List<SelfGuidedTask> rescheduleMissed(User user, Long goalId);

    DailyCheckIn getCheckIn(User user, LocalDate date);
    DailyCheckIn upsertCheckIn(User user, LocalDate date, DailyCheckInRequest request);
}
