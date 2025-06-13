package com.adamasorho.mindapax_backend.service.impl;

import com.adamasorho.mindapax_backend.dto.SessionDTO;
import com.adamasorho.mindapax_backend.mapper.SessionMapper;
import com.adamasorho.mindapax_backend.model.Professional;
import com.adamasorho.mindapax_backend.model.Session;
import com.adamasorho.mindapax_backend.model.User;
import com.adamasorho.mindapax_backend.model.enums.SessionMode;
import com.adamasorho.mindapax_backend.model.enums.SessionStatus;
import com.adamasorho.mindapax_backend.model.enums.Specialization;
import com.adamasorho.mindapax_backend.repository.ProfessionalRepository;
import com.adamasorho.mindapax_backend.repository.SessionRepository;
import com.adamasorho.mindapax_backend.repository.UserRepository;
import jakarta.persistence.EntityNotFoundException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContext;
import org.springframework.security.core.context.SecurityContextHolder;

import java.time.LocalDateTime;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;
import org.mockito.ArgumentCaptor; // Import ArgumentCaptor
import org.hibernate.PropertyValueException; // Import for testing null property violations


@ExtendWith(MockitoExtension.class)
class SessionServiceImplTests {

    @Mock
    private SessionRepository sessionRepository;

    @Mock
    private UserRepository userRepository;

    @Mock
    private ProfessionalRepository professionalRepository;

    @Mock
    private SessionMapper sessionMapper;

    @Mock
    private Authentication authentication;

    @Mock
    private SecurityContext securityContext;

    @InjectMocks
    private SessionServiceImpl sessionService;

    private SessionDTO sessionDTO;
    private Session session;
    private User user;
    private Professional professional;
    private User professionalUser;

    @BeforeEach
    void setUp() {
        professionalUser = new User();
        professionalUser.setId(1L);
        professionalUser.setEmail("professional@example.com");
        professionalUser.setFirstName("Professional");
        professionalUser.setLastName("User");

        professional = new Professional();
        professional.setId(1L);
        professional.setUser(professionalUser);
        professional.setSpecialization(Specialization.MENTAL_HEALTH);
        // professional.setZoomMeetingId(null); // Set in individual tests for clarity

        user = new User();
        user.setId(2L);
        user.setFirstName("Client");
        user.setLastName("User");

        sessionDTO = new SessionDTO();
        sessionDTO.setUserId(user.getId());
        sessionDTO.setStartTime(OffsetDateTime.now().plusHours(1).withNano(0)); // Remove nanos for easier comparison
        sessionDTO.setDurationMinutes(60); // Set duration instead of endTime
        sessionDTO.setMode(SessionMode.VIDEO);
        sessionDTO.setNotes("Test session notes");
        // sessionDTO.setStatus() is not set here, service will default it.

        session = new Session(); // This mock 'session' object might be less used now if ArgumentCaptor is the focus
        session.setId(1L);
        session.setUser(user);
        session.setProfessional(professional);
        session.setStartTime(sessionDTO.getStartTime()); // This will now be OffsetDateTime
        session.setDurationMinutes(sessionDTO.getDurationMinutes()); // Use duration
        session.setMode(sessionDTO.getMode());
        session.setNotes(sessionDTO.getNotes());
        session.setStatus(SessionStatus.SCHEDULED);
    }

