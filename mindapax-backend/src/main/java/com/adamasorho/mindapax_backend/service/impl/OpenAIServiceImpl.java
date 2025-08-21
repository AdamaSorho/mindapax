package com.adamasorho.mindapax_backend.service.impl;

import java.util.Arrays;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import com.adamasorho.mindapax_backend.service.OpenAIService;
import com.unfbx.chatgpt.OpenAiClient;
import com.unfbx.chatgpt.entity.chat.ChatCompletion;
import com.unfbx.chatgpt.entity.chat.ChatCompletionResponse;
import com.unfbx.chatgpt.entity.chat.Message;

@Service
public class OpenAIServiceImpl implements OpenAIService {

    private final OpenAiClient openAiClient;

    @Value("${openai.model:gpt-4o-mini}")
    private String model;

    public OpenAIServiceImpl(OpenAiClient openAiClient) {
        this.openAiClient = openAiClient;
    }

    @Override
    public String getCompletion(String message) {
        ChatCompletion request = ChatCompletion.builder()
                .model(model)
                .messages(Arrays.asList(
                        Message.builder()
                                .role(Message.Role.SYSTEM)
                                .content(
                                        "You are Mindapax, a helpful wellness assistant supporting users with financial, physical, and mental health questions.")
                                .build(),
                        Message.builder().role(Message.Role.USER).content(message).build()))
                .build();

        ChatCompletionResponse response = openAiClient.chatCompletion(request);
        if (response == null || response.getChoices() == null || response.getChoices().isEmpty()) {
            return "";
        }
        return response.getChoices().get(0).getMessage().getContent();
    }
}

