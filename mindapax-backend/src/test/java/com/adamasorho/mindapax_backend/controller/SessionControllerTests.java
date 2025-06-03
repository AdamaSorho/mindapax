package com.adamasorho.mindapax_backend.controller;

import com.adamasorho.mindapax_backend.dto.SessionDTO;
import com.adamasorho.mindapax_backend.model.enums.SessionMode;
import com.adamasorho.mindapax_backend.service.SessionService;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.web.servlet.MockMvc;

import java.time.LocalDateTime;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@WebMvcTest(SessionController.class)
class SessionControllerTests {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private SessionService sessionService;

    @Autowired
    private ObjectMapper objectMapper; // Automatically configured by Spring Boot

    private SessionDTO sessionDTO;
    private SessionDTO requestDTO;

    @BeforeEach
    void setUp() {
        // objectMapper.registerModule(new JavaTimeModule()); // Register JavaTimeModule for ObjectMapper if not already globally configured

        requestDTO = new SessionDTO();
        requestDTO.setUserId(2L);
        requestDTO.setStartTime(LocalDateTime.now().plusDays(1).withHour(10).withMinute(0).withSecond(0).withNano(0));
        requestDTO.setEndTime(LocalDateTime.now().plusDays(1).withHour(11).withMinute(0).withSecond(0).withNano(0));
        requestDTO.setMode(SessionMode.VIDEO);
        requestDTO.setNotes("Client consultation");

        sessionDTO = new SessionDTO(); // This would be the DTO returned by the service
        sessionDTO.setId(1L);
        sessionDTO.setUserId(requestDTO.getUserId());
        sessionDTO.setProfessionalId(1L); // Assuming professional ID is 1
        sessionDTO.setProfessionalName("Dr. Professional");
        sessionDTO.setProfessionalSpecialization("MENTAL_HEALTH");
        sessionDTO.setStartTime(requestDTO.getStartTime());
        sessionDTO.setEndTime(requestDTO.getEndTime());
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
                .andExpect(jsonPath("$.endTime").value(sessionDTO.getEndTime().toString()))
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
}