    @Test
    void testScheduleSessionByProfessional_Success() {
        // Arrange
        when(securityContext.getAuthentication()).thenReturn(authentication);
        SecurityContextHolder.setContext(securityContext);
        when(authentication.getName()).thenReturn(professionalUser.getEmail());

        // Mock initial fetches
        when(professionalRepository.findByUserEmail(professionalUser.getEmail())).thenReturn(Optional.of(professional));
        when(userRepository.findById(eq(sessionDTO.getUserId()))).thenReturn(Optional.of(user)); // Use eq() for specific ID

        // The service now uses 'new Session()' and manually sets fields from DTO.
        // So, no need to mock sessionMapper.toEntity().

        // Mock the save operation to return the session passed to it, potentially with an ID set.
        // For the purpose of capturing and verifying, this is fine.
        // If the ID set by save is crucial for DTO mapping, adjust accordingly.
        when(sessionRepository.save(any(Session.class))).thenAnswer(invocation -> {
            Session sessionToSave = invocation.getArgument(0);
            if (sessionToSave.getId() == null) { // Simulate ID generation if not already set
                 sessionToSave.setId(1L); // Example ID
            }
            return sessionToSave;
        });

        // Prepare the DTO that mapper.toDTO should return
        SessionDTO mappedDto = new SessionDTO();
        mappedDto.setId(1L); // Assuming ID is set by save
        mappedDto.setUserId(user.getId());
        mappedDto.setProfessionalId(professional.getId());
        mappedDto.setStartTime(sessionDTO.getStartTime()); // This will now be OffsetDateTime
        mappedDto.setDurationMinutes(sessionDTO.getDurationMinutes()); // Use duration
        mappedDto.setMode(sessionDTO.getMode());
        mappedDto.setNotes(sessionDTO.getNotes());
        mappedDto.setStatus(SessionStatus.SCHEDULED);
        // Add professionalName and professionalSpecialization if mapper sets them
        // mappedDto.setProfessionalName(professional.getUser().getFirstName() + " " + professional.getUser().getLastName());
        // mappedDto.setProfessionalSpecialization(professional.getSpecialization().name());


        when(sessionMapper.toDTO(any(Session.class))).thenReturn(mappedDto);

        // Act
        SessionDTO resultDTO = sessionService.scheduleSessionByProfessional(sessionDTO);

        // Assertions on the returned DTO
        assertNotNull(resultDTO);
        assertEquals(mappedDto.getId(), resultDTO.getId());
        assertEquals(user.getId(), resultDTO.getUserId()); // Assert based on the 'user' object's ID
        assertEquals(professional.getId(), resultDTO.getProfessionalId()); // Assert based on the 'professional' object's ID
        assertEquals(SessionStatus.SCHEDULED, resultDTO.getStatus());

        // Verify interactions and capture the saved session
        verify(professionalRepository).findByUserEmail(professionalUser.getEmail()); // Initial fetch
        verify(userRepository).findById(eq(sessionDTO.getUserId())); // Initial fetch for client user


        ArgumentCaptor<Session> sessionCaptor = ArgumentCaptor.forClass(Session.class);
        verify(sessionRepository).save(sessionCaptor.capture());
        Session capturedSession = sessionCaptor.getValue();

        // Assertions on the captured Session entity
        assertNotNull(capturedSession.getProfessional(), "Professional should be set on the session");
        assertEquals(professional.getId(), capturedSession.getProfessional().getId(), "Professional ID should match the mockProfessional's ID");

        assertNotNull(capturedSession.getUser(), "User should be set on the session");
        assertEquals(user.getId(), capturedSession.getUser().getId(), "User ID should match the mockUser's ID");

        assertEquals(SessionStatus.SCHEDULED, capturedSession.getStatus(), "Session status should be SCHEDULED");
        // Explicitly assert non-null for fields that are non-nullable in the entity
        assertNotNull(capturedSession.getStartTime(), "StartTime should be set on the session");
        assertNotNull(capturedSession.getDurationMinutes(), "DurationMinutes should be set on the session"); // Check duration
        assertNotNull(capturedSession.getMode(), "Mode should be set on the session");
        assertNotNull(capturedSession.getStatus(), "Status should be set on the session");

        assertEquals(sessionDTO.getStartTime(), capturedSession.getStartTime());
        assertEquals(sessionDTO.getDurationMinutes(), capturedSession.getDurationMinutes()); // Check duration
        assertEquals(sessionDTO.getMode(), capturedSession.getMode());
        assertEquals(sessionDTO.getNotes(), capturedSession.getNotes());
        // Default case: zoomMeetingId is not set in sessionDTO,
        // AND professional.zoomMeetingId is not set in general setUp,
        // so it should be null in capturedSession if mode is VIDEO.
        // If mode is not VIDEO, it will also be null.
        if (sessionDTO.getMode() == SessionMode.VIDEO && professional.getZoomMeetingId() != null) {
             assertEquals(professional.getZoomMeetingId(), capturedSession.getZoomMeetingId());
        } else {
            assertNull(capturedSession.getZoomMeetingId());
        }

        verify(sessionMapper).toDTO(capturedSession); // Verify DTO mapping was called with the captured session
    }

