package com.adamasorho.mindapax_backend.dto.response.selfguided;

import java.time.LocalDate;
import java.time.LocalDateTime;

import com.adamasorho.mindapax_backend.model.SelfGuidedTask;
import com.adamasorho.mindapax_backend.model.enums.SelfGuidedTaskStatus;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class SelfGuidedTaskResponse {
    private Long id;
    private Long goalId;
    private LocalDate date;
    private String title;
    private int minutes;
    private SelfGuidedTaskStatus status;
    private LocalDateTime completedAt;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    public static SelfGuidedTaskResponse fromEntity(SelfGuidedTask task) {
        if (task == null) return null;
        return new SelfGuidedTaskResponse(
            task.getId(),
            task.getGoal() != null ? task.getGoal().getId() : null,
            task.getDate(),
            task.getTitle(),
            task.getMinutes(),
            task.getStatus(),
            task.getCompletedAt(),
            task.getCreatedAt(),
            task.getUpdatedAt()
        );
    }
}
