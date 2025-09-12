package com.adamasorho.mindapax_backend.dto.response.assistant;

import java.util.List;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class ProgressSnapshotDTO {
    private int activeGoals;
    private int completedGoals7d;
    private int suggestedGoals;
    private long sessionsLast7d;
    private String lastSessionAgo; // humanized, e.g., "2d 3h"
    private String nextSessionAt; // ISO string or empty
    private List<GoalBriefDTO> topActiveGoals;
}