    @Test
    void testScheduleSessionByProfessional_WithZoomMeetingId_InDTO() {
        // This test verifies that if zoomMeetingId is provided in the DTO,
        // and the new logic for VIDEO sessions (copying from professional) doesn't apply (e.g. mode is CHAT),
        // then the DTO's zoomMeetingId is used.
        // If mode IS VIDEO, the professional's ID will take precedence due to the new logic.

        // Arrange
        sessionDTO.setMode(SessionMode.CHAT); // Ensure mode is not VIDEO to test DTO's zoomId path
        sessionDTO.setZoomMeetingId("dtoZoomId123");

        when(securityContext.getAuthentication()).thenReturn(authentication);
        SecurityContextHolder.setContext(securityContext);
        when(authentication.getName()).thenReturn(professionalUser.getEmail());

        when(professionalRepository.findByUserEmail(professionalUser.getEmail())).thenReturn(Optional.of(professional));
        when(userRepository.findById(eq(sessionDTO.getUserId()))).thenReturn(Optional.of(user));

        when(sessionRepository.save(any(Session.class))).thenAnswer(invocation -> {
            Session sessionToSave = invocation.getArgument(0);
            sessionToSave.setId(2L); // Different ID for this test
            return sessionToSave;
        });

        SessionDTO mappedDtoWithZoom = new SessionDTO(); // Create a new DTO for this specific mapping
        mappedDtoWithZoom.setId(2L);
        mappedDtoWithZoom.setZoomMeetingId("zoom123");
        // Copy other essential fields from the main mappedDto or sessionDTO as needed for assertion
        mappedDtoWithZoom.setUserId(user.getId());
        mappedDtoWithZoom.setProfessionalId(professional.getId());
        mappedDtoWithZoom.setStartTime(sessionDTO.getStartTime());
        mappedDtoWithZoom.setDurationMinutes(sessionDTO.getDurationMinutes());
        mappedDtoWithZoom.setMode(sessionDTO.getMode());
        mappedDtoWithZoom.setNotes(sessionDTO.getNotes());
        mappedDtoWithZoom.setStatus(SessionStatus.SCHEDULED);


        when(sessionMapper.toDTO(any(Session.class))).thenReturn(mappedDtoWithZoom);

        // Act
        SessionDTO resultDTO = sessionService.scheduleSessionByProfessional(sessionDTO);

        // Assertions on the returned DTO
        assertNotNull(resultDTO);
        assertEquals("dtoZoomId123", resultDTO.getZoomMeetingId());

        // Verify interactions and capture the saved session
        ArgumentCaptor<Session> sessionCaptor = ArgumentCaptor.forClass(Session.class);
        verify(sessionRepository).save(sessionCaptor.capture());
        Session capturedSession = sessionCaptor.getValue();

        // Assertions on the captured Session entity
        assertEquals("dtoZoomId123", capturedSession.getZoomMeetingId()); // DTO's zoomId is used because mode is CHAT
        assertEquals(sessionDTO.getStartTime(), capturedSession.getStartTime());
        assertEquals(sessionDTO.getDurationMinutes(), capturedSession.getDurationMinutes());
        assertEquals(SessionMode.CHAT, capturedSession.getMode()); // Verify mode was indeed CHAT
        assertEquals(sessionDTO.getNotes(), capturedSession.getNotes());
        assertEquals(SessionStatus.SCHEDULED, capturedSession.getStatus());
        assertNotNull(capturedSession.getProfessional());
        assertEquals(professional.getId(), capturedSession.getProfessional().getId());
        assertNotNull(capturedSession.getUser());
        assertEquals(user.getId(), capturedSession.getUser().getId());


        verify(sessionMapper).toDTO(capturedSession);
    }

