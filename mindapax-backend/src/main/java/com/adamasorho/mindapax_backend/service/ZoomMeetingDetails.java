package com.adamasorho.mindapax_backend.service;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class ZoomMeetingDetails {
    private String meetingId;
    private String startUrl;
    private String joinUrl;
}
