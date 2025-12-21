package com.adamasorho.mindapax_backend.service.impl;

import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.Optional;
import java.util.stream.Collectors;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import com.adamasorho.mindapax_backend.dto.request.MicroSessionRequest;
import com.adamasorho.mindapax_backend.dto.response.microsession.MicroSessionCompletionResponse;
import com.adamasorho.mindapax_backend.model.MicroSession;
import com.adamasorho.mindapax_backend.model.MicroSessionCompletion;
import com.adamasorho.mindapax_backend.model.SelfGuidedGoal;
import com.adamasorho.mindapax_backend.model.User;
import com.adamasorho.mindapax_backend.model.enums.SelfGuidedDomain;
import com.adamasorho.mindapax_backend.model.enums.SelfGuidedTaskStatus;
import com.adamasorho.mindapax_backend.repository.MicroSessionCompletionRepository;
import com.adamasorho.mindapax_backend.repository.MicroSessionRepository;
import com.adamasorho.mindapax_backend.repository.SelfGuidedGoalRepository;
import com.adamasorho.mindapax_backend.service.MicroSessionService;

import lombok.AllArgsConstructor;

@Service
@AllArgsConstructor
public class MicroSessionServiceImpl implements MicroSessionService {

    private final MicroSessionRepository repository;
    private final MicroSessionCompletionRepository completionRepository;
    private final SelfGuidedGoalRepository goalRepository;

    @Override
    @Transactional(readOnly = true)
    public List<MicroSession> list(Optional<SelfGuidedDomain> domain, Optional<String> outcome) {
        List<MicroSession> sessions = repository.findAll();
        if (domain.isPresent()) {
            sessions = sessions.stream()
                .filter(s -> s.getDomain() == domain.get())
                .collect(Collectors.toList());
        }
        if (outcome.isPresent()) {
            String target = outcome.get().toLowerCase(Locale.ROOT);
            sessions = sessions.stream()
                .filter(s -> s.getOutcomes() != null
                    && s.getOutcomes().stream()
                        .anyMatch(o -> o != null && o.toLowerCase(Locale.ROOT).equals(target)))
                .collect(Collectors.toList());
        }
        return sessions;
    }

    @Override
    @Transactional(readOnly = true)
    public MicroSession get(Long id) {
        return repository.findById(id)
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Micro session not found"));
    }

    @Override
    @Transactional
    public MicroSession create(MicroSessionRequest request) {
        validate(request);
        MicroSession session = new MicroSession();
        apply(session, request);
        return repository.save(session);
    }

    @Override
    @Transactional
    public MicroSession update(Long id, MicroSessionRequest request) {
        MicroSession session = get(id);
        if (request.getTitle() != null) session.setTitle(request.getTitle().trim());
        if (request.getDescription() != null) session.setDescription(request.getDescription().trim());
        if (request.getDomain() != null) session.setDomain(request.getDomain());
        if (request.getOutcomes() != null) session.setOutcomes(cleanList(request.getOutcomes()));
        if (request.getMinutes() != null) session.setMinutes(Math.max(1, request.getMinutes()));
        if (request.getSteps() != null) session.setSteps(cleanList(request.getSteps()));
        return repository.save(session);
    }

    @Override
    @Transactional
    public void delete(Long id) {
        MicroSession session = get(id);
        repository.delete(session);
    }

    @Override
    @Transactional
    public MicroSessionCompletionResponse complete(User user, Long id) {
        MicroSession session = get(id);
        MicroSessionCompletion completion = new MicroSessionCompletion();
        completion.setUser(user);
        completion.setMicroSession(session);
        completion.setCompletedAt(java.time.LocalDateTime.now());
        completionRepository.save(completion);

        SelfGuidedGoal goal = selectGoalForSession(user, session);
        int xpAwarded = 0;
        Long goalId = null;
        if (goal != null) {
            xpAwarded = 5;
            bumpGoalProgress(goal, SelfGuidedTaskStatus.DONE, xpAwarded);
            goalId = goal.getId();
        }
        return new MicroSessionCompletionResponse(
            session.getId(),
            completion.getCompletedAt(),
            xpAwarded == 0 ? null : xpAwarded,
            goalId
        );
    }

    private void apply(MicroSession session, MicroSessionRequest request) {
        session.setTitle(request.getTitle().trim());
        session.setDescription(request.getDescription().trim());
        session.setDomain(request.getDomain());
        session.setOutcomes(cleanList(request.getOutcomes()));
        session.setMinutes(Math.max(1, request.getMinutes()));
        session.setSteps(cleanList(request.getSteps()));
    }

    private void validate(MicroSessionRequest request) {
        if (request.getTitle() == null || request.getTitle().trim().isEmpty()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Title is required");
        }
        if (request.getDescription() == null || request.getDescription().trim().isEmpty()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Description is required");
        }
        if (request.getDomain() == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Domain is required");
        }
        if (request.getMinutes() == null || request.getMinutes() < 1) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Minutes is required");
        }
        if (request.getOutcomes() == null || request.getOutcomes().isEmpty()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Outcomes are required");
        }
        if (request.getSteps() == null || request.getSteps().isEmpty()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Steps are required");
        }
    }

    private List<String> cleanList(List<String> values) {
        if (values == null) return new ArrayList<>();
        return values.stream()
            .filter(v -> v != null && !v.trim().isEmpty())
            .map(String::trim)
            .collect(Collectors.toList());
    }

    private SelfGuidedGoal selectGoalForSession(User user, MicroSession session) {
        List<SelfGuidedGoal> goals = goalRepository.findByUser(user);
        if (goals.isEmpty()) return null;
        if (session.getOutcomes() != null && !session.getOutcomes().isEmpty()) {
            for (SelfGuidedGoal goal : goals) {
                if (goal.getOutcome() == null) continue;
                for (String outcome : session.getOutcomes()) {
                    if (outcome != null && outcome.equalsIgnoreCase(goal.getOutcome())) {
                        return goal;
                    }
                }
            }
        }
        for (SelfGuidedGoal goal : goals) {
            if (goal.getDomain() == session.getDomain()) {
                return goal;
            }
        }
        return goals.get(0);
    }

    private void bumpGoalProgress(SelfGuidedGoal goal, SelfGuidedTaskStatus status, int xpAwarded) {
        java.time.LocalDate today = java.time.LocalDate.now();
        java.time.LocalDate last = goal.getLastProgressDate();
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
        int delta = xpAwarded > 0 ? xpAwarded : (status == SelfGuidedTaskStatus.DONE ? 10 : 2);
        goal.setStreak(streak);
        goal.setLastProgressDate(today);
        goal.setXp(Math.min(Integer.MAX_VALUE, goal.getXp() + delta));
        goalRepository.save(goal);
    }
}
