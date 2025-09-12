package com.adamasorho.mindapax_backend.dto.response.assistant;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class ContextStatusResponse {
    private boolean completed;
}

