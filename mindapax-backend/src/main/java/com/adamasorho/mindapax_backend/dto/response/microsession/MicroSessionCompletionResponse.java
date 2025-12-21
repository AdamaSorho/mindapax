package com.adamasorho.mindapax_backend.dto.response.microsession;

import java.time.LocalDateTime;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class MicroSessionCompletionResponse {
    private Long microSessionId;
    private LocalDateTime completedAt;
    private Integer xpAwarded;
    private Long goalId;
}
