package com.adamasorho.mindapax_backend.dto.assistant;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class AssistantPrefsDTO {
    private boolean useContext = true;
    private boolean includeProgress = true;
    private boolean suggestGoals = true;
}

