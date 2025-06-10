package com.adamasorho.mindapax_backend.service.impl;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jws;
import io.jsonwebtoken.Jwts;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.test.util.ReflectionTestUtils;

import static org.junit.jupiter.api.Assertions.*;

public class ZoomServiceImplTest {

    private ZoomServiceImpl zoomService;

    private final String mockSdkKey = "testSdkKey";
    // Ensure the secret is long enough for HS256, typically 256 bits / 32 bytes
    private final String mockSdkSecret = "TestSecretKeyForHs256Algorithm123";

    @BeforeEach
    void setUp() {
        zoomService = new ZoomServiceImpl();
        ReflectionTestUtils.setField(zoomService, "zoomSdkKey", mockSdkKey);
        ReflectionTestUtils.setField(zoomService, "zoomSdkSecret", mockSdkSecret);
    }

    @Test
    void getSdkKey_shouldReturnSdkKey() {
        assertEquals(mockSdkKey, zoomService.getSdkKey());
    }

    @Test
    void generateSignature_shouldReturnValidJwt() {
        String meetingNumber = "123456789";
        int role = 0; // Attendee

        String signature = zoomService.generateSignature(meetingNumber, role);
        assertNotNull(signature);
        assertTrue(signature.split("\\.").length == 3, "Signature should be a valid JWT format");

        // Verify JWT claims
        Jws<Claims> parsedJwt = Jwts.parserBuilder()
                                .setSigningKey(mockSdkSecret.getBytes())
                                .build()
                                .parseClaimsJws(signature);

        Claims claims = parsedJwt.getBody();
        assertEquals(mockSdkKey, claims.get("appKey", String.class));
        assertEquals(mockSdkKey, claims.get("sdkKey", String.class));
        assertEquals(meetingNumber, claims.get("mn", String.class));
        assertEquals(role, claims.get("role", Integer.class));
        assertNotNull(claims.getIssuedAt());
        assertNotNull(claims.getExpiration());
        assertTrue(claims.getExpiration().after(claims.getIssuedAt()));
        // Check if iat is reasonably close to now (e.g., within 60 seconds)
        long nowInSeconds = System.currentTimeMillis() / 1000;
        assertTrue(Math.abs(claims.getIssuedAt().getTime() / 1000 - nowInSeconds) < 60);
    }

    @Test
    void generateSignature_shouldHandleDifferentRoles() {
        String meetingNumber = "987654321";
        int hostRole = 1; // Host

        String signature = zoomService.generateSignature(meetingNumber, hostRole);
        Jws<Claims> parsedJwt = Jwts.parserBuilder()
                                .setSigningKey(mockSdkSecret.getBytes())
                                .build()
                                .parseClaimsJws(signature);
        assertEquals(hostRole, parsedJwt.getBody().get("role", Integer.class));
    }

    @Test
    void generateSignature_withEmptyMeetingNumber_shouldStillGenerate() {
        // Zoom might require non-empty meeting number, but JWT generation itself should work.
        // Application logic should validate meetingNumber if it's mandatory.
        String meetingNumber = "";
        int role = 0;
        assertDoesNotThrow(() -> {
            String signature = zoomService.generateSignature(meetingNumber, role);
            assertNotNull(signature);
        });
    }

    @Test
    void generateSignature_expirationShouldBeApproximatelyTwoHoursFromIssue() {
        String meetingNumber = "123";
        int role = 0;
        String signature = zoomService.generateSignature(meetingNumber, role);
        Jws<Claims> parsedJwt = Jwts.parserBuilder()
                                .setSigningKey(mockSdkSecret.getBytes())
                                .build()
                                .parseClaimsJws(signature);
        Claims claims = parsedJwt.getBody();
        long issueAtSeconds = claims.getIssuedAt().getTime() / 1000;
        long expirationAtSeconds = claims.getExpiration().getTime() / 1000;
        // Expected diff: 7200 seconds (2 hours). Allow small variance for execution time.
        assertEquals(7200, expirationAtSeconds - issueAtSeconds, 5);
    }
}
