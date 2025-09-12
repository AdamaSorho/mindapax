package com.adamasorho.mindapax_backend.service.impl;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import org.springframework.ai.chat.messages.SystemMessage;
import org.springframework.ai.chat.messages.UserMessage;
import org.springframework.ai.chat.prompt.Prompt;
import org.springframework.ai.openai.OpenAiChatModel;
import org.springframework.stereotype.Service;

import com.adamasorho.mindapax_backend.dto.assistant.AssistantContextDTO;
import com.adamasorho.mindapax_backend.dto.assistant.AssistantPrefsDTO;
import com.adamasorho.mindapax_backend.dto.response.AssistantChatResponse;
import com.adamasorho.mindapax_backend.dto.response.assistant.GoalSuggestionDTO;
import com.adamasorho.mindapax_backend.model.AssistantContext;
import com.adamasorho.mindapax_backend.model.AssistantGoal;
import com.adamasorho.mindapax_backend.model.AssistantPreferences;
import com.adamasorho.mindapax_backend.model.AssistantGoal.Frequency;
import com.adamasorho.mindapax_backend.model.AssistantGoal.Status;
import com.adamasorho.mindapax_backend.model.User;
import com.adamasorho.mindapax_backend.repository.AssistantContextRepository;
import com.adamasorho.mindapax_backend.repository.AssistantGoalRepository;
import com.adamasorho.mindapax_backend.exception.BadRequestException;
import com.adamasorho.mindapax_backend.repository.SessionRepository;
import com.adamasorho.mindapax_backend.repository.AssistantPreferencesRepository;
import java.time.OffsetDateTime;
import java.time.Duration;
import java.time.LocalDateTime;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class AssistantServiceImpl implements com.adamasorho.mindapax_backend.service.AssistantService {

    private final OpenAiChatModel chatModel;
    private final AssistantContextRepository contextRepo;
    private final AssistantGoalRepository goalRepo;
    private final SessionRepository sessionRepo;
    private final AssistantPreferencesRepository prefsRepo;

    @Override
    public AssistantChatResponse chat(User user, String message, boolean requestRecommendations, boolean useContext, boolean includeProgress, String contextOverride) {
        AssistantContext ctx = useContext ? contextRepo.findByUser(user).orElse(null) : null;
        String contextStr = buildContextString(ctx, contextOverride);
        String rag = includeProgress ? buildRagContext(user) : "";
        String system = "You are Mindapax, a supportive wellbeing assistant."
                + " Personalize advice to the user's context when provided."
                + " Provide compassionate, practical guidance across mental, physical, and financial wellbeing."
                + (requestRecommendations ? " If appropriate, also propose up to 3 small, achievable goals tailored to the user. Return JSON as described." : "");

        String userMsg = "User context (if any):\n" + contextStr
                + (rag.isBlank() ? "" : "\n\nRecent progress recap:\n" + rag)
                + "\n\nUser says: " + message
                + (requestRecommendations
                        ? "\n\nReturn output in this JSON structure inside a fenced code block (```json):\n"
                                + "{\n  \"reply\": string,\n  \"goals\": [ { \"title\": string, \"frequency\": \"DAILY\"|\"WEEKLY\"|\"MONTHLY\" } ]\n}\n"
                        : "");

        Prompt prompt = new Prompt(List.of(new SystemMessage(system), new UserMessage(userMsg)));
        org.springframework.ai.chat.model.ChatResponse ai = chatModel.call(prompt);
        String text = (ai != null && ai.getResult() != null && ai.getResult().getOutput() != null)
                ? ai.getResult().getOutput().getText()
                : "";

        // Parse JSON from code fence if present; fall back to plain reply
        String json = extractJson(text);
        String reply = text;
        List<GoalSuggestionDTO> suggestions = new ArrayList<>();
        if (json != null) {
            Map<String, Object> parsed = JsonUtils.parseJson(json);
            Object r = parsed.get("reply");
            if (r instanceof String s) reply = s;
            Object goals = parsed.get("goals");
            if (goals instanceof List<?> list) {
                for (Object o : list) {
                    if (o instanceof Map<?, ?> m) {
                        String title = String.valueOf(m.get("title"));
                        String freqStr = String.valueOf(m.get("frequency"));
                        Frequency freq = toFrequency(freqStr);
                        if (title != null && !title.isBlank() && freq != null) {
                            suggestions.add(new GoalSuggestionDTO(title, freq));
                        }
                    }
                }
            }
        }

        // Persist suggestions as SUGGESTED (non-committal) so client can accept/activate later
        if (!suggestions.isEmpty()) {
            for (GoalSuggestionDTO s : suggestions) {
                AssistantGoal g = new AssistantGoal();
                g.setUser(user);
                g.setTitle(s.getTitle());
                g.setFrequency(s.getFrequency());
                g.setStatus(Status.SUGGESTED);
                goalRepo.save(g);
            }
        }

        return new AssistantChatResponse(reply, suggestions);
    }

    @Override
    public AssistantContext upsertContext(User user, AssistantContextDTO body) {
        AssistantContext ctx = contextRepo.findByUser(user).orElseGet(() -> {
            AssistantContext c = new AssistantContext();
            c.setUser(user);
            return c;
        });
        // Validate and normalize preferences JSON if provided
        String prefs = body.getPreferencesJson();
        boolean hasPrefs = prefs != null && !prefs.isBlank();
        if (hasPrefs) {
            ctx.setPreferencesJson(normalizePrefsJson(prefs));
        } else {
            ctx.setPreferencesJson(null);
        }
        String notes = body.getNotes();
        ctx.setNotes(notes);
        // Mark completed once any non-empty preferences or notes have been saved at least once
        if (!ctx.isCompleted() && (hasPrefs || (notes != null && !notes.isBlank()))) {
            ctx.setCompleted(true);
        }
        return contextRepo.save(ctx);
    }

    @Override
    public AssistantContext getContext(User user) {
        return contextRepo.findByUser(user).orElse(null);
    }

    private static final java.util.Set<String> REMINDER_ENUM = java.util.Set.of("DAILY", "WEEKLY", "MONTHLY");
    private static final java.util.Set<String> TONE_ENUM = java.util.Set.of("SUPPORTIVE", "COACHING", "CONCISE");

    private static String normalizePrefsJson(String raw) {
        try {
            com.fasterxml.jackson.databind.ObjectMapper om = new com.fasterxml.jackson.databind.ObjectMapper();
            @SuppressWarnings("unchecked")
            Map<String, Object> map = om.readValue(raw, Map.class);
            // Normalize specific enum-like fields when present
            Object r = map.get("reminders");
            if (r != null) {
                String v = r.toString().toUpperCase();
                if (!REMINDER_ENUM.contains(v)) {
                    throw new BadRequestException("Invalid reminders value: " + r);
                }
                map.put("reminders", v);
            }
            Object t = map.get("tone");
            if (t != null) {
                String v = t.toString().toUpperCase();
                if (!TONE_ENUM.contains(v)) {
                    throw new BadRequestException("Invalid tone value: " + t);
                }
                map.put("tone", v);
            }
            return om.writeValueAsString(map);
        } catch (BadRequestException e) {
            throw e;
        } catch (Exception e) {
            throw new BadRequestException("Invalid preferencesJson: " + e.getMessage());
        }
    }

    @Override
    public List<AssistantGoal> listGoals(User user) {
        return goalRepo.findByUserOrderByCreatedAtDesc(user);
    }

    @Override
    public AssistantGoal updateGoalStatus(User user, Long goalId, Status status) {
        AssistantGoal g = goalRepo.findById(goalId).orElseThrow();
        if (!g.getUser().getId().equals(user.getId())) {
            throw new RuntimeException("Not allowed");
        }
        g.setStatus(status);
        return goalRepo.save(g);
    }

    @Override
    public void acceptSuggestions(User user, List<GoalSuggestionDTO> suggestions) {
        for (GoalSuggestionDTO s : suggestions) {
            AssistantGoal g = new AssistantGoal();
            g.setUser(user);
            g.setTitle(s.getTitle());
            g.setFrequency(s.getFrequency());
            g.setStatus(Status.ACTIVE);
            goalRepo.save(g);
        }
    }

    @Override
    public com.adamasorho.mindapax_backend.dto.response.assistant.ProgressSnapshotDTO getProgress(User user) {
        try {
            var now = OffsetDateTime.now();
            List<AssistantGoal> goals = goalRepo.findByUserOrderByCreatedAtDesc(user);
            int active = (int) goals.stream().filter(g -> g.getStatus() == Status.ACTIVE).count();
            int suggested = (int) goals.stream().filter(g -> g.getStatus() == Status.SUGGESTED).count();
            int completed7d = (int) goals.stream()
                .filter(g -> g.getStatus() == Status.COMPLETED && g.getUpdatedAt() != null)
                .filter(g -> g.getUpdatedAt().isAfter(java.time.LocalDateTime.now().minusDays(7)))
                .count();
            long sessions7 = sessionRepo.countByUserIdAndStartTimeAfter(user.getId(), now.minusDays(7));
            var past = sessionRepo.findByUserIdAndStartTimeBefore(user.getId(), now, PageRequest.of(0, 1, Sort.by("startTime").descending()));
            String lastAgo = "";
            if (!past.isEmpty()) {
                var last = past.getContent().get(0);
                lastAgo = humanizeDuration(java.time.Duration.between(last.getStartTime(), now));
            }
            var upcoming = sessionRepo.findByUserIdAndStartTimeGreaterThanEqual(user.getId(), now, PageRequest.of(0, 1, Sort.by("startTime").ascending()));
            String nextAt = "";
            if (!upcoming.isEmpty()) {
                nextAt = upcoming.getContent().get(0).getStartTime().toString();
            }
            var top = new java.util.ArrayList<com.adamasorho.mindapax_backend.dto.response.assistant.GoalBriefDTO>();
            goals.stream().filter(g -> g.getStatus() == Status.ACTIVE).limit(3).forEach(g -> {
                top.add(new com.adamasorho.mindapax_backend.dto.response.assistant.GoalBriefDTO(g.getTitle(), g.getFrequency()));
            });
            return new com.adamasorho.mindapax_backend.dto.response.assistant.ProgressSnapshotDTO(active, completed7d, suggested, sessions7, lastAgo, nextAt, top);
        } catch (Exception e) {
            return new com.adamasorho.mindapax_backend.dto.response.assistant.ProgressSnapshotDTO(0, 0, 0, 0, "", "", java.util.List.of());
        }
    }

    @Override
    public AssistantPrefsDTO getPreferences(User user) {
        AssistantPreferences p = prefsRepo.findByUser(user).orElseGet(() -> {
            AssistantPreferences np = new AssistantPreferences();
            np.setUser(user);
            return prefsRepo.save(np);
        });
        return new AssistantPrefsDTO(p.isUseContext(), p.isIncludeProgress(), p.isSuggestGoals());
    }

    @Override
    public AssistantPrefsDTO upsertPreferences(User user, AssistantPrefsDTO prefs) {
        AssistantPreferences p = prefsRepo.findByUser(user).orElseGet(() -> {
            AssistantPreferences np = new AssistantPreferences();
            np.setUser(user);
            return np;
        });
        p.setUseContext(prefs.isUseContext());
        p.setIncludeProgress(prefs.isIncludeProgress());
        p.setSuggestGoals(prefs.isSuggestGoals());
        p = prefsRepo.save(p);
        return new AssistantPrefsDTO(p.isUseContext(), p.isIncludeProgress(), p.isSuggestGoals());
    }

    private static Frequency toFrequency(String s) {
        if (s == null) return null;
        try { return Frequency.valueOf(s.toUpperCase()); } catch (Exception e) { return null; }
    }

    private static String buildContextString(AssistantContext ctx, String override) {
        StringBuilder sb = new StringBuilder();
        if (ctx != null) {
            if (ctx.getPreferencesJson() != null && !ctx.getPreferencesJson().isBlank()) {
                sb.append("preferences: ").append(ctx.getPreferencesJson()).append('\n');
            }
            if (ctx.getNotes() != null && !ctx.getNotes().isBlank()) {
                sb.append("notes: ").append(ctx.getNotes()).append('\n');
            }
        }
        if (override != null && !override.isBlank()) {
            sb.append("override: ").append(override);
        }
        return sb.toString();
    }

    private String buildRagContext(User user) {
        try {
            StringBuilder sb = new StringBuilder();
            // Goals summary
            List<AssistantGoal> goals = goalRepo.findByUserOrderByCreatedAtDesc(user);
            long active = goals.stream().filter(g -> g.getStatus() == Status.ACTIVE).count();
            long suggested = goals.stream().filter(g -> g.getStatus() == Status.SUGGESTED).count();
            long completed = goals.stream().filter(g -> g.getStatus() == Status.COMPLETED).count();
            long completed7d = goals.stream()
                .filter(g -> g.getStatus() == Status.COMPLETED && g.getUpdatedAt() != null)
                .filter(g -> g.getUpdatedAt().isAfter(LocalDateTime.now().minusDays(7)))
                .count();
            if (!goals.isEmpty()) {
                sb.append("Goals → active:").append(active)
                  .append(", completed:").append(completed)
                  .append(" (last7d:").append(completed7d).append(")")
                  .append(", suggested:").append(suggested).append('\n');
                goals.stream().filter(g -> g.getStatus() == Status.ACTIVE).limit(3).forEach(g -> {
                    sb.append(" - [").append(g.getFrequency()).append("] ").append(g.getTitle()).append('\n');
                });
            }
            // Sessions summary
            var now = OffsetDateTime.now();
            long sessions7 = sessionRepo.countByUserIdAndStartTimeAfter(user.getId(), now.minusDays(7));
            var past = sessionRepo.findByUserIdAndStartTimeBefore(user.getId(), now, PageRequest.of(0, 3, Sort.by("startTime").descending()));
            if (!past.isEmpty()) {
                sb.append("Recent sessions:\n");
                past.getContent().forEach(s -> {
                    sb.append(" - ").append(s.getStartTime()).append(" • ")
                      .append(s.getMode()).append(" • ")
                      .append(s.getStatus()).append(" • ")
                      .append(s.getDurationMinutes()).append("m\n");
                });
                var last = past.getContent().get(0);
                Duration since = Duration.between(last.getStartTime(), now);
                String human = humanizeDuration(since);
                sb.append("Last session: ").append(human).append(" ago\n");
            }
            sb.append("Sessions last7d: ").append(sessions7).append('\n');
            var upcoming = sessionRepo.findByUserIdAndStartTimeGreaterThanEqual(user.getId(), now, PageRequest.of(0, 1, Sort.by("startTime").ascending()));
            if (!upcoming.isEmpty()) {
                var s = upcoming.getContent().get(0);
                sb.append("Next session: ").append(s.getStartTime()).append(" • ")
                  .append(s.getMode()).append(" • ")
                  .append(s.getStatus()).append("\n");
            }
            return sb.toString().trim();
        } catch (Exception e) {
            return "";
        }
    }

    private static String humanizeDuration(Duration d) {
        long days = d.toDays();
        long hours = d.minusDays(days).toHours();
        long minutes = d.minusDays(days).minusHours(hours).toMinutes();
        StringBuilder sb = new StringBuilder();
        if (days > 0) sb.append(days).append("d ");
        if (hours > 0) sb.append(hours).append("h ");
        if (days == 0 && minutes > 0) sb.append(minutes).append("m ");
        String s = sb.toString().trim();
        return s.isEmpty() ? "just now" : s;
    }

    private static String extractJson(String text) {
        if (text == null) return null;
        int fence = text.indexOf("```json");
        if (fence >= 0) {
            int start = fence + "```json".length();
            // skip immediate whitespace/newlines after the fence
            while (start < text.length()) {
                char c = text.charAt(start);
                if (c == '\n' || c == '\r' || Character.isWhitespace(c)) {
                    start++;
                } else {
                    break;
                }
            }
            int endFence = text.indexOf("```", start);
            if (endFence > start) {
                String candidate = text.substring(start, endFence).trim();
                int s = candidate.indexOf('{');
                int e = candidate.lastIndexOf('}');
                if (s >= 0 && e > s) {
                    return candidate.substring(s, e + 1);
                }
            }
        }
        // fallback: try to find first brace to last brace
        int s = text.indexOf('{');
        int e = text.lastIndexOf('}');
        if (s >= 0 && e > s) {
            return text.substring(s, e + 1);
        }
        return null;
    }
}

// Minimal JSON parse helper to avoid adding new dependencies
class JsonUtils {
    @SuppressWarnings("unchecked")
    public static Map<String, Object> parseJson(String json) {
        try {
            // Use Spring's Jackson via ObjectMapper if available on classpath
            com.fasterxml.jackson.databind.ObjectMapper mapper = new com.fasterxml.jackson.databind.ObjectMapper();
            return mapper.readValue(json, Map.class);
        } catch (Exception e) {
            return Map.of();
        }
    }
}
