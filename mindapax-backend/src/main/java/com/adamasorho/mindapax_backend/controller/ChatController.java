package com.adamasorho.mindapax_backend.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.bind.annotation.RequestParam;

import com.adamasorho.mindapax_backend.dto.request.ChatRequest;
import com.adamasorho.mindapax_backend.dto.response.AssistantChatResponse;
import com.adamasorho.mindapax_backend.dto.assistant.AssistantContextDTO;
import com.adamasorho.mindapax_backend.dto.assistant.AssistantPrefsDTO;
import com.adamasorho.mindapax_backend.dto.response.assistant.AssistantContextResponse;
import com.adamasorho.mindapax_backend.dto.response.assistant.GoalSuggestionDTO;
import com.adamasorho.mindapax_backend.dto.response.assistant.ContextStatusResponse;
import com.adamasorho.mindapax_backend.model.AssistantContext;
import com.adamasorho.mindapax_backend.model.AssistantGoal;
import com.adamasorho.mindapax_backend.model.User;
import com.adamasorho.mindapax_backend.security.CustomUserDetails;
import com.adamasorho.mindapax_backend.service.AssistantService;
import com.adamasorho.mindapax_backend.service.OpenAIService;

import jakarta.validation.Valid;
import lombok.AllArgsConstructor;

@RestController
@RequestMapping("/api/v1/assistant")
@AllArgsConstructor
public class ChatController {
    private final OpenAIService openAIService; // kept for compatibility or future use
    private final AssistantService assistantService;

    @PostMapping
    public ResponseEntity<AssistantChatResponse> chat(@RequestBody @Valid ChatRequest request) {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null || !(auth.getPrincipal() instanceof CustomUserDetails)) {
            return ResponseEntity.status(401).build();
        }
        User user = ((CustomUserDetails) auth.getPrincipal()).getUser();
        AssistantChatResponse resp = assistantService.chat(
            user,
            request.getMessage(),
            request.isRequestRecommendations(),
            request.isUseContext(),
            request.isIncludeProgress(),
            request.getContextOverride()
        );
        return ResponseEntity.ok(resp);
    }

    @PostMapping("/context")
    public ResponseEntity<AssistantContextResponse> upsertContext(@RequestBody AssistantContextDTO body) {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null || !(auth.getPrincipal() instanceof CustomUserDetails)) {
            return ResponseEntity.status(401).build();
        }
        User user = ((CustomUserDetails) auth.getPrincipal()).getUser();
        AssistantContext ctx = assistantService.upsertContext(user, body);
        return ResponseEntity.ok(AssistantContextResponse.fromEntity(ctx));
    }

    @GetMapping("/context")
    public ResponseEntity<AssistantContextResponse> getContext() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null || !(auth.getPrincipal() instanceof CustomUserDetails)) {
            return ResponseEntity.status(401).build();
        }
        User user = ((CustomUserDetails) auth.getPrincipal()).getUser();
        AssistantContext ctx = assistantService.getContext(user);
        return ResponseEntity.ok(AssistantContextResponse.fromEntity(ctx));
    }

    @GetMapping("/context/completed")
    public ResponseEntity<ContextStatusResponse> getContextCompleted() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null || !(auth.getPrincipal() instanceof CustomUserDetails)) {
            return ResponseEntity.status(401).build();
        }
        User user = ((CustomUserDetails) auth.getPrincipal()).getUser();
        AssistantContext ctx = assistantService.getContext(user);
        boolean completed = ctx != null && Boolean.TRUE.equals(ctx.isCompleted());
        return ResponseEntity.ok(new ContextStatusResponse(completed));
    }

    @GetMapping("/goals")
    public ResponseEntity<java.util.List<AssistantGoal>> listGoals() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null || !(auth.getPrincipal() instanceof CustomUserDetails)) {
            return ResponseEntity.status(401).build();
        }
        User user = ((CustomUserDetails) auth.getPrincipal()).getUser();
        return ResponseEntity.ok(assistantService.listGoals(user));
    }

    @PostMapping("/goals/{goalId}/status")
    public ResponseEntity<AssistantGoal> updateGoalStatus(@org.springframework.web.bind.annotation.PathVariable Long goalId,
            @RequestParam("status") AssistantGoal.Status status) {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null || !(auth.getPrincipal() instanceof CustomUserDetails)) {
            return ResponseEntity.status(401).build();
        }
        User user = ((CustomUserDetails) auth.getPrincipal()).getUser();
        AssistantGoal g = assistantService.updateGoalStatus(user, goalId, status);
        return ResponseEntity.ok(g);
    }

    @PostMapping("/goals/accept")
    public ResponseEntity<Void> acceptGoals(@RequestBody java.util.List<GoalSuggestionDTO> suggestions) {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null || !(auth.getPrincipal() instanceof CustomUserDetails)) {
            return ResponseEntity.status(401).build();
        }
        User user = ((CustomUserDetails) auth.getPrincipal()).getUser();
        assistantService.acceptSuggestions(user, suggestions);
        return ResponseEntity.ok().build();
    }

    @GetMapping("/prefs")
    public ResponseEntity<AssistantPrefsDTO> getPrefs() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null || !(auth.getPrincipal() instanceof CustomUserDetails)) {
            return ResponseEntity.status(401).build();
        }
        User user = ((CustomUserDetails) auth.getPrincipal()).getUser();
        return ResponseEntity.ok(assistantService.getPreferences(user));
    }

    @PostMapping("/prefs")
    public ResponseEntity<AssistantPrefsDTO> upsertPrefs(@RequestBody AssistantPrefsDTO body) {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null || !(auth.getPrincipal() instanceof CustomUserDetails)) {
            return ResponseEntity.status(401).build();
        }
        User user = ((CustomUserDetails) auth.getPrincipal()).getUser();
        return ResponseEntity.ok(assistantService.upsertPreferences(user, body));
    }

    @GetMapping("/progress")
    public ResponseEntity<com.adamasorho.mindapax_backend.dto.response.assistant.ProgressSnapshotDTO> getProgress() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null || !(auth.getPrincipal() instanceof CustomUserDetails)) {
            return ResponseEntity.status(401).build();
        }
        User user = ((CustomUserDetails) auth.getPrincipal()).getUser();
        return ResponseEntity.ok(assistantService.getProgress(user));
    }
}