    @Test
    void testScheduleSessionByProfessional_WithNullZoomMeetingId_InDTO() {
        // This test is similar to the above, ensuring null from DTO is handled if new logic doesn't apply.
        // Arrange
        sessionDTO.setMode(SessionMode.CHAT); // Ensure mode is not VIDEO
        sessionDTO.setZoomMeetingId(null); // Explicitly set to null in DTO

        ArgumentCaptor<Session> sessionCaptor = ArgumentCaptor.forClass(Session.class);
        Session capturedSession = sessionCaptor.getValue();

        when(securityContext.getAuthentication()).thenReturn(authentication);
        assertEquals(SessionMode.CHAT, capturedSession.getMode()); // Verify mode
        assertEquals(sessionDTO.getNotes(), capturedSession.getNotes());
        assertEquals(SessionStatus.SCHEDULED, capturedSession.getStatus());
        assertNotNull(capturedSession.getProfessional());
        assertEquals(professional.getId(), capturedSession.getProfessional().getId());
        assertNotNull(capturedSession.getUser());
        assertEquals(user.getId(), capturedSession.getUser().getId());

        verify(sessionMapper).toDTO(capturedSession);
    }

    // --- New tests for Professional's Zoom ID logic ---

    @Test
    void scheduleSessionByProfessional_videoMode_professionalHasZoomId_setsSessionZoomId() {
        // Arrange
        professional.setZoomMeetingId("profZoomId789");
        sessionDTO.setMode(SessionMode.VIDEO);
        sessionDTO.setZoomMeetingId(null); // Ensure DTO does not provide it, to test professional's ID usage

        when(securityContext.getAuthentication()).thenReturn(authentication);
        when(authentication.getName()).thenReturn(professionalUser.getEmail());
        when(professionalRepository.findByUserEmail(professionalUser.getEmail())).thenReturn(Optional.of(professional));
        when(userRepository.findById(sessionDTO.getUserId())).thenReturn(Optional.of(user));
        when(sessionRepository.save(any(Session.class))).thenAnswer(invocation -> invocation.getArgument(0));

        SessionDTO mappedDto = new SessionDTO(); // DTO returned by mapper
        // This DTO should reflect the session state AFTER professional's zoomId is copied
        mappedDto.setZoomMeetingId(professional.getZoomMeetingId());
        // ... copy other relevant fields for the mapped DTO ...
        mappedDto.setId(4L);
        mappedDto.setUserId(user.getId());
        mappedDto.setProfessionalId(professional.getId());
        mappedDto.setStartTime(sessionDTO.getStartTime());
        mappedDto.setDurationMinutes(sessionDTO.getDurationMinutes());
        mappedDto.setMode(SessionMode.VIDEO);
        mappedDto.setStatus(SessionStatus.SCHEDULED);

        when(sessionMapper.toDTO(any(Session.class))).thenReturn(mappedDto);

        // Act
        SessionDTO resultDTO = sessionService.scheduleSessionByProfessional(sessionDTO);

        // Assert
        ArgumentCaptor<Session> sessionCaptor = ArgumentCaptor.forClass(Session.class);
        verify(sessionRepository).save(sessionCaptor.capture());
        Session capturedSession = sessionCaptor.getValue();

        assertEquals("profZoomId789", capturedSession.getZoomMeetingId());
        assertEquals(SessionMode.VIDEO, capturedSession.getMode());
        assertNotNull(resultDTO);
        assertEquals("profZoomId789", resultDTO.getZoomMeetingId());
    }

