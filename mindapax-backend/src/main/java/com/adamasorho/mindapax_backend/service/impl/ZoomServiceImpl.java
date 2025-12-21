package com.adamasorho.mindapax_backend.service.impl;

import com.adamasorho.mindapax_backend.service.ZoomMeetingDetails;
import com.adamasorho.mindapax_backend.service.ZoomService;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.SignatureAlgorithm;
import lombok.extern.slf4j.Slf4j;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.web.reactive.function.BodyInserters;
import org.springframework.web.reactive.function.client.WebClient;
import reactor.core.publisher.Mono;
import java.util.Base64;
import java.util.Map;

import javax.crypto.spec.SecretKeySpec;

// import com.fasterxml.jackson.databind.ObjectMapper; // Not directly used, but good for general JSON work
import com.fasterxml.jackson.annotation.JsonProperty;

import java.nio.charset.StandardCharsets;
import java.util.Date;
import java.util.HashMap;

@Service
@Slf4j
public class ZoomServiceImpl implements ZoomService {


    @Value("${zoom.sdk_key}")
    private String zoomSdkKey;

    @Value("${zoom.sdk_secret}")
    private String zoomSdkSecret;

    @Value("${zoom.api.account-id}")
    private String zoomApiAccountId;

    @Value("${zoom.api.client-id}")
    private String zoomApiClientId;

    @Value("${zoom.api.client-secret}")
    private String zoomApiClientSecret;

    private final WebClient webClient;

    public ZoomServiceImpl(WebClient.Builder webClientBuilder) {
        this.webClient = webClientBuilder.baseUrl("https://api.zoom.us/v2").build();
    }

    @Override
    public String getSdkKey() {
        return zoomSdkKey;
    }

    @Override
    public String generateSignature(String meetingNumber, int role) {
        try {
            long timestamp = new Date().getTime() / 1000 - 30;
            long expiryTimestamp = timestamp + 7200;

            SecretKeySpec secretKeySpec = new SecretKeySpec(zoomSdkSecret.getBytes(StandardCharsets.UTF_8), SignatureAlgorithm.HS256.getJcaName());
            Map<String, Object> oHeader = new HashMap<>();
            oHeader.put("alg", SignatureAlgorithm.HS256);
            oHeader.put("typ", "JWT");

            String payload = Jwts.builder()
                .setHeaderParams(oHeader)
                .claim("appKey", zoomSdkKey)
                .claim("sdkKey", zoomSdkKey)
                .claim("mn", meetingNumber)
                .claim("role", role)
                .claim("iat", timestamp)
                .claim("exp", expiryTimestamp)
                .claim("tokenExp", expiryTimestamp)
                .signWith(secretKeySpec)
                .compact();

            return payload;

        } catch (Exception e) {
            log.error("Error generating Zoom signature for meeting {}: {}", meetingNumber, e.getMessage(), e);
            throw new RuntimeException("Error generating Zoom signature", e);
        }
    }

    @Override
    public ZoomMeetingDetails createPermanentMeetingForProfessional(String professionalName, String password) {
        log.info("Attempting to create a permanent Zoom meeting for professional: {}", professionalName);

        String accessToken = getS2SAccessToken().block();
        if (accessToken == null) {
            log.error("Failed to obtain Zoom S2S access token for professional: {}", professionalName);
            throw new RuntimeException("Failed to obtain Zoom S2S access token.");
        }
        log.debug("Successfully obtained Zoom S2S access token for professional: {}.", professionalName);

        String userId = "me";

        ZoomMeetingRequest requestBody = new ZoomMeetingRequest();
        requestBody.setTopic("Consultation Room for " + professionalName);
        requestBody.setType(2); // Scheduled meeting
        requestBody.setPassword(password);
        ZoomMeetingSettings settings = new ZoomMeetingSettings();
        settings.setJoinBeforeHost(true);
        settings.setWaitingRoom(true);
        settings.setMeetingAuthentication(false);
        requestBody.setSettings(settings);

        try {
            ZoomMeetingResponse response = this.webClient.post()
                .uri("/users/" + userId + "/meetings")
                .header(HttpHeaders.AUTHORIZATION, "Bearer " + accessToken)
                .contentType(MediaType.APPLICATION_JSON)
                .body(BodyInserters.fromValue(requestBody))
                .retrieve()
                .bodyToMono(ZoomMeetingResponse.class)
                .doOnError(e -> log.error("Error response from Zoom API during meeting creation for {}: {}", professionalName, e.getMessage(), e))
                .block();

            if (response != null && response.getId() != null) {
                log.info("Successfully created Zoom meeting for {}. Meeting ID: {}", professionalName, response.getId());
                return new ZoomMeetingDetails(
                    String.valueOf(response.getId()),
                    response.getStartUrl(),
                    response.getJoinUrl()
                );
            } else {
                log.error("Failed to create Zoom meeting for {}. Response was null or lacked ID. Response: {}", professionalName, response);
                throw new RuntimeException("Failed to create Zoom meeting for " + professionalName + ". Invalid response from Zoom.");
            }
        } catch (Exception e) {
            log.error("Exception during Zoom meeting creation for {}: {}", professionalName, e.getMessage(), e);
            throw new RuntimeException("Exception during Zoom meeting creation for " + professionalName, e);
        }
    }

