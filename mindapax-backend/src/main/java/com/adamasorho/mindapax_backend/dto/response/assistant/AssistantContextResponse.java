package com.adamasorho.mindapax_backend.dto.response.assistant;

import java.time.LocalDateTime;

import com.adamasorho.mindapax_backend.model.AssistantContext;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class AssistantContextResponse {
    private String preferencesJson;
    private String notes;
    private boolean completed;
    private LocalDateTime updatedAt;

    public static AssistantContextResponse fromEntity(AssistantContext ctx) {
        if (ctx == null) {
            return new AssistantContextResponse(null, null, false, null);
        }
        return new AssistantContextResponse(
                ctx.getPreferencesJson(),
                ctx.getNotes(),
                ctx.isCompleted(),
                ctx.getUpdatedAt());
    }
}