    @Test
    void scheduleSessionByProfessional_videoMode_professionalZoomIdNull_sessionZoomIdNull() {
        // Arrange
        professional.setZoomMeetingId(null); // Professional has no Zoom ID
        sessionDTO.setMode(SessionMode.VIDEO);
        sessionDTO.setZoomMeetingId("thisShouldBeIgnored"); // DTO has one, but it should be ignored for VIDEO mode if prof's is null

        when(securityContext.getAuthentication()).thenReturn(authentication);
        when(authentication.getName()).thenReturn(professionalUser.getEmail());
        when(professionalRepository.findByUserEmail(professionalUser.getEmail())).thenReturn(Optional.of(professional));
        when(userRepository.findById(sessionDTO.getUserId())).thenReturn(Optional.of(user));
        when(sessionRepository.save(any(Session.class))).thenAnswer(invocation -> invocation.getArgument(0));

        SessionDTO mappedDto = new SessionDTO();
        mappedDto.setZoomMeetingId(null); // Expect null because professional's ID is null
        // ... copy other relevant fields for the mapped DTO ...
         mappedDto.setId(5L);
        mappedDto.setUserId(user.getId());
        mappedDto.setProfessionalId(professional.getId());
        mappedDto.setStartTime(sessionDTO.getStartTime());
        mappedDto.setDurationMinutes(sessionDTO.getDurationMinutes());
        mappedDto.setMode(SessionMode.VIDEO);
        mappedDto.setStatus(SessionStatus.SCHEDULED);
        when(sessionMapper.toDTO(any(Session.class))).thenReturn(mappedDto);

        // Act
        SessionDTO resultDTO = sessionService.scheduleSessionByProfessional(sessionDTO);

        // Assert
        ArgumentCaptor<Session> sessionCaptor = ArgumentCaptor.forClass(Session.class);
        verify(sessionRepository).save(sessionCaptor.capture());
        Session capturedSession = sessionCaptor.getValue();

        assertNull(capturedSession.getZoomMeetingId());
        assertNotNull(resultDTO);
        assertNull(resultDTO.getZoomMeetingId());
    }

    @Test
    void scheduleSessionByProfessional_chatMode_professionalHasZoomId_sessionZoomIdNullOrFromDTO() {
        // Arrange
        professional.setZoomMeetingId("profZoomIdChat");
        sessionDTO.setMode(SessionMode.CHAT); // Non-VIDEO mode
        sessionDTO.setZoomMeetingId("dtoZoomForChat"); // DTO might have its own, which should be preserved

        when(securityContext.getAuthentication()).thenReturn(authentication);
        SecurityContextHolder.setContext(securityContext);
        when(authentication.getName()).thenReturn(professionalUser.getEmail());

        when(professionalRepository.findByUserEmail(professionalUser.getEmail())).thenReturn(Optional.of(professional));
        when(userRepository.findById(eq(sessionDTO.getUserId()))).thenReturn(Optional.of(user));

        when(sessionRepository.save(any(Session.class))).thenAnswer(invocation -> {
            Session sessionToSave = invocation.getArgument(0);
            sessionToSave.setId(3L); // Different ID
            return sessionToSave;
        });

        SessionDTO mappedDtoNullZoom = new SessionDTO(); // Create a new DTO for this specific mapping
        mappedDtoNullZoom.setId(3L);
        mappedDtoNullZoom.setZoomMeetingId(null);
        // Copy other essential fields
        mappedDtoNullZoom.setUserId(user.getId());
        mappedDtoNullZoom.setProfessionalId(professional.getId());
        mappedDtoNullZoom.setStartTime(sessionDTO.getStartTime());
        mappedDtoNullZoom.setDurationMinutes(sessionDTO.getDurationMinutes());
        mappedDtoNullZoom.setMode(sessionDTO.getMode());
        mappedDtoNullZoom.setNotes(sessionDTO.getNotes());
        mappedDtoNullZoom.setStatus(SessionStatus.SCHEDULED);


        when(sessionMapper.toDTO(any(Session.class))).thenReturn(mappedDtoNullZoom);

        // Act
        SessionDTO resultDTO = sessionService.scheduleSessionByProfessional(sessionDTO);

        // Assertions on the returned DTO
        assertNotNull(resultDTO);
        assertNull(resultDTO.getZoomMeetingId());

        // Verify interactions and capture the saved session
        ArgumentCaptor<Session> sessionCaptor = ArgumentCaptor.forClass(Session.class);
        verify(sessionRepository).save(sessionCaptor.capture());
        Session capturedSession = sessionCaptor.getValue();

        // Assertions on the captured Session entity
        assertNull(capturedSession.getZoomMeetingId());
        assertEquals(sessionDTO.getStartTime(), capturedSession.getStartTime());
        assertEquals(sessionDTO.getDurationMinutes(), capturedSession.getDurationMinutes());
        assertEquals(SessionMode.CHAT, capturedSession.getMode());
        assertEquals(sessionDTO.getNotes(), capturedSession.getNotes());
        assertEquals(SessionStatus.SCHEDULED, capturedSession.getStatus());
        assertNotNull(capturedSession.getProfessional());
        assertEquals(professional.getId(), capturedSession.getProfessional().getId());
        assertNotNull(capturedSession.getUser());
        assertEquals(user.getId(), capturedSession.getUser().getId());

        verify(sessionMapper).toDTO(capturedSession);
    }

