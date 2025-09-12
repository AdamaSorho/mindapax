package com.adamasorho.mindapax_backend.dto.assistant;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class AssistantContextDTO {
    private String preferencesJson;
    private String notes;
}

