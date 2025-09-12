package com.adamasorho.mindapax_backend.service;

import java.util.List;

import com.adamasorho.mindapax_backend.dto.assistant.AssistantContextDTO;
import com.adamasorho.mindapax_backend.dto.assistant.AssistantPrefsDTO;
import com.adamasorho.mindapax_backend.dto.response.AssistantChatResponse;
import com.adamasorho.mindapax_backend.dto.response.assistant.GoalSuggestionDTO;
import com.adamasorho.mindapax_backend.model.AssistantContext;
import com.adamasorho.mindapax_backend.model.AssistantGoal;
import com.adamasorho.mindapax_backend.model.User;
import com.adamasorho.mindapax_backend.dto.response.assistant.ProgressSnapshotDTO;

public interface AssistantService {
    AssistantChatResponse chat(User user, String message, boolean requestRecommendations, boolean useContext, boolean includeProgress, String contextOverride);

    AssistantContext upsertContext(User user, AssistantContextDTO body);

    AssistantContext getContext(User user);

    List<AssistantGoal> listGoals(User user);

    AssistantGoal updateGoalStatus(User user, Long goalId, AssistantGoal.Status status);

    void acceptSuggestions(User user, List<GoalSuggestionDTO> suggestions);

    AssistantPrefsDTO getPreferences(User user);

    AssistantPrefsDTO upsertPreferences(User user, AssistantPrefsDTO prefs);

    ProgressSnapshotDTO getProgress(User user);
}