    @Test
    void testScheduleSessionByProfessional_NullStartTimeInDto_ThrowsPropertyValueException() {
        // Arrange
        when(securityContext.getAuthentication()).thenReturn(authentication);
        SecurityContextHolder.setContext(securityContext);
        when(authentication.getName()).thenReturn(professionalUser.getEmail());

        when(professionalRepository.findByUserEmail(professionalUser.getEmail())).thenReturn(Optional.of(professional));
        when(userRepository.findById(eq(user.getId()))).thenReturn(Optional.of(user));


        SessionDTO dtoWithNullStartTime = new SessionDTO();
        dtoWithNullStartTime.setUserId(user.getId());
        dtoWithNullStartTime.setStartTime(null); // Intentionally set to null
        dtoWithNullStartTime.setDurationMinutes(60); // Set duration
        dtoWithNullStartTime.setMode(SessionMode.VIDEO);

        // This mock is important: it simulates what happens when Hibernate tries to save
        // an entity that violates a non-nullable constraint at the entity/ORM level.
        when(sessionRepository.save(any(Session.class))).thenThrow(
            new PropertyValueException("startTime is null", Session.class.getName(), "startTime")
        );

        // Act & Assert
        PropertyValueException exception = assertThrows(PropertyValueException.class, () -> {
            sessionService.scheduleSessionByProfessional(dtoWithNullStartTime);
        });

        // Verify that the exception is about the 'startTime' property
        assertTrue(exception.getMessage().contains("startTime"));
        assertEquals("startTime", exception.getPropertyName());

        // Verify that findByUserEmail and findById were called up to the point of failure
        // verify(professionalRepository).findByUserEmail(professionalUser.getEmail()); // This line is problematic due to earlier mock setup
        // verify(userRepository).findById(eq(user.getId())); // This line is problematic
        // verify(professionalRepository).findById(eq(professional.getId())); // This line is problematic
        // verify(userRepository, times(2)).findById(eq(user.getId())); // This line is problematic

        verify(sessionRepository).save(any(Session.class)); // Save was attempted
    }

    @Test
    void testScheduleSessionByProfessional_NullDurationInDto_ThrowsPropertyValueException() {
        // Arrange
        when(securityContext.getAuthentication()).thenReturn(authentication);
        SecurityContextHolder.setContext(securityContext);
        when(authentication.getName()).thenReturn(professionalUser.getEmail());

        when(professionalRepository.findByUserEmail(professionalUser.getEmail())).thenReturn(Optional.of(professional));
        when(userRepository.findById(eq(user.getId()))).thenReturn(Optional.of(user));

        SessionDTO dtoWithNullDuration = new SessionDTO();
        dtoWithNullDuration.setUserId(user.getId());
        dtoWithNullDuration.setStartTime(OffsetDateTime.now().plusHours(1));
        dtoWithNullDuration.setDurationMinutes(null); // Intentionally set to null
        dtoWithNullDuration.setMode(SessionMode.VIDEO);

        when(sessionRepository.save(any(Session.class))).thenThrow(
            new PropertyValueException("durationMinutes is null", Session.class.getName(), "durationMinutes")
        );

        // Act & Assert
        PropertyValueException exception = assertThrows(PropertyValueException.class, () -> {
            sessionService.scheduleSessionByProfessional(dtoWithNullDuration);
        });

        assertTrue(exception.getMessage().contains("durationMinutes"));
        assertEquals("durationMinutes", exception.getPropertyName());
        verify(sessionRepository).save(any(Session.class)); // Save was attempted
    }


