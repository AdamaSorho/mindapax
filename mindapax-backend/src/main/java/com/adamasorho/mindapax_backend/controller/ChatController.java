package com.adamasorho.mindapax_backend.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.adamasorho.mindapax_backend.dto.request.ChatRequest;
import com.adamasorho.mindapax_backend.dto.response.ChatResponse;
import com.adamasorho.mindapax_backend.service.OpenAIService;

import jakarta.validation.Valid;
import lombok.AllArgsConstructor;

@RestController
@RequestMapping("/api/v1/assistant")
@AllArgsConstructor
public class ChatController {
    private final OpenAIService openAIService;

    @PostMapping
    public ResponseEntity<ChatResponse> chat(@RequestBody @Valid ChatRequest request) {
        String reply = openAIService.getCompletion(request.getMessage());
        return ResponseEntity.ok(new ChatResponse(reply));
    }
}

