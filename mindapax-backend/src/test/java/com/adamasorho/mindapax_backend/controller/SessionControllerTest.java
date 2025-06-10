package com.adamasorho.mindapax_backend.controller;

import com.adamasorho.mindapax_backend.dto.SessionDTO;
import com.adamasorho.mindapax_backend.dto.ZoomSignatureResponse;
import com.adamasorho.mindapax_backend.mapper.SessionMapper;
import com.adamasorho.mindapax_backend.model.Professional;
import com.adamasorho.mindapax_backend.model.Session;
import com.adamasorho.mindapax_backend.model.User;
import com.adamasorho.mindapax_backend.model.enums.SessionMode;
import com.adamasorho.mindapax_backend.model.enums.UserRole;
import com.adamasorho.mindapax_backend.security.CustomUserDetails;
import com.adamasorho.mindapax_backend.service.SessionService;
import com.adamasorho.mindapax_backend.service.ZoomService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.server.ResponseStatusException;

import java.util.Collections; // For CustomUserDetails authorities

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
public class SessionControllerTest {

    @Mock
    private SessionService sessionService;

    @Mock
    private SessionMapper sessionMapper;

    @Mock
    private ZoomService zoomService;

    @InjectMocks
    private SessionController sessionController;

    private User clientUser;
    private User professionalUser;
    private Professional professional;
    private Session videoSession;
    private SessionDTO videoSessionDTO;

    @BeforeEach
    void setUp() {
        clientUser = new User();
        clientUser.setId(1L);
        clientUser.setEmail("client@example.com");
        clientUser.setRole(UserRole.USER);

        professionalUser = new User();
        professionalUser.setId(2L);
        professionalUser.setEmail("prof@example.com");
        professionalUser.setRole(UserRole.PROFESSIONAL);

        professional = new Professional();
        professional.setId(2L); // Assuming Professional ID is same as User ID for simplicity here
        professional.setUser(professionalUser);

        videoSession = new Session();
        videoSession.setId(100L);
        videoSession.setUser(clientUser);
        videoSession.setProfessional(professional);
        videoSession.setMode(SessionMode.VIDEO);

        videoSessionDTO = new SessionDTO(); // Populate this DTO as your mapper would
        videoSessionDTO.setId(100L);
        videoSessionDTO.setUserId(clientUser.getId());
        // Assuming SessionDTO has a way to get professional's user ID or Professional object/ID
        // For this test, let's assume it has professionalId which maps to Professional entity's ID.
        // And that mapper can reconstruct the Professional entity with its User.
        videoSessionDTO.setProfessionalId(professional.getId());
        videoSessionDTO.setMode(SessionMode.VIDEO);


        // Mock security context
        // No specific authorities needed for hasAnyRole('USER', 'PROFESSIONAL') beyond authentication
        CustomUserDetails userDetails = new CustomUserDetails(clientUser);
        Authentication authentication = new UsernamePasswordAuthenticationToken(userDetails, null, userDetails.getAuthorities());
        SecurityContextHolder.getContext().setAuthentication(authentication);
    }

    private void mockSecurityContext(User user, UserRole role) {
        CustomUserDetails userDetails = new CustomUserDetails(user);
        Authentication authentication = new UsernamePasswordAuthenticationToken(userDetails, null, userDetails.getAuthorities());
        SecurityContextHolder.getContext().setAuthentication(authentication);
    }

    @Test
    void joinVideoSession_asClient_success() {
        mockSecurityContext(clientUser, UserRole.USER);

        when(sessionService.getSessionById(videoSession.getId())).thenReturn(videoSessionDTO);
        when(sessionMapper.toEntity(videoSessionDTO)).thenReturn(videoSession); // Ensure mapper returns the full entity
        when(zoomService.getSdkKey()).thenReturn("testSdkKey");
        when(zoomService.generateSignature(String.valueOf(videoSession.getId()), 0)).thenReturn("testSignature");

        ResponseEntity<ZoomSignatureResponse> response = sessionController.joinVideoSession(videoSession.getId());

        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertNotNull(response.getBody());
        assertEquals("testSdkKey", response.getBody().getApiKey());
        assertEquals(String.valueOf(videoSession.getId()), response.getBody().getMeetingNumber());
        assertEquals("testSignature", response.getBody().getSignature());
    }