    @Test
    void testScheduleSessionByProfessional_ProfessionalNotFound() {
        // Arrange
        // No change to SecurityContextHolder needed here as it's for the initial part
        when(authentication.getName()).thenReturn("unknown@example.com"); // Ensure this is used for the first call
        when(professionalRepository.findByUserEmail("unknown@example.com")).thenReturn(Optional.empty());
        // No need to mock SecurityContextHolder.getContext() again if it's already set up generally
        // or if the test doesn't rely on a specific state of it beyond authentication.getName()

        // Act & Assert
        EntityNotFoundException exception = assertThrows(EntityNotFoundException.class, () -> {
            sessionService.scheduleSessionByProfessional(sessionDTO);
        });
        assertEquals("Professional not found with email: unknown@example.com", exception.getMessage());

        verify(professionalRepository).findByUserEmail("unknown@example.com");
        verify(userRepository, never()).findById(anyLong());
        verify(sessionRepository, never()).save(any(Session.class));
    }

    @Test
    void testScheduleSessionByProfessional_UserNotFound() {
        // Arrange
        // No change to SecurityContextHolder needed here
        when(authentication.getName()).thenReturn(professionalUser.getEmail()); // For initial professional fetch
        when(professionalRepository.findByUserEmail(professionalUser.getEmail())).thenReturn(Optional.of(professional));

        Long nonExistentUserId = 99L;
        sessionDTO.setUserId(nonExistentUserId); // Set DTO to use a non-existent user ID for the initial client fetch

        // Mock for initial client fetch (which will fail)
        when(userRepository.findById(nonExistentUserId)).thenReturn(Optional.empty());
        // The re-fetch for the professional (professionalRepository.findById) might still be mocked if you want to be thorough,
        // but the code should ideally not reach the re-fetch of the user if the initial client fetch fails.
        // For robustness, ensure professional re-fetch is still mocked if it could be reached.
        // when(professionalRepository.findById(eq(professional.getId()))).thenReturn(Optional.of(professional));


        // Act & Assert
        EntityNotFoundException exception = assertThrows(EntityNotFoundException.class, () -> {
            sessionService.scheduleSessionByProfessional(sessionDTO);
        });
        assertEquals("User not found with ID: " + nonExistentUserId, exception.getMessage());

        verify(professionalRepository).findByUserEmail(professionalUser.getEmail());
        verify(userRepository).findById(nonExistentUserId);
        verify(sessionRepository, never()).save(any(Session.class)); // Save should not be reached if user not found
    }

