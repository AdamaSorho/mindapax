package com.adamasorho.mindapax_backend.dto.request;

import com.adamasorho.mindapax_backend.model.enums.SelfGuidedDifficulty;
import com.adamasorho.mindapax_backend.model.enums.SelfGuidedDomain;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class SelfGuidedGoalUpdateRequest {
    private String title;
    private SelfGuidedDomain domain;
    private String outcome;
    private String action;
    private Integer targetPerWeek;
    private Integer minutesPerTask;
    private SelfGuidedDifficulty difficulty;
}
