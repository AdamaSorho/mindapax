package com.adamasorho.mindapax_backend.service.impl;

import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.Set;
import java.util.stream.Collectors;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

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
import com.adamasorho.mindapax_backend.model.enums.SelfGuidedTaskStatus;
import com.adamasorho.mindapax_backend.repository.DailyCheckInRepository;
import com.adamasorho.mindapax_backend.repository.SelfGuidedGoalRepository;
import com.adamasorho.mindapax_backend.repository.SelfGuidedTaskRepository;
import com.adamasorho.mindapax_backend.service.SelfGuidedService;

import lombok.AllArgsConstructor;

@Service
@AllArgsConstructor
public class SelfGuidedServiceImpl implements SelfGuidedService {

    private final SelfGuidedGoalRepository goalRepository;
    private final SelfGuidedTaskRepository taskRepository;
    private final DailyCheckInRepository checkInRepository;

    @Override
    @Transactional
    public List<SelfGuidedGoal> listGoals(User user, Optional<SelfGuidedDomain> domain, Optional<String> outcome) {
        List<SelfGuidedGoal> goals = goalRepository.findByUser(user);
        if (domain.isPresent()) {
            goals = goals.stream()
                .filter(g -> g.getDomain() == domain.get())
                .collect(Collectors.toList());
        }
        if (outcome.isPresent()) {
            String target = outcome.get();
            goals = goals.stream()
                .filter(g -> target.equalsIgnoreCase(g.getOutcome()))
                .collect(Collectors.toList());
        }
        LocalDate now = LocalDate.now();
        for (SelfGuidedGoal goal : goals) {
            ensureWeekPlan(goal, now);
        }
        return goals;
    }

    @Override
    @Transactional(readOnly = true)
    public SelfGuidedGoal getGoal(User user, Long id) {
        return goalRepository.findByIdAndUser(id, user)
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Goal not found"));
    }

    @Override
    @Transactional
    public SelfGuidedGoal createGoal(User user, SelfGuidedGoalRequest request) {
        validateGoalRequest(request);
        SelfGuidedGoal goal = new SelfGuidedGoal();
        goal.setUser(user);
        goal.setTitle(request.getTitle().trim());
        goal.setDomain(request.getDomain());
        goal.setOutcome(trimToNull(request.getOutcome()));
        goal.setAction(request.getAction().trim());
        goal.setTargetPerWeek(clampInt(request.getTargetPerWeek(), 1, 7));
        goal.setMinutesPerTask(Math.max(1, request.getMinutesPerTask()));
        goal.setDifficulty(request.getDifficulty());
        goal.setXp(0);
        goal.setStreak(0);
        goal = goalRepository.save(goal);
        ensureWeekPlan(goal, LocalDate.now());
        return goal;
    }

    @Override
    @Transactional
    public SelfGuidedGoal updateGoal(User user, Long id, SelfGuidedGoalUpdateRequest request) {
        SelfGuidedGoal goal = getGoal(user, id);
        if (request.getTitle() != null) {
            goal.setTitle(request.getTitle().trim());
        }
        if (request.getDomain() != null) {
            goal.setDomain(request.getDomain());
        }
        if (request.getOutcome() != null) {
            goal.setOutcome(trimToNull(request.getOutcome()));
        }
        if (request.getAction() != null) {
            goal.setAction(request.getAction().trim());
        }
        if (request.getTargetPerWeek() != null) {
            goal.setTargetPerWeek(clampInt(request.getTargetPerWeek(), 1, 7));
        }
        if (request.getMinutesPerTask() != null) {
            goal.setMinutesPerTask(Math.max(1, request.getMinutesPerTask()));
        }
        if (request.getDifficulty() != null) {
            goal.setDifficulty(request.getDifficulty());
        }
        ensureWeekPlan(goal, LocalDate.now());
        return goalRepository.save(goal);
    }

    @Override
    @Transactional
    public void deleteGoal(User user, Long id) {
        SelfGuidedGoal goal = getGoal(user, id);
        goalRepository.delete(goal);
    }

    @Override
    @Transactional(readOnly = true)
    public List<SelfGuidedTask> listTasks(User user, Long goalId, LocalDate start, LocalDate end) {
        SelfGuidedGoal goal = getGoal(user, goalId);
        if (start != null && end != null) {
            return taskRepository.findByGoalAndDateBetween(goal, start, end);
        }
        return taskRepository.findByGoal(goal);
    }

