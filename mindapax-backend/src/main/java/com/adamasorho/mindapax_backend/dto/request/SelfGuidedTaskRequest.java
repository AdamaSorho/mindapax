package com.adamasorho.mindapax_backend.dto.request;

import java.time.LocalDate;

import com.adamasorho.mindapax_backend.model.enums.SelfGuidedTaskStatus;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class SelfGuidedTaskRequest {
    private LocalDate date;
    private String title;
    private Integer minutes;
    private SelfGuidedTaskStatus status;
}
