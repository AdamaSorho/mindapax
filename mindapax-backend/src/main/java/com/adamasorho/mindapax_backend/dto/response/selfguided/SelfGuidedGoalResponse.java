package com.adamasorho.mindapax_backend.dto.response.selfguided;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

import com.adamasorho.mindapax_backend.model.SelfGuidedGoal;
import com.adamasorho.mindapax_backend.model.enums.SelfGuidedDifficulty;
import com.adamasorho.mindapax_backend.model.enums.SelfGuidedDomain;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class SelfGuidedGoalResponse {
    private Long id;
    private String title;
    private SelfGuidedDomain domain;
    private String outcome;
    private String action;
    private int targetPerWeek;
    private int minutesPerTask;
    private SelfGuidedDifficulty difficulty;
    private int xp;
    private int streak;
    private LocalDate lastProgressDate;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
    private List<SelfGuidedTaskResponse> tasks;

    public static SelfGuidedGoalResponse fromEntity(SelfGuidedGoal goal) {
        if (goal == null) return null;
        return new SelfGuidedGoalResponse(
            goal.getId(),
            goal.getTitle(),
            goal.getDomain(),
            goal.getOutcome(),
            goal.getAction(),
            goal.getTargetPerWeek(),
            goal.getMinutesPerTask(),
            goal.getDifficulty(),
            goal.getXp(),
            goal.getStreak(),
            goal.getLastProgressDate(),
            goal.getCreatedAt(),
            goal.getUpdatedAt(),
            goal.getTasks() == null ? java.util.List.of() :
                goal.getTasks().stream()
                    .map(SelfGuidedTaskResponse::fromEntity)
                    .collect(Collectors.toList())
        );
    }
}
