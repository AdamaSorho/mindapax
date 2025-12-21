package com.adamasorho.mindapax_backend.dto;

import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

class ZoomSignatureResponseTest {

    @Test
    void testZoomSignatureResponseConstructionAndGetters() {
        String apiKey = "testApiKey";
        String meetingNumber = "123456789";
        String signature = "testSignature";
        String password = "testPassword";
        String startUrl = "https://zoom.us/s/123";

        // Test constructor (implicitly testing @AllArgsConstructor)
        ZoomSignatureResponse response = new ZoomSignatureResponse(apiKey, meetingNumber, signature, password, startUrl);

        // Test getters (implicitly testing @Data)
        assertEquals(apiKey, response.getApiKey());
        assertEquals(meetingNumber, response.getMeetingNumber());
        assertEquals(signature, response.getSignature());
        assertEquals(password, response.getPassword());
        assertEquals(startUrl, response.getStartUrl());
    }

    @Test
    void testZoomSignatureResponseConstructionWithNullPassword() {
        String apiKey = "testApiKey";
        String meetingNumber = "123456789";
        String signature = "testSignature";
        String startUrl = "https://zoom.us/s/321";

        // Test constructor with null password
        ZoomSignatureResponse response = new ZoomSignatureResponse(apiKey, meetingNumber, signature, null, startUrl);

        assertEquals(apiKey, response.getApiKey());
        assertEquals(meetingNumber, response.getMeetingNumber());
        assertEquals(signature, response.getSignature());
        assertNull(response.getPassword());
        assertEquals(startUrl, response.getStartUrl());
    }

    @Test
    void testSetters() {
        // Test setters (implicitly testing @Data and @NoArgsConstructor if used)
        ZoomSignatureResponse response = new ZoomSignatureResponse();
        response.setApiKey("newApiKey");
        response.setMeetingNumber("987654321");
        response.setSignature("newSignature");
        response.setPassword("newPassword");
        response.setStartUrl("https://zoom.us/s/987");

        assertEquals("newApiKey", response.getApiKey());
        assertEquals("987654321", response.getMeetingNumber());
        assertEquals("newSignature", response.getSignature());
        assertEquals("newPassword", response.getPassword());
        assertEquals("https://zoom.us/s/987", response.getStartUrl());
    }
}
