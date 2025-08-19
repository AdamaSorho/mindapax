package com.adamasorho.mindapax_backend.service.impl;

import java.util.List;
import java.util.Map;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.client.WebClient;

import com.adamasorho.mindapax_backend.service.OpenAIService;
import com.fasterxml.jackson.databind.JsonNode;

@Service
public class OpenAIServiceImpl implements OpenAIService {

    private final WebClient webClient;

    @Value("${openai.api-key}")
    private String apiKey;

    @Value("${openai.model:gpt-4o-mini}")
    private String model;

    public OpenAIServiceImpl(WebClient.Builder builder) {
        this.webClient = builder.baseUrl("https://api.openai.com/v1").build();
    }

    @Override
    public String getCompletion(String message) {
        Map<String, Object> body = Map.of(
                "model", model,
                "messages", List.of(
                        Map.of("role", "system", "content",
                                "You are Mindapax, a helpful wellness assistant supporting users with financial, physical, and mental health questions."),
                        Map.of("role", "user", "content", message)));

        JsonNode response = webClient.post()
                .uri("/chat/completions")
                .header("Authorization", "Bearer " + apiKey)
                .bodyValue(body)
                .retrieve()
                .bodyToMono(JsonNode.class)
                .block();

        if (response == null || !response.has("choices")) {
            return "";
        }

        return response.path("choices").get(0).path("message").path("content").asText("");
    }
}

