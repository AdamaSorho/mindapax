package com.adamasorho.mindapax_backend.dto.response;

import java.util.List;

import com.adamasorho.mindapax_backend.dto.response.assistant.GoalSuggestionDTO;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class AssistantChatResponse {
    private String reply;
    private List<GoalSuggestionDTO> suggestions;
}
