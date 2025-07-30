package com.adamasorho.mindapax_backend.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.lang.NonNull;
import org.springframework.messaging.simp.config.MessageBrokerRegistry;
import org.springframework.web.socket.config.annotation.EnableWebSocketMessageBroker;
import org.springframework.web.socket.config.annotation.StompEndpointRegistry;
import org.springframework.web.socket.config.annotation.WebSocketMessageBrokerConfigurer;

@Configuration
@EnableWebSocketMessageBroker
public class WebSocketConfig implements WebSocketMessageBrokerConfigurer {

    @Override
    public void configureMessageBroker(@NonNull MessageBrokerRegistry config) {
        config.enableSimpleBroker("/topic"); // clients will subscribe here
        config.setApplicationDestinationPrefixes("/app"); // client sends here
    }

    @Override
    public void registerStompEndpoints(@NonNull StompEndpointRegistry registry) {
        registry.addEndpoint("/ws")  // WebSocket endpoint
                .setAllowedOrigins("http://localhost:4200", "http://mindapax-frontend-bucket.s3-website-us-east-1.amazonaws.com")
                .withSockJS();       // fallback for browsers
    }
}

