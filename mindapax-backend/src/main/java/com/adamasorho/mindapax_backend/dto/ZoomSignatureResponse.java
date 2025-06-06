package com.adamasorho.mindapax_backend.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class ZoomSignatureResponse {
    private String apiKey;
    private String meetingNumber;
    private String signature;
    // Consider adding userName and userEmail if they are determined on the backend
    // and needed by the frontend for the Zoom SDK join method.
    // For now, kept it simple as per initial plan.
}
