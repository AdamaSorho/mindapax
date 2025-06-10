package com.adamasorho.mindapax_backend.controller;

import com.adamasorho.mindapax_backend.dto.SessionDTO;
import com.adamasorho.mindapax_backend.model.enums.SessionMode;
import com.adamasorho.mindapax_backend.service.SessionService;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.http.MediaType;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

import java.time.LocalDateTime;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.util.Collections;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;
import org.mockito.ArgumentCaptor;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.Pageable;
import com.adamasorho.mindapax_backend.dto.SessionTimeFilter;
import static org.mockito.ArgumentMatchers.eq;
import static org.junit.jupiter.api.Assertions.assertEquals;

@WebMvcTest(SessionController.class)
class SessionControllerTests {

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private SessionService sessionService;

    @Autowired
    private ObjectMapper objectMapper; // Automatically configured by Spring Boot

    private SessionDTO sessionDTO;
    private SessionDTO requestDTO;

    @BeforeEach
    void setUp() {
        // objectMapper.registerModule(new JavaTimeModule()); // Register JavaTimeModule for ObjectMapper if not already globally configured

        // objectMapper.registerModule(new JavaTimeModule()); // Register JavaTimeModule for ObjectMapper if not already globally configured

        requestDTO = new SessionDTO();
        requestDTO.setUserId(2L);
        // Use a specific OffsetDateTime for predictability in tests
        requestDTO.setStartTime(OffsetDateTime.of(2023, 12, 1, 10, 0, 0, 0, ZoneOffset.ofHours(-5)));
        requestDTO.setDurationMinutes(60);
        requestDTO.setMode(SessionMode.VIDEO);
        requestDTO.setNotes("Client consultation");

        sessionDTO = new SessionDTO(); // This would be the DTO returned by the service
        sessionDTO.setId(1L);
        sessionDTO.setUserId(requestDTO.getUserId());
        sessionDTO.setProfessionalId(1L); // Assuming professional ID is 1
        sessionDTO.setProfessionalName("Dr. Professional");
        sessionDTO.setProfessionalSpecialization("MENTAL_HEALTH");
        sessionDTO.setStartTime(requestDTO.getStartTime()); // Will be OffsetDateTime
        sessionDTO.setDurationMinutes(requestDTO.getDurationMinutes());
        sessionDTO.setMode(requestDTO.getMode());
        sessionDTO.setNotes(requestDTO.getNotes());
        sessionDTO.setStatus(com.adamasorho.mindapax_backend.model.enums.SessionStatus.SCHEDULED);
    }

    @Test
    @WithMockUser(username = "prof@example.com", roles = {"PROFESSIONAL"})
    void testScheduleByProfessional_Success() throws Exception {
        when(sessionService.scheduleSessionByProfessional(any(SessionDTO.class))).thenReturn(sessionDTO);

        mockMvc.perform(post("/api/v1/sessions/professional/schedule")
                        .with(csrf()) // If CSRF is enabled
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(requestDTO)))
                .andExpect(status().isCreated())
                .andExpect(content().contentType(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$.id").value(sessionDTO.getId()))
                .andExpect(jsonPath("$.userId").value(sessionDTO.getUserId()))
                .andExpect(jsonPath("$.professionalId").value(sessionDTO.getProfessionalId()))
                .andExpect(jsonPath("$.professionalName").value(sessionDTO.getProfessionalName()))
                // Note: LocalDateTime needs custom serializer/deserializer or string comparison for JSON path
                .andExpect(jsonPath("$.startTime").value(sessionDTO.getStartTime().toString()))
                .andExpect(jsonPath("$.durationMinutes").value(sessionDTO.getDurationMinutes().toString()))
                .andExpect(jsonPath("$.mode").value(sessionDTO.getMode().toString()))
                .andExpect(jsonPath("$.status").value(sessionDTO.getStatus().toString()));
    }

    @Test
    @WithMockUser(username = "user@example.com", roles = {"USER"})
    void testScheduleByProfessional_Forbidden_WrongRole() throws Exception {
        mockMvc.perform(post("/api/v1/sessions/professional/schedule")
                        .with(csrf())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(requestDTO)))
                .andExpect(status().isForbidden());
    }

    @Test
    // No @WithMockUser, so anonymous/unauthenticated
    void testScheduleByProfessional_Unauthorized_NoUser() throws Exception {
        mockMvc.perform(post("/api/v1/sessions/professional/schedule")
                        .with(csrf())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(requestDTO)))
                .andExpect(status().isUnauthorized()); // Or 403 if Spring Security defaults to that for unauth path access
    }


    @Test
    @WithMockUser(username = "prof@example.com", roles = {"PROFESSIONAL"})
    void testScheduleByProfessional_InvalidRequestBody() throws Exception {
        SessionDTO invalidRequestDTO = new SessionDTO(); // Missing required fields like userId, startTime, endTime, mode
        // No userId, no startTime, etc.

        mockMvc.perform(post("/api/v1/sessions/professional/schedule")
                        .with(csrf())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(invalidRequestDTO)))
                .andExpect(status().isBadRequest()); // Assuming @Valid is on the controller method's @RequestBody
    }

    @Test
    @WithMockUser(username = "testuser@example.com", roles = {"USER"})
    void testGetSessionsByUser_WithOffsetDateTimeParameter() throws Exception {
        // Arrange
        String requestDateStr = "2023-12-15T12:00:00-05:00";
        OffsetDateTime parsedRequestDate = OffsetDateTime.parse(requestDateStr);

        SessionDTO responseSessionDTO = new SessionDTO();
        responseSessionDTO.setId(1L);
        responseSessionDTO.setUserId(1L);
        responseSessionDTO.setStartTime(parsedRequestDate.plusDays(1)); // Example time
        responseSessionDTO.setDurationMinutes(60);
        responseSessionDTO.setMode(SessionMode.VIDEO);
        responseSessionDTO.setStatus(com.adamasorho.mindapax_backend.model.enums.SessionStatus.SCHEDULED);

        when(sessionService.getSessionsByUserAndTime(
                any(String.class), // Changed from Long to String to match controller
                any(OffsetDateTime.class),
                any(SessionTimeFilter.class),
                any(), // For status, can be null
                any(Pageable.class)))
                .thenReturn(new PageImpl<>(Collections.singletonList(responseSessionDTO)));


        // Act
        mockMvc.perform(get("/api/v1/sessions/by-user")
                        .param("date", requestDateStr) // Pass the ISO 8601 string
                        .accept(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(content().contentType(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$.content[0].id").value(responseSessionDTO.getId()))
                .andExpect(jsonPath("$.content[0].startTime").value(responseSessionDTO.getStartTime().toString()));

        // Assert service call
        ArgumentCaptor<OffsetDateTime> dateTimeCaptor = ArgumentCaptor.forClass(OffsetDateTime.class);
        ArgumentCaptor<String> userIdCaptor = ArgumentCaptor.forClass(String.class); // Capture userId as String

        verify(sessionService).getSessionsByUserAndTime(
                userIdCaptor.capture(), // Capture userId
                dateTimeCaptor.capture(),
                eq(SessionTimeFilter.UPCOMING), // Default filter in controller if not specified
                eq(null), // Default status in controller if not specified
                any(Pageable.class)
        );

        assertEquals("testuser@example.com", userIdCaptor.getValue()); // Verify username from @WithMockUser
        assertEquals(parsedRequestDate, dateTimeCaptor.getValue());
    }
}
