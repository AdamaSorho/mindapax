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
import static org.mockito.Mockito.verify;
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
        // clientUser = new User(); // Initialized below for clarity
        // clientUser.setId(1L); // Initialized below for clarity
        clientUser.setEmail("client@example.com");
        clientUser.setRole(UserRole.USER);

        professionalUser = new User();
        professionalUser.setId(2L);
        professionalUser.setEmail("prof@example.com");
        professionalUser.setRole(UserRole.PROFESSIONAL);

        professional = new Professional();
        professional.setId(2L);
        professional.setUser(professionalUser);

        videoSession = new Session();
        videoSession.setId(100L);
        videoSession.setUser(clientUser);
        videoSession.setProfessional(professional);
        videoSession.setMode(SessionMode.VIDEO);
        videoSession.setZoomMeetingId("defaultZoomId123"); // Added default zoomMeetingId
        professional.setZoomMeetingStartUrl("https://start.example.com"); // Default start URL

        // videoSessionDTO is no longer directly needed in setUp for these tests after controller changes
        // videoSessionDTO = new SessionDTO();
        // videoSessionDTO.setId(100L);
        // videoSessionDTO.setUserId(clientUser.getId());
        // videoSessionDTO.setProfessionalId(professional.getId());
        // videoSessionDTO.setMode(SessionMode.VIDEO);

        // Initial security context can be set here if a default user is mostly used,
        // or set specifically in each test method via mockSecurityContext.
        // For clarity, we'll ensure it's explicitly set in test methods.
        // CustomUserDetails userDetails = new CustomUserDetails(clientUser);
        // Authentication authentication = new UsernamePasswordAuthenticationToken(userDetails, null, userDetails.getAuthorities());
        // SecurityContextHolder.getContext().setAuthentication(authentication);
    }

    private void mockSecurityContext(User user, UserRole role) {
        // Ensure clientUser is initialized before being used by CustomUserDetails
        if (user == null) { // Basic initialization if user is null
            user = new User();
            user.setId(0L); // Default ID or ensure it's set before use
            user.setRole(UserRole.USER); // Default role
            user.setEmail("default@example.com");
        } else {
             // Ensure the user object, especially clientUser, is fully initialized
            if (user.getId() == null) user.setId(0L); // Example default
            if (user.getRole() == null) user.setRole(UserRole.USER); // Example default
            if (user.getEmail() == null) user.setEmail("default@example.com"); // Example default
        }

        CustomUserDetails userDetails = new CustomUserDetails(user);
        Authentication authentication = new UsernamePasswordAuthenticationToken(userDetails, null, userDetails.getAuthorities());
        SecurityContextHolder.getContext().setAuthentication(authentication);
    }

    @Test
    void joinVideoSession_asClient_success() {
        // Initialize clientUser for this specific test context if not already done in setUp
        clientUser = new User(); // Ensure clientUser is what's expected for THIS test
        clientUser.setId(1L);
        clientUser.setEmail("client@example.com");
        clientUser.setRole(UserRole.USER);
         // Re-initialize videoSession to use this test-specific clientUser
        professionalUser = new User(); professionalUser.setId(2L); professionalUser.setEmail("prof@example.com"); professionalUser.setRole(UserRole.PROFESSIONAL);
        professional = new Professional(); professional.setId(2L); professional.setUser(professionalUser);
        videoSession = new Session(); videoSession.setId(100L); videoSession.setUser(clientUser); videoSession.setProfessional(professional); videoSession.setMode(SessionMode.VIDEO);


        mockSecurityContext(clientUser, UserRole.USER);
        // videoSession already has zoomMeetingId set in setUp or test-specific setup
        videoSession.setZoomMeetingId("clientZoomSuccess123");
        videoSession.setZoomMeetingPassword("clientPassword456"); // Set password for the session
        professional.setZoomMeetingStartUrl("https://start.example.com/host");


        when(sessionService.getSessionEntityById(videoSession.getId())).thenReturn(videoSession);
        when(zoomService.getSdkKey()).thenReturn("testSdkKey");
        // Use zoomMeetingId from the session object
        when(zoomService.generateSignature(eq(videoSession.getZoomMeetingId()), eq(0))).thenReturn("testSignature");

        ResponseEntity<ZoomSignatureResponse> response = sessionController.joinVideoSession(videoSession.getId());

        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertNotNull(response.getBody());
        assertEquals("testSdkKey", response.getBody().getApiKey());
        assertEquals(videoSession.getZoomMeetingId(), response.getBody().getMeetingNumber()); // Verify zoomMeetingId
        assertEquals("testSignature", response.getBody().getSignature());
        assertEquals("clientPassword456", response.getBody().getPassword()); // Verify password
        assertEquals("https://start.example.com/host", response.getBody().getStartUrl());
        verify(sessionService).getSessionEntityById(videoSession.getId());
        verify(zoomService).generateSignature(eq(videoSession.getZoomMeetingId()), eq(0)); // Verify correct meetingNumber used
    }

    @Test
    void joinVideoSession_asClient_success_nullPassword() {
        // Test case where session password is null
        clientUser = new User();
        clientUser.setId(1L);
        clientUser.setEmail("client@example.com");
        clientUser.setRole(UserRole.USER);
        professionalUser = new User(); professionalUser.setId(2L); professionalUser.setEmail("prof@example.com"); professionalUser.setRole(UserRole.PROFESSIONAL);
        professional = new Professional(); professional.setId(2L); professional.setUser(professionalUser);
        videoSession = new Session(); videoSession.setId(100L); videoSession.setUser(clientUser); videoSession.setProfessional(professional); videoSession.setMode(SessionMode.VIDEO);
        videoSession.setZoomMeetingId("clientZoomNoPass123");
        videoSession.setZoomMeetingPassword(null); // Explicitly null password
        professional.setZoomMeetingStartUrl("https://start.example.com/host");

        mockSecurityContext(clientUser, UserRole.USER);

        when(sessionService.getSessionEntityById(videoSession.getId())).thenReturn(videoSession);
        when(zoomService.getSdkKey()).thenReturn("testSdkKey");
        when(zoomService.generateSignature(eq(videoSession.getZoomMeetingId()), eq(0))).thenReturn("testSignatureNoPass");

        ResponseEntity<ZoomSignatureResponse> response = sessionController.joinVideoSession(videoSession.getId());

        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertNotNull(response.getBody());
        assertEquals("testSdkKey", response.getBody().getApiKey());
        assertEquals("clientZoomNoPass123", response.getBody().getMeetingNumber());
        assertEquals("testSignatureNoPass", response.getBody().getSignature());
        assertNull(response.getBody().getPassword(), "Password should be null in response"); // Verify password is null
        assertEquals("https://start.example.com/host", response.getBody().getStartUrl());
    }

    @Test
    void joinVideoSession_asProfessional_success() {
        // Initialize professionalUser for this specific test context
        professionalUser = new User(); // Ensure professionalUser is what's expected for THIS test
        professionalUser.setId(2L);
        professionalUser.setEmail("prof@example.com");
        professionalUser.setRole(UserRole.PROFESSIONAL);
        clientUser = new User(); clientUser.setId(1L); clientUser.setEmail("client@example.com"); clientUser.setRole(UserRole.USER);
        professional = new Professional(); professional.setId(2L); professional.setUser(professionalUser);
        videoSession = new Session(); videoSession.setId(100L); videoSession.setUser(clientUser); videoSession.setProfessional(professional); videoSession.setMode(SessionMode.VIDEO);

        mockSecurityContext(professionalUser, UserRole.PROFESSIONAL);
        // videoSession already has zoomMeetingId set in setUp or test-specific setup
        videoSession.setZoomMeetingId("profZoomSuccess456");
        videoSession.setZoomMeetingPassword("profPassword789"); // Set password for the session
        professional.setZoomMeetingStartUrl("https://start.example.com/prof");


        when(sessionService.getSessionEntityById(videoSession.getId())).thenReturn(videoSession);
        when(zoomService.getSdkKey()).thenReturn("testSdkKey");
        // Use zoomMeetingId from the session object
        when(zoomService.generateSignature(eq(videoSession.getZoomMeetingId()), eq(1))).thenReturn("testSignatureProf");

        ResponseEntity<ZoomSignatureResponse> response = sessionController.joinVideoSession(videoSession.getId());

        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertNotNull(response.getBody());
        assertEquals("testSdkKey", response.getBody().getApiKey());
        assertEquals(videoSession.getZoomMeetingId(), response.getBody().getMeetingNumber()); // Verify zoomMeetingId
        assertEquals("testSignatureProf", response.getBody().getSignature());
        assertEquals("profPassword789", response.getBody().getPassword()); // Verify password
        assertEquals("https://start.example.com/prof", response.getBody().getStartUrl());
        verify(sessionService).getSessionEntityById(videoSession.getId());
        verify(zoomService).generateSignature(eq(videoSession.getZoomMeetingId()), eq(1)); // Verify correct meetingNumber used
    }

    @Test
    void joinVideoSession_nullZoomMeetingId_throwsBadRequest() {
        clientUser = new User(); clientUser.setId(1L); clientUser.setEmail("client@example.com"); clientUser.setRole(UserRole.USER);
        professionalUser = new User(); professionalUser.setId(2L); professionalUser.setEmail("prof@example.com"); professionalUser.setRole(UserRole.PROFESSIONAL);
        professional = new Professional(); professional.setId(2L); professional.setUser(professionalUser);

        videoSession = new Session();
        videoSession.setId(100L);
        videoSession.setUser(clientUser);
        videoSession.setProfessional(professional);
        videoSession.setMode(SessionMode.VIDEO);
        videoSession.setZoomMeetingId(null); // Explicitly set to null

        mockSecurityContext(clientUser, UserRole.USER);

        when(sessionService.getSessionEntityById(videoSession.getId())).thenReturn(videoSession);

        ResponseStatusException exception = assertThrows(ResponseStatusException.class, () -> {
            sessionController.joinVideoSession(videoSession.getId());
        });

        assertEquals(HttpStatus.BAD_REQUEST, exception.getStatusCode());
        assertTrue(exception.getReason().contains("Zoom Meeting ID is missing for this session"));
        verify(sessionService).getSessionEntityById(videoSession.getId());
        // verify(zoomService, never()).generateSignature(anyString(), anyInt()); // Ensure signature generation was not attempted
    }

    @Test
    void joinVideoSession_sessionNotFound() {
        clientUser = new User(); clientUser.setId(1L); clientUser.setEmail("client@example.com"); clientUser.setRole(UserRole.USER);
        mockSecurityContext(clientUser, UserRole.USER);
        // Ensure getSessionEntityById is mocked for this path
        when(sessionService.getSessionEntityById(anyLong())).thenThrow(new ResponseStatusException(HttpStatus.NOT_FOUND, "Session not found"));

        ResponseStatusException exception = assertThrows(ResponseStatusException.class, () -> {
            sessionController.joinVideoSession(999L);
        });
        assertEquals(HttpStatus.NOT_FOUND, exception.getStatusCode());
        verify(sessionService).getSessionEntityById(999L);
    }

    @Test
    void joinVideoSession_notVideoSession() {
        clientUser = new User(); clientUser.setId(1L); clientUser.setEmail("client@example.com"); clientUser.setRole(UserRole.USER);
        professionalUser = new User(); professionalUser.setId(2L); professionalUser.setEmail("prof@example.com"); professionalUser.setRole(UserRole.PROFESSIONAL);
        professional = new Professional(); professional.setId(2L); professional.setUser(professionalUser);
        mockSecurityContext(clientUser, UserRole.USER);

        Session chatSession = new Session();
        chatSession.setId(101L);
        chatSession.setUser(clientUser);
        chatSession.setProfessional(professional);
        chatSession.setMode(SessionMode.CHAT); // Not a video session

        // SessionDTO chatSessionDTO = new SessionDTO(); // DTO not needed for this path anymore
        // chatSessionDTO.setId(101L);
        // chatSessionDTO.setMode(SessionMode.CHAT);

        when(sessionService.getSessionEntityById(chatSession.getId())).thenReturn(chatSession); // Mock new service method

        ResponseStatusException exception = assertThrows(ResponseStatusException.class, () -> {
            sessionController.joinVideoSession(chatSession.getId());
        });
        assertEquals(HttpStatus.BAD_REQUEST, exception.getStatusCode());
        assertTrue(exception.getReason().contains("Session is not a video session"));
        verify(sessionService).getSessionEntityById(chatSession.getId());
    }

    @Test
    void joinVideoSession_userNotPartOfSession() {
        clientUser = new User(); clientUser.setId(1L); clientUser.setEmail("client@example.com"); clientUser.setRole(UserRole.USER);
        professionalUser = new User(); professionalUser.setId(2L); professionalUser.setEmail("prof@example.com"); professionalUser.setRole(UserRole.PROFESSIONAL);
        professional = new Professional(); professional.setId(2L); professional.setUser(professionalUser);
        videoSession = new Session(); videoSession.setId(100L); videoSession.setUser(clientUser); videoSession.setProfessional(professional); videoSession.setMode(SessionMode.VIDEO);

        User otherUser = new User();
        otherUser.setId(3L);
        otherUser.setRole(UserRole.USER);
        otherUser.setEmail("other@example.com");
        mockSecurityContext(otherUser, UserRole.USER); // Authenticated as a different user

        when(sessionService.getSessionEntityById(videoSession.getId())).thenReturn(videoSession); // Mock new service method

        ResponseStatusException exception = assertThrows(ResponseStatusException.class, () -> {
            sessionController.joinVideoSession(videoSession.getId());
        });
        assertEquals(HttpStatus.FORBIDDEN, exception.getStatusCode());
        assertTrue(exception.getReason().contains("User not part of this session"));
        verify(sessionService).getSessionEntityById(videoSession.getId());
    }

    @Test
    void joinVideoSession_unauthenticatedUser() {
        SecurityContextHolder.getContext().setAuthentication(null); // Simulate unauthenticated
        // videoSession might not be fully initialized here if setUp relies on other mocks that aren't called
        // However, the primary check here is for authentication, which happens before session loading.
        // For robustness, ensure videoSession.getId() is valid if any preliminary controller logic uses it,
        // though for this specific test, it might not be strictly necessary if authentication check is early.
        // Let's assume videoSession.getId() is called for consistency in the controller method signature.
        // We can use a default ID like 100L as used elsewhere.
        final Long testSessionId = 100L;


        // Note: @PreAuthorize might handle this before method execution,
        // leading to a Spring Security exception rather than our ResponseStatusException.
        // However, the internal check is also good defense-in-depth.
        // For this test, we'll assume it reaches our controller logic for the null check.
        // If Spring Security's filter chain denies access earlier, this specific test might fail
        // or need to be adapted to expect AccessDeniedException or similar.

        // The controller code itself throws ResponseStatusException if auth is null or principal isn't CustomUserDetails
        ResponseStatusException exception = assertThrows(ResponseStatusException.class, () -> {
             sessionController.joinVideoSession(testSessionId); // Use testSessionId
        });
        assertEquals(HttpStatus.UNAUTHORIZED, exception.getStatusCode());
    }
}
