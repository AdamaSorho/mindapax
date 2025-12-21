package com.adamasorho.mindapax_backend.dto.response.microsession;

import java.time.LocalDateTime;
import java.util.List;

import com.adamasorho.mindapax_backend.model.MicroSession;
import com.adamasorho.mindapax_backend.model.enums.SelfGuidedDomain;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class MicroSessionResponse {
    private Long id;
    private String title;
    private String description;
    private SelfGuidedDomain domain;
    private List<String> outcomes;
    private int minutes;
    private List<String> steps;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    public static MicroSessionResponse fromEntity(MicroSession session) {
        if (session == null) return null;
        return new MicroSessionResponse(
            session.getId(),
            session.getTitle(),
            session.getDescription(),
            session.getDomain(),
            session.getOutcomes(),
            session.getMinutes(),
            session.getSteps(),
            session.getCreatedAt(),
            session.getUpdatedAt()
        );
    }
}