    @Override
    @Transactional
    public List<SelfGuidedTask> addTasks(User user, Long goalId, List<SelfGuidedTaskRequest> tasks) {
        if (tasks == null || tasks.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Tasks are required");
        }
        SelfGuidedGoal goal = getGoal(user, goalId);
        List<SelfGuidedTask> created = new ArrayList<>();
        for (SelfGuidedTaskRequest req : tasks) {
            if (req.getDate() == null || req.getTitle() == null || req.getTitle().trim().isEmpty()) {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Task date and title are required");
            }
            int minutes = req.getMinutes() == null ? goal.getMinutesPerTask() : Math.max(1, req.getMinutes());
            SelfGuidedTask task = new SelfGuidedTask();
            task.setGoal(goal);
            task.setDate(req.getDate());
            task.setTitle(req.getTitle().trim());
            task.setMinutes(minutes);
            task.setStatus(req.getStatus() == null ? SelfGuidedTaskStatus.PENDING : req.getStatus());
            created.add(task);
        }
        goal.getTasks().addAll(created);
        goalRepository.save(goal);
        return created;
    }

    @Override
    @Transactional
    public SelfGuidedTask updateTask(User user, Long taskId, SelfGuidedTaskUpdateRequest request) {
        SelfGuidedTask task = taskRepository.findByIdAndGoal_User(taskId, user)
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Task not found"));
        SelfGuidedTaskStatus prevStatus = task.getStatus();
        if (request.getDate() != null) {
            task.setDate(request.getDate());
        }
        if (request.getTitle() != null && !request.getTitle().trim().isEmpty()) {
            task.setTitle(request.getTitle().trim());
        }
        if (request.getMinutes() != null) {
            task.setMinutes(Math.max(1, request.getMinutes()));
        }
        if (request.getStatus() != null) {
            task.setStatus(request.getStatus());
            if (request.getStatus() == SelfGuidedTaskStatus.DONE
                || request.getStatus() == SelfGuidedTaskStatus.SOFT_SKIPPED) {
                task.setCompletedAt(java.time.LocalDateTime.now());
            } else {
                task.setCompletedAt(null);
            }
        }
        SelfGuidedTask saved = taskRepository.save(task);
        if (request.getStatus() != null
            && !isCompletion(prevStatus)
            && isCompletion(request.getStatus())) {
            bumpProgress(saved.getGoal(), request.getStatus());
        }
        return saved;
    }

    @Override
    @Transactional
    public List<SelfGuidedTask> rescheduleMissed(User user, Long goalId) {
        SelfGuidedGoal goal = getGoal(user, goalId);
        LocalDate today = LocalDate.now();
        LocalDate weekStart = monday(today);
        LocalDate weekEnd = weekStart.plusDays(6);
        List<SelfGuidedTask> pendingPast = goal.getTasks().stream()
            .filter(t -> t.getStatus() == SelfGuidedTaskStatus.PENDING)
            .filter(t -> t.getDate().isBefore(today))
            .collect(Collectors.toList());
        if (pendingPast.isEmpty()) {
            return List.of();
        }
        Set<LocalDate> busyDays = goal.getTasks().stream()
            .filter(t -> t.getStatus() == SelfGuidedTaskStatus.PENDING
                || t.getStatus() == SelfGuidedTaskStatus.DONE
                || t.getStatus() == SelfGuidedTaskStatus.SOFT_SKIPPED)
            .map(SelfGuidedTask::getDate)
            .collect(Collectors.toSet());

        for (SelfGuidedTask task : pendingPast) {
            LocalDate target = today;
            while (busyDays.contains(target) && !target.isAfter(weekEnd)) {
                target = target.plusDays(1);
            }
            if (target.isAfter(weekEnd)) {
                int daysUntilNextWeek = (7 - today.getDayOfWeek().getValue());
                target = today.plusDays(daysUntilNextWeek + (task.getDate().getDayOfWeek().getValue() - 1));
            }
            task.setDate(target);
            busyDays.add(target);
        }
        return taskRepository.saveAll(pendingPast);
    }

    @Override
    @Transactional(readOnly = true)
    public DailyCheckIn getCheckIn(User user, LocalDate date) {
        return checkInRepository.findByUserAndDate(user, date).orElse(null);
    }

