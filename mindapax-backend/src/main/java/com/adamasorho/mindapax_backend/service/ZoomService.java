package com.adamasorho.mindapax_backend.service;

public interface ZoomService {
    /**
     * Generates a signature required by the Zoom Web SDK.
     * @param meetingNumber The unique identifier for the Zoom meeting.
     * @param role The role of the user in the Zoom meeting (e.g., 1 for host, 0 for attendee).
     * @return The generated signature.
     * @throws RuntimeException if signature generation fails.
     */
    String generateSignature(String meetingNumber, int role);

    /**
     * Retrieves the Zoom SDK Key from application configuration.
     * @return The Zoom SDK Key.
     */
    String getSdkKey();

    /**
     * Creates a permanent Zoom meeting for a professional.
     * @param professionalName The name of the professional, used for the meeting topic.
     * @param password The password for the Zoom meeting.
     * @return Meeting details including ID and start URL.
     * @throws RuntimeException if meeting creation fails.
     */
    ZoomMeetingDetails createPermanentMeetingForProfessional(String professionalName, String password);
}
