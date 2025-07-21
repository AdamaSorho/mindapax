package com.adamasorho.mindapax_backend.controller;

import com.adamasorho.mindapax_backend.dto.UserDTO;
import com.adamasorho.mindapax_backend.mapper.ProfessionalMapper;
import com.adamasorho.mindapax_backend.model.Professional;
import com.adamasorho.mindapax_backend.model.User;
import com.adamasorho.mindapax_backend.repository.ProfessionalRepository;
import com.adamasorho.mindapax_backend.service.ProfessionalService;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.persistence.EntityNotFoundException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.http.MediaType;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

import java.util.Collections;
import java.util.Optional;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@WebMvcTest(ProfessionalController.class)
class ProfessionalControllerTests {

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private ProfessionalService professionalService;

    @MockitoBean
    private ProfessionalRepository professionalRepository;

    @MockitoBean
    private ProfessionalMapper professionalMapper; // ProfessionalController depends on this

    @Autowired
    private ObjectMapper objectMapper;

    private Professional professional;
    private User professionalUser;
    private UserDTO connectedUserDTO;
    private Page<UserDTO> userDTOPage;

    @BeforeEach
    void setUp() {
        professionalUser = new User();
        professionalUser.setId(1L);
        professionalUser.setEmail("prof@example.com");

        professional = new Professional();
        professional.setId(1L); // This is the Professional's own ID, which is also the User ID due to @MapsId
        professional.setUser(professionalUser);

        connectedUserDTO = new UserDTO();
        connectedUserDTO.setId(10L);
        connectedUserDTO.setFirstName("Connected");
        connectedUserDTO.setLastName("User");

        userDTOPage = new PageImpl<>(Collections.singletonList(connectedUserDTO), PageRequest.of(0, 20), 1);
    }

    @Test
    @WithMockUser(username = "prof@example.com", roles = {"PROFESSIONAL"})
    void testGetMyConnectedUsers_Success() throws Exception {
        when(professionalRepository.findByUserEmail("prof@example.com")).thenReturn(Optional.of(professional));
        when(professionalService.getConnectedUsers(eq(professional.getId()), any(Pageable.class)))
                .thenReturn(userDTOPage);

        mockMvc.perform(get("/api/v1/professionals/me/connected-users")
                        .param("page", "0")
                        .param("size", "20")
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(content().contentType(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$.content[0].id").value(connectedUserDTO.getId()))
                .andExpect(jsonPath("$.content[0].firstName").value(connectedUserDTO.getFirstName()))
                .andExpect(jsonPath("$.totalElements").value(1));
    }

    @Test
    @WithMockUser(username = "prof@example.com", roles = {"PROFESSIONAL"})
    void testGetMyConnectedUsers_ProfessionalEntityNotFoundForAuthenticatedUser() throws Exception {
        when(professionalRepository.findByUserEmail("prof@example.com")).thenReturn(Optional.empty());

        mockMvc.perform(get("/api/v1/professionals/me/connected-users")
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isNotFound()); // Assuming EntityNotFoundException maps to 404
    }

    @Test
    @WithMockUser(username = "user@example.com", roles = {"USER"})
    void testGetMyConnectedUsers_Forbidden_WrongRole() throws Exception {
        mockMvc.perform(get("/api/v1/professionals/me/connected-users")
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isForbidden());
    }

    @Test
    // No @WithMockUser, so anonymous/unauthenticated
    void testGetMyConnectedUsers_Unauthorized_NoUser() throws Exception {
        mockMvc.perform(get("/api/v1/professionals/me/connected-users")
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isUnauthorized());
    }

    @Test
    @WithMockUser(username = "prof@example.com", roles = {"PROFESSIONAL"})
    void testGetMyConnectedUsers_ServiceThrowsException() throws Exception {
        when(professionalRepository.findByUserEmail("prof@example.com")).thenReturn(Optional.of(professional));
        when(professionalService.getConnectedUsers(eq(professional.getId()), any(Pageable.class)))
                .thenThrow(new RuntimeException("Service layer error"));

        mockMvc.perform(get("/api/v1/professionals/me/connected-users")
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isInternalServerError()); // Or whatever your global exception handler returns
    }
}
