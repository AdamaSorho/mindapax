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

        user = new User();
        user.setId(2L);
        user.setFirstName("Client");
        user.setLastName("User");

        sessionDTO = new SessionDTO();
        sessionDTO.setUserId(user.getId());
        sessionDTO.setStartTime(LocalDateTime.now().plusHours(1).withNano(0)); // Remove nanos for easier comparison
        sessionDTO.setDurationMinutes(60); // Set duration instead of endTime
        sessionDTO.setMode(SessionMode.VIDEO);
        sessionDTO.setNotes("Test session notes");
        // sessionDTO.setStatus() is not set here, service will default it.

        session = new Session(); // This mock 'session' object might be less used now if ArgumentCaptor is the focus
        session.setId(1L);
        session.setUser(user);
        session.setProfessional(professional);
        session.setStartTime(sessionDTO.getStartTime());
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
        mappedDto.setStartTime(sessionDTO.getStartTime());
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

        verify(sessionMapper).toDTO(capturedSession); // Verify DTO mapping was called with the captured session
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
        verify(professionalRepository).findByUserEmail(professionalUser.getEmail());
        verify(userRepository).findById(eq(user.getId()));
        verify(professionalRepository).findById(eq(professional.getId()));
        verify(userRepository, times(2)).findById(eq(user.getId()));

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
        dtoWithNullDuration.setStartTime(LocalDateTime.now().plusHours(1));
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
}
