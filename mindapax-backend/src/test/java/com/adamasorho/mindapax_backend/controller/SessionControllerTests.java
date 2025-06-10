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
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;
import java.time.Duration;
import org.springframework.data.domain.PageRequest;

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

    @Test
    @WithMockUser(username = "testuser", roles = {"USER"})
    void testGetSessionsByUser_WithUTCDateParameter() throws Exception {
        // Arrange
        String requestDateStr = "2023-12-01T15:00:00Z"; // UTC 'Z'
        OffsetDateTime expectedDateTime = OffsetDateTime.parse(requestDateStr);

        when(sessionService.getSessionsByUserAndTime(
                any(String.class),
                any(OffsetDateTime.class),
                any(SessionTimeFilter.class),
                any(), // status
                any(Pageable.class)))
                .thenReturn(new PageImpl<>(Collections.emptyList(), PageRequest.of(0, 10), 0));

        // Act
        mockMvc.perform(get("/api/v1/sessions/by-user")
                        .param("date", requestDateStr)
                        // .param("filter", "UPCOMING") // Rely on controller default if any
                        // .param("userId", "testuser") // Handled by @WithMockUser
                        .accept(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk());

        // Assert
        ArgumentCaptor<OffsetDateTime> dateTimeCaptor = ArgumentCaptor.forClass(OffsetDateTime.class);
        ArgumentCaptor<String> userIdCaptor = ArgumentCaptor.forClass(String.class);

        verify(sessionService).getSessionsByUserAndTime(
                userIdCaptor.capture(),
                dateTimeCaptor.capture(),
                any(SessionTimeFilter.class), // Or specific default like UPCOMING
                any(), // status
                any(Pageable.class)
        );
        assertEquals("testuser", userIdCaptor.getValue());
        assertTrue(expectedDateTime.isEqual(dateTimeCaptor.getValue()),
                "Captured OffsetDateTime should be equal to the parsed UTC input string.");
    }

    @Test
    @WithMockUser(username = "testuser", roles = {"USER"})
    void testGetSessionsByUser_WithDateParameterWithoutOffset() throws Exception {
        // Arrange
        String requestDateStr = "2023-12-01T10:00:00"; // No offset
        // Spring's @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) for OffsetDateTime
        // when no offset is provided, typically uses the system's default zone offset.
        // For testing consistency, we can't rely on a specific system default.
        // However, the parsing mechanism of OffsetDateTime.parse(text) itself would throw
        // DateTimeParseException if no offset found and no default can be inferred.
        // The @RequestParam binding with ISO.DATE_TIME might behave differently.
        // This test will observe Spring's behavior.
        // Let's assume for now Spring might parse it by attaching system's default offset.
        // Or it might fail, or it might parse as LocalDateTime then convert with default offset.

        when(sessionService.getSessionsByUserAndTime(
                any(String.class),
                any(OffsetDateTime.class),
                any(SessionTimeFilter.class),
                any(),
                any(Pageable.class)))
                .thenReturn(new PageImpl<>(Collections.emptyList(), PageRequest.of(0, 10), 0));

        // Act
        mockMvc.perform(get("/api/v1/sessions/by-user")
                        .param("date", requestDateStr)
                        .accept(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk());

        // Assert
        ArgumentCaptor<OffsetDateTime> dateTimeCaptor = ArgumentCaptor.forClass(OffsetDateTime.class);
        verify(sessionService).getSessionsByUserAndTime(
                anyString(),
                dateTimeCaptor.capture(),
                any(SessionTimeFilter.class),
                any(),
                any(Pageable.class)
        );

        OffsetDateTime capturedDateTime = dateTimeCaptor.getValue();
        // The key is what OffsetDateTime Spring creates from "2023-12-01T10:00:00".
        // It *should* be parsed as a LocalDateTime and then the system default offset applied.
        // For example, if system default is UTC, it would be 2023-12-01T10:00:00Z.
        // If system default is -05:00, it would be 2023-12-01T10:00:00-05:00.
        // We can check that the local part matches.
        assertEquals(10, capturedDateTime.getHour());
        assertEquals(0, capturedDateTime.getMinute());
        assertEquals(2023, capturedDateTime.getYear());
        assertEquals(12, capturedDateTime.getMonthValue());
        assertEquals(1, capturedDateTime.getDayOfMonth());
        // The offset itself would depend on the test environment's system zone.
        // This assertion is mainly to confirm it *was* parsed.
        assertNotNull(capturedDateTime.getOffset());
    }


    @Test
    @WithMockUser(username = "testuser", roles = {"USER"})
    void testGetSessionsByUser_WithNoDateParameter() throws Exception {
        // Arrange
        when(sessionService.getSessionsByUserAndTime(
                any(String.class),
                any(OffsetDateTime.class),
                any(SessionTimeFilter.class),
                any(), // status
                any(Pageable.class)))
                .thenReturn(new PageImpl<>(Collections.emptyList(), PageRequest.of(0, 10), 0));

        // Act
        mockMvc.perform(get("/api/v1/sessions/by-user")
                        // No "date" parameter
                        .accept(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk());

        // Assert
        ArgumentCaptor<OffsetDateTime> dateTimeCaptor = ArgumentCaptor.forClass(OffsetDateTime.class);
        ArgumentCaptor<String> userIdCaptor = ArgumentCaptor.forClass(String.class);

        verify(sessionService).getSessionsByUserAndTime(
                userIdCaptor.capture(),
                dateTimeCaptor.capture(),
                any(SessionTimeFilter.class),
                any(), // status
                any(Pageable.class)
        );

        OffsetDateTime capturedEffectiveDate = dateTimeCaptor.getValue();
        assertEquals("testuser", userIdCaptor.getValue());
        assertNotNull(capturedEffectiveDate);
        // Check if the captured date is very recent (e.g., within the last 5 seconds)
        assertTrue(Duration.between(capturedEffectiveDate, OffsetDateTime.now()).abs().getSeconds() < 5,
                "Captured OffsetDateTime should be close to OffsetDateTime.now().");
    }
}
