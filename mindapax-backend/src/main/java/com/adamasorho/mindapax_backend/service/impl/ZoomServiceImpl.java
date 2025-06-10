package com.adamasorho.mindapax_backend.service.impl;

import com.adamasorho.mindapax_backend.service.ZoomService;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.SignatureAlgorithm;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.nio.charset.StandardCharsets;
import java.util.Date;

@Service
public class ZoomServiceImpl implements ZoomService {

    // TODO: Replace these mock credentials by securely fetching from Vault or environment variables in production.
    @Value("${zoom.sdk_key}")
    private String zoomSdkKey;

    @Value("${zoom.sdk_secret}")
    private String zoomSdkSecret;

    @Override
    public String getSdkKey() {
        // This is the SDK Key (formerly API Key), not the SDK Secret or API Secret.
        return zoomSdkKey;
    }

    @Override
    public String generateSignature(String meetingNumber, int role) {
        try {
            long timestamp = new Date().getTime() / 1000 - 30; // Current time - 30s leeway
            long expiryTimestamp = timestamp + 7200; // Expires in 2 hours, adjust as needed

            // IMPORTANT: This is the SDK JWT Signature.
            // The Zoom Web SDK requires a signature generated with SDK Key and SDK Secret.
            // It's different from server-to-server OAuth tokens or user-level OAuth tokens.

            // Create the JWT payload
            // Refer to Zoom Developer Docs for the most up-to-date required claims:
            // https://developers.zoom.us/docs/meeting-sdk/auth/
            String payload = Jwts.builder()
                .claim("appKey", zoomSdkKey) // Use appKey or sdkKey based on Zoom's current terminology
                // .claim("sdkKey", zoomSdkKey) // Some docs show sdkKey
                .claim("mn", meetingNumber)
                .claim("role", role)
                .claim("iat", timestamp)
                .claim("exp", expiryTimestamp)
                .claim("tokenExp", expiryTimestamp) // tokenExp is also commonly used
                .signWith(SignatureAlgorithm.HS256, zoomSdkSecret.getBytes(StandardCharsets.UTF_8)) // Use the SDK Secret
                .compact();

            return payload;

        } catch (Exception e) {
            // Log the exception in a real application
            System.err.println("Error generating Zoom signature: " + e.getMessage());
            throw new RuntimeException("Error generating Zoom signature", e);
        }
    }
}
