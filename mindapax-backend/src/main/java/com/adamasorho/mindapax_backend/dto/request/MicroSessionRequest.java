package com.adamasorho.mindapax_backend.dto.request;

import java.util.List;

import com.adamasorho.mindapax_backend.model.enums.SelfGuidedDomain;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class MicroSessionRequest {
    private String title;
    private String description;
    private SelfGuidedDomain domain;
    private List<String> outcomes;
    private Integer minutes;
    private List<String> steps;
}