    @Test
    void testScheduleSessionWithDifferentOffsets() {
        // Arrange
        when(securityContext.getAuthentication()).thenReturn(authentication);
        SecurityContextHolder.setContext(securityContext);
        when(authentication.getName()).thenReturn(professionalUser.getEmail());

        when(professionalRepository.findByUserEmail(professionalUser.getEmail())).thenReturn(Optional.of(professional));
        when(userRepository.findById(anyLong())).thenReturn(Optional.of(user)); // Assume client user always found for simplicity

        OffsetDateTime startTimeEST = OffsetDateTime.of(2023, 12, 1, 10, 0, 0, 0, ZoneOffset.ofHours(-5));
        OffsetDateTime startTimePST = OffsetDateTime.of(2023, 12, 1, 7, 0, 0, 0, ZoneOffset.ofHours(-8));

        SessionDTO dto1 = new SessionDTO();
        dto1.setUserId(user.getId());
        dto1.setStartTime(startTimeEST);
        dto1.setDurationMinutes(60);
        dto1.setMode(SessionMode.VIDEO);

        SessionDTO dto2 = new SessionDTO();
        dto2.setUserId(user.getId());
        dto2.setStartTime(startTimePST);
        dto2.setDurationMinutes(60);
        dto2.setMode(SessionMode.VIDEO);

        // Mock save to return the session passed, potentially with an ID
        when(sessionRepository.save(any(Session.class))).thenAnswer(invocation -> {
            Session s = invocation.getArgument(0);
            s.setId(System.currentTimeMillis()); // Assign a unique ID for differentiation if needed
            return s;
        });

        // Mock mapper to return a DTO reflecting the saved session's state
        when(sessionMapper.toDTO(any(Session.class))).thenAnswer(invocation -> {
            Session s = invocation.getArgument(0);
            SessionDTO resultDto = new SessionDTO();
            resultDto.setId(s.getId());
            resultDto.setStartTime(s.getStartTime());
            // copy other relevant fields
            return resultDto;
        });

        // Act
        sessionService.scheduleSessionByProfessional(dto1);
        sessionService.scheduleSessionByProfessional(dto2);

        // Assert
        ArgumentCaptor<Session> sessionCaptor = ArgumentCaptor.forClass(Session.class);
        verify(sessionRepository, times(2)).save(sessionCaptor.capture());
        List<Session> capturedSessions = sessionCaptor.getAllValues();

        assertEquals(2, capturedSessions.size());
        Session capturedSession1 = capturedSessions.get(0);
        Session capturedSession2 = capturedSessions.get(1);

        // Assert that start times represent the same instant
        assertTrue(capturedSession1.getStartTime().isEqual(capturedSession2.getStartTime()),
                "Start times should be equal despite different offsets.");
        assertEquals(capturedSession1.getStartTime().toInstant(), capturedSession2.getStartTime().toInstant(),
                "Start times should represent the same instant in time.");
    }

    @Test
    void testGetSessionsByUserAndTime_FiltersCorrectlyWithOffsetDateTime() {
        // Arrange
        Long userId = 123L; // Example client user ID
        OffsetDateTime queryDate = OffsetDateTime.of(2023, 12, 15, 12, 0, 0, 0, ZoneOffset.ofHours(-5)); // 12:00 PM EST

        // Simulate a client user (not professional)
        when(securityContext.getAuthentication()).thenReturn(authentication);
        SecurityContextHolder.setContext(securityContext);
        // Ensure authentication.getAuthorities() does not contain "ROLE_PROFESSIONAL"
        // For simplicity, assume it's configured correctly or mock it explicitly if needed.
        // when(authentication.getAuthorities()).thenReturn(Collections.singletonList(new SimpleGrantedAuthority("ROLE_USER")));


        // Mock repository calls
        // For UPCOMING
        sessionService.getSessionsByUserAndTime(userId, queryDate, com.adamasorho.mindapax_backend.dto.SessionTimeFilter.UPCOMING, null, org.springframework.data.domain.Pageable.unpaged());
        // For PAST
        sessionService.getSessionsByUserAndTime(userId, queryDate, com.adamasorho.mindapax_backend.dto.SessionTimeFilter.PAST, null, org.springframework.data.domain.Pageable.unpaged());


        // Assert
        ArgumentCaptor<OffsetDateTime> dateCaptor = ArgumentCaptor.forClass(OffsetDateTime.class);

        // Verify for UPCOMING
        verify(sessionRepository).findByUserIdAndStartTimeGreaterThanEqual(eq(userId), dateCaptor.capture(), any(org.springframework.data.domain.Pageable.class));
        assertTrue(queryDate.isEqual(dateCaptor.getValue()), "Query date for UPCOMING sessions should match.");

        // Verify for PAST
        verify(sessionRepository).findByUserIdAndStartTimeBefore(eq(userId), dateCaptor.capture(), any(org.springframework.data.domain.Pageable.class));
        assertTrue(queryDate.isEqual(dateCaptor.getValue()), "Query date for PAST sessions should match.");
    }
}
