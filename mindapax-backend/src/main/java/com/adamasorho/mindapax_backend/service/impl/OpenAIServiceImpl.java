package com.adamasorho.mindapax_backend.service.impl;

import java.util.List;

import org.springframework.ai.chat.messages.SystemMessage;
import org.springframework.ai.chat.messages.UserMessage;
import org.springframework.ai.chat.model.ChatResponse;
import org.springframework.ai.chat.prompt.Prompt;
import org.springframework.ai.openai.OpenAiChatModel;
import org.springframework.stereotype.Service;

import com.adamasorho.mindapax_backend.service.OpenAIService;

@Service
public class OpenAIServiceImpl implements OpenAIService {

    private final OpenAiChatModel chatModel;

    public OpenAIServiceImpl(OpenAiChatModel chatModel) {
        this.chatModel = chatModel;
    }

    @Override
    public String getCompletion(String message) {
        Prompt prompt = new Prompt(List.of(
                new SystemMessage("You are Mindapax, a helpful wellness assistant supporting users with financial, physical, and mental health questions."),
                new UserMessage(message)));
        ChatResponse response = chatModel.call(prompt);
        if (response == null || response.getResult() == null || response.getResult().getOutput() == null) {
            return "";
        }
        return response.getResult().getOutput().getContent();
    }
}

