package com.adamasorho.mindapax_backend.controller;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.adamasorho.mindapax_backend.dto.request.DailyCheckInRequest;
import com.adamasorho.mindapax_backend.dto.request.SelfGuidedGoalRequest;
import com.adamasorho.mindapax_backend.dto.request.SelfGuidedGoalUpdateRequest;
import com.adamasorho.mindapax_backend.dto.request.SelfGuidedTaskRequest;
import com.adamasorho.mindapax_backend.dto.request.SelfGuidedTaskUpdateRequest;
import com.adamasorho.mindapax_backend.dto.response.selfguided.DailyCheckInResponse;
import com.adamasorho.mindapax_backend.dto.response.selfguided.SelfGuidedGoalResponse;
import com.adamasorho.mindapax_backend.dto.response.selfguided.SelfGuidedTaskResponse;
import com.adamasorho.mindapax_backend.model.DailyCheckIn;
import com.adamasorho.mindapax_backend.model.SelfGuidedGoal;
import com.adamasorho.mindapax_backend.model.SelfGuidedTask;
import com.adamasorho.mindapax_backend.model.User;
import com.adamasorho.mindapax_backend.model.enums.SelfGuidedDomain;
import com.adamasorho.mindapax_backend.security.CustomUserDetails;
import com.adamasorho.mindapax_backend.service.SelfGuidedService;

import lombok.AllArgsConstructor;

@RestController
@RequestMapping("/api/v1/self-guided")
@AllArgsConstructor
public class SelfGuidedController {
    private final SelfGuidedService selfGuidedService;

    @GetMapping("/goals")
    public ResponseEntity<List<SelfGuidedGoalResponse>> listGoals(
            @RequestParam(required = false) SelfGuidedDomain domain,
            @RequestParam(required = false) String outcome) {
        User user = currentUser();
        List<SelfGuidedGoal> goals = selfGuidedService.listGoals(
            user,
            Optional.ofNullable(domain),
            Optional.ofNullable(outcome));
        return ResponseEntity.ok(goals.stream()
            .map(SelfGuidedGoalResponse::fromEntity)
            .collect(Collectors.toList()));
    }

    @PostMapping("/goals")
    public ResponseEntity<SelfGuidedGoalResponse> createGoal(@RequestBody SelfGuidedGoalRequest request) {
        User user = currentUser();
        SelfGuidedGoal goal = selfGuidedService.createGoal(user, request);
        return ResponseEntity.ok(SelfGuidedGoalResponse.fromEntity(goal));
    }

    @GetMapping("/goals/{id}")
    public ResponseEntity<SelfGuidedGoalResponse> getGoal(@PathVariable Long id) {
        User user = currentUser();
        return ResponseEntity.ok(SelfGuidedGoalResponse.fromEntity(selfGuidedService.getGoal(user, id)));
    }

    @PatchMapping("/goals/{id}")
    public ResponseEntity<SelfGuidedGoalResponse> updateGoal(
            @PathVariable Long id,
            @RequestBody SelfGuidedGoalUpdateRequest request) {
        User user = currentUser();
        SelfGuidedGoal goal = selfGuidedService.updateGoal(user, id, request);
        return ResponseEntity.ok(SelfGuidedGoalResponse.fromEntity(goal));
    }

    @DeleteMapping("/goals/{id}")
    public ResponseEntity<Void> deleteGoal(@PathVariable Long id) {
        User user = currentUser();
        selfGuidedService.deleteGoal(user, id);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/goals/{id}/tasks")
    public ResponseEntity<List<SelfGuidedTaskResponse>> listTasks(
            @PathVariable Long id,
            @RequestParam(required = false)
            @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate start,
            @RequestParam(required = false)
            @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate end) {
        User user = currentUser();
        List<SelfGuidedTask> tasks = selfGuidedService.listTasks(user, id, start, end);
        return ResponseEntity.ok(tasks.stream()
            .map(SelfGuidedTaskResponse::fromEntity)
            .collect(Collectors.toList()));
    }

    @PostMapping("/goals/{id}/tasks")
    public ResponseEntity<List<SelfGuidedTaskResponse>> addTasks(
            @PathVariable Long id,
            @RequestBody List<SelfGuidedTaskRequest> tasks) {
        User user = currentUser();
        List<SelfGuidedTask> created = selfGuidedService.addTasks(user, id, tasks);
        return ResponseEntity.ok(created.stream()
            .map(SelfGuidedTaskResponse::fromEntity)
            .collect(Collectors.toList()));
    }

    @PatchMapping("/tasks/{taskId}")
    public ResponseEntity<SelfGuidedTaskResponse> updateTask(
            @PathVariable Long taskId,
            @RequestBody SelfGuidedTaskUpdateRequest request) {
        User user = currentUser();
        SelfGuidedTask task = selfGuidedService.updateTask(user, taskId, request);
        return ResponseEntity.ok(SelfGuidedTaskResponse.fromEntity(task));
    }

    @PostMapping("/goals/{id}/tasks/reschedule-missed")
    public ResponseEntity<List<SelfGuidedTaskResponse>> rescheduleMissed(@PathVariable Long id) {
        User user = currentUser();
        List<SelfGuidedTask> updated = selfGuidedService.rescheduleMissed(user, id);
        return ResponseEntity.ok(updated.stream()
            .map(SelfGuidedTaskResponse::fromEntity)
            .collect(Collectors.toList()));
    }

    @GetMapping("/check-ins")
    public ResponseEntity<DailyCheckInResponse> getCheckIn(
            @RequestParam(required = false)
            @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        User user = currentUser();
        LocalDate target = date != null ? date : LocalDate.now();
        DailyCheckIn entry = selfGuidedService.getCheckIn(user, target);
        if (entry == null) {
            return ResponseEntity.noContent().build();
        }
        return ResponseEntity.ok(DailyCheckInResponse.fromEntity(entry));
    }

    @PutMapping("/check-ins/{date}")
    public ResponseEntity<DailyCheckInResponse> upsertCheckIn(
            @PathVariable @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date,
            @RequestBody DailyCheckInRequest request) {
        User user = currentUser();
        DailyCheckIn entry = selfGuidedService.upsertCheckIn(user, date, request);
        return ResponseEntity.ok(DailyCheckInResponse.fromEntity(entry));
    }

    private User currentUser() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null || !(auth.getPrincipal() instanceof CustomUserDetails)) {
            throw new org.springframework.web.server.ResponseStatusException(
                org.springframework.http.HttpStatus.UNAUTHORIZED, "User not authenticated");
        }
        return ((CustomUserDetails) auth.getPrincipal()).getUser();
    }
}