    @Test
    void joinVideoSession_asProfessional_success() {
        mockSecurityContext(professionalUser, UserRole.PROFESSIONAL);

        when(sessionService.getSessionById(videoSession.getId())).thenReturn(videoSessionDTO);
        when(sessionMapper.toEntity(videoSessionDTO)).thenReturn(videoSession);
        when(zoomService.getSdkKey()).thenReturn("testSdkKey");
        when(zoomService.generateSignature(String.valueOf(videoSession.getId()), 1)).thenReturn("testSignatureProf");

        ResponseEntity<ZoomSignatureResponse> response = sessionController.joinVideoSession(videoSession.getId());

        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertNotNull(response.getBody());
        assertEquals("testSdkKey", response.getBody().getApiKey());
        assertEquals("testSignatureProf", response.getBody().getSignature());
    }

    @Test
    void joinVideoSession_sessionNotFound() {
        mockSecurityContext(clientUser, UserRole.USER);
        when(sessionService.getSessionById(anyLong())).thenThrow(new ResponseStatusException(HttpStatus.NOT_FOUND, "Session not found"));

        ResponseStatusException exception = assertThrows(ResponseStatusException.class, () -> {
            sessionController.joinVideoSession(999L);
        });
        assertEquals(HttpStatus.NOT_FOUND, exception.getStatusCode());
    }

    @Test
    void joinVideoSession_notVideoSession() {
        mockSecurityContext(clientUser, UserRole.USER);
        Session chatSession = new Session();
        chatSession.setId(101L);
        chatSession.setUser(clientUser);
        chatSession.setProfessional(professional);
        chatSession.setMode(SessionMode.CHAT); // Not a video session

        SessionDTO chatSessionDTO = new SessionDTO();
        chatSessionDTO.setId(101L);
        chatSessionDTO.setMode(SessionMode.CHAT);

        when(sessionService.getSessionById(chatSession.getId())).thenReturn(chatSessionDTO);
        when(sessionMapper.toEntity(chatSessionDTO)).thenReturn(chatSession);

        ResponseStatusException exception = assertThrows(ResponseStatusException.class, () -> {
            sessionController.joinVideoSession(chatSession.getId());
        });
        assertEquals(HttpStatus.BAD_REQUEST, exception.getStatusCode());
        assertTrue(exception.getReason().contains("Session is not a video session"));
    }

    @Test
    void joinVideoSession_userNotPartOfSession() {
        User otherUser = new User();
        otherUser.setId(3L);
        otherUser.setRole(UserRole.USER);
        mockSecurityContext(otherUser, UserRole.USER); // Authenticated as a different user

        when(sessionService.getSessionById(videoSession.getId())).thenReturn(videoSessionDTO);
        when(sessionMapper.toEntity(videoSessionDTO)).thenReturn(videoSession);

        ResponseStatusException exception = assertThrows(ResponseStatusException.class, () -> {
            sessionController.joinVideoSession(videoSession.getId());
        });
        assertEquals(HttpStatus.FORBIDDEN, exception.getStatusCode());
        assertTrue(exception.getReason().contains("User not part of this session"));
    }

    @Test
    void joinVideoSession_unauthenticatedUser() {
        SecurityContextHolder.getContext().setAuthentication(null); // Simulate unauthenticated

        // Note: @PreAuthorize might handle this before method execution,
        // leading to a Spring Security exception rather than our ResponseStatusException.
        // However, the internal check is also good defense-in-depth.
        // For this test, we'll assume it reaches our controller logic for the null check.
        // If Spring Security's filter chain denies access earlier, this specific test might fail
        // or need to be adapted to expect AccessDeniedException or similar.

        // The controller code itself throws ResponseStatusException if auth is null or principal isn't CustomUserDetails
        ResponseStatusException exception = assertThrows(ResponseStatusException.class, () -> {
             sessionController.joinVideoSession(videoSession.getId());
        });
        assertEquals(HttpStatus.UNAUTHORIZED, exception.getStatusCode());
    }
}