    @Override
    @Transactional
    public DailyCheckIn upsertCheckIn(User user, LocalDate date, DailyCheckInRequest request) {
        if (request.getMood() == null || request.getEffort() == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Mood and effort are required");
        }
        DailyCheckIn entry = checkInRepository.findByUserAndDate(user, date).orElseGet(DailyCheckIn::new);
        entry.setUser(user);
        entry.setDate(date);
        entry.setMood(request.getMood());
        entry.setEffort(request.getEffort());
        entry.setNote(trimToNull(request.getNote()));
        return checkInRepository.save(entry);
    }

    private void validateGoalRequest(SelfGuidedGoalRequest request) {
        if (request.getTitle() == null || request.getTitle().trim().isEmpty()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Title is required");
        }
        if (request.getDomain() == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Domain is required");
        }
        if (request.getAction() == null || request.getAction().trim().isEmpty()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Action is required");
        }
        if (request.getTargetPerWeek() == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Target per week is required");
        }
        if (request.getMinutesPerTask() == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Minutes per task is required");
        }
        if (request.getDifficulty() == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Difficulty is required");
        }
    }

    private void ensureWeekPlan(SelfGuidedGoal goal, LocalDate now) {
        LocalDate start = monday(now);
        LocalDate end = start.plusDays(6);
        List<SelfGuidedTask> weekTasks = goal.getTasks().stream()
            .filter(t -> !t.getDate().isBefore(start) && !t.getDate().isAfter(end))
            .collect(Collectors.toList());
        if (weekTasks.size() >= goal.getTargetPerWeek()) return;

        int needed = goal.getTargetPerWeek() - weekTasks.size();
        Set<LocalDate> existingDays = weekTasks.stream()
            .map(SelfGuidedTask::getDate)
            .collect(Collectors.toSet());
        List<Integer> offsets = dayOffsetsFor(goal.getTargetPerWeek());
        for (int offset : offsets) {
            LocalDate date = start.plusDays(offset);
            if (existingDays.contains(date)) continue;
            SelfGuidedTask task = new SelfGuidedTask();
            task.setGoal(goal);
            task.setDate(date);
            task.setTitle(goal.getAction());
            task.setMinutes(goal.getMinutesPerTask());
            task.setStatus(SelfGuidedTaskStatus.PENDING);
            goal.getTasks().add(task);
            existingDays.add(date);
            needed -= 1;
            if (needed == 0) break;
        }
        goalRepository.save(goal);
    }

    private List<Integer> dayOffsetsFor(int targetPerWeek) {
        int capped = clampInt(targetPerWeek, 1, 7);
        switch (capped) {
            case 1:
                return List.of(0);
            case 2:
                return List.of(0, 3);
            case 3:
                return List.of(0, 2, 4);
            case 4:
                return List.of(0, 1, 3, 5);
            case 5:
                return List.of(0, 1, 2, 3, 4);
            case 6:
                return List.of(0, 1, 2, 3, 4, 5);
            case 7:
            default:
                return List.of(0, 1, 2, 3, 4, 5, 6);
        }
    }

    private LocalDate monday(LocalDate date) {
        int delta = date.getDayOfWeek().getValue() - 1;
        return date.minusDays(delta);
    }

    private boolean isCompletion(SelfGuidedTaskStatus status) {
        return status == SelfGuidedTaskStatus.DONE || status == SelfGuidedTaskStatus.SOFT_SKIPPED;
    }

    private void bumpProgress(SelfGuidedGoal goal, SelfGuidedTaskStatus status) {
        LocalDate today = LocalDate.now();
        LocalDate last = goal.getLastProgressDate();
        int streak = goal.getStreak();
        if (last == null) {
            streak = 1;
        } else if (last.isEqual(today)) {
            streak = Math.max(streak, 1);
        } else if (last.isEqual(today.minusDays(1))) {
            streak += 1;
        } else {
            streak = 1;
        }
        int delta = status == SelfGuidedTaskStatus.DONE ? 10 : 2;
        goal.setStreak(streak);
        goal.setLastProgressDate(today);
        goal.setXp(Math.min(Integer.MAX_VALUE, goal.getXp() + delta));
        goalRepository.save(goal);
    }

    private int clampInt(int value, int min, int max) {
        return Math.max(min, Math.min(max, value));
    }

    private String trimToNull(String value) {
        if (value == null) return null;
        String trimmed = value.trim();
        return trimmed.isEmpty() ? null : trimmed;
    }
}