    private Mono<String> getS2SAccessToken() {
        log.debug("Attempting to get Zoom S2S access token.");
        String credentials = Base64.getEncoder().encodeToString((zoomApiClientId + ":" + zoomApiClientSecret).getBytes(StandardCharsets.UTF_8));
        String tokenUrl = "https://zoom.us/oauth/token";

        return this.webClient.post()
            .uri(tokenUrl)
            .header(HttpHeaders.AUTHORIZATION, "Basic " + credentials)
            .contentType(MediaType.APPLICATION_FORM_URLENCODED)
            .body(BodyInserters.fromFormData("grant_type", "account_credentials")
                             .with("account_id", zoomApiAccountId))
            .retrieve()
            .bodyToMono(Map.class)
            .map(responseBody -> {
                if (responseBody == null || !responseBody.containsKey("access_token")) {
                    log.error("Zoom S2S token response is invalid or missing access_token. Response: {}", responseBody);
                    throw new RuntimeException("Invalid response from Zoom token endpoint.");
                }
                String token = (String) responseBody.get("access_token");
                log.debug("Successfully retrieved Zoom S2S access token.");
                return token;
            })
            .doOnError(e -> log.error("Error obtaining Zoom S2S token: {}", e.getMessage(), e));
    }

    // Inner DTOs for Zoom API
    static class ZoomMeetingRequest {
        private String topic;
        private int type;
        private ZoomMeetingSettings settings;
        private String password;

        public String getTopic() { return topic; }
        public void setTopic(String topic) { this.topic = topic; }
        public int getType() { return type; }
        public void setType(int type) { this.type = type; }
        public ZoomMeetingSettings getSettings() { return settings; }
        public void setSettings(ZoomMeetingSettings settings) { this.settings = settings; }
        public String getPassword() { return password; }
        public void setPassword(String password) { this.password = password; }
    }

    static class ZoomMeetingSettings {
        @JsonProperty("join_before_host")
        private boolean joinBeforeHost;
        @JsonProperty("waiting_room")
        private boolean waitingRoom;
        @JsonProperty("meeting_authentication")
        private boolean meetingAuthentication;

        public boolean isJoinBeforeHost() { return joinBeforeHost; }
        public void setJoinBeforeHost(boolean joinBeforeHost) { this.joinBeforeHost = joinBeforeHost; }
        public boolean isWaitingRoom() { return waitingRoom; }
        public void setWaitingRoom(boolean waitingRoom) { this.waitingRoom = waitingRoom; }
        public boolean isMeetingAuthentication() { return meetingAuthentication; }
        public void setMeetingAuthentication(boolean meetingAuthentication) { this.meetingAuthentication = meetingAuthentication; }
    }

    static class ZoomMeetingResponse {
        private Long id;
        private String topic;
        @JsonProperty("join_url")
        private String joinUrl;
        @JsonProperty("start_url")
        private String startUrl;

        public Long getId() { return id; }
        public void setId(Long id) { this.id = id; }
        public String getTopic() { return topic; }
        public void setTopic(String topic) { this.topic = topic; }
        public String getJoinUrl() { return joinUrl; }
        public void setJoinUrl(String joinUrl) { this.joinUrl = joinUrl; }
        public String getStartUrl() { return startUrl; }
        public void setStartUrl(String startUrl) { this.startUrl = startUrl; }
    }
}
