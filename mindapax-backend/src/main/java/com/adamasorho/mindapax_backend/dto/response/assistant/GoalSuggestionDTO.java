package com.adamasorho.mindapax_backend.dto.response.assistant;

import com.adamasorho.mindapax_backend.model.AssistantGoal.Frequency;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class GoalSuggestionDTO {
    private String title;
    private Frequency frequency;
}

