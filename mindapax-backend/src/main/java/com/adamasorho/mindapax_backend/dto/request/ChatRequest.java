package com.adamasorho.mindapax_backend.dto.request;

import jakarta.validation.constraints.NotBlank;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class ChatRequest {
    @NotBlank(message = "Message is required")
    private String message;

    // If true, assistant may include suggested goals tailored to the user context
    private boolean requestRecommendations = true;

    // If false, do not include stored AssistantContext when crafting the reply
    private boolean useContext = true;

    public boolean isUseContext() {
        return useContext;
    }

    // If true, include recent progress (goals + sessions recap) as grounding context
    private boolean includeProgress = true;

    public boolean isIncludeProgress() {
        return includeProgress;
    }

    // Optional ad-hoc context additions (won't be saved). JSON or plain text.
    private String contextOverride;
}
