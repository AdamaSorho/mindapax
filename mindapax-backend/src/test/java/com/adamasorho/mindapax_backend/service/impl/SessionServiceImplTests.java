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
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.*;

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
        sessionDTO.setStartTime(LocalDateTime.now().plusHours(1));
        sessionDTO.setEndTime(LocalDateTime.now().plusHours(2));
        sessionDTO.setMode(SessionMode.VIDEO);
        sessionDTO.setNotes("Test session notes");

        session = new Session();
        session.setId(1L);
        session.setUser(user);
        session.setProfessional(professional);
        session.setStartTime(sessionDTO.getStartTime());
        session.setEndTime(sessionDTO.getEndTime());
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

        when(professionalRepository.findByUserEmail(professionalUser.getEmail())).thenReturn(Optional.of(professional));
        when(userRepository.findById(user.getId())).thenReturn(Optional.of(user));
        when(sessionMapper.toEntity(any(SessionDTO.class))).thenReturn(session); // map DTO to an initial session entity
        when(sessionRepository.save(any(Session.class))).thenReturn(session); // saving sets ID and returns the saved entity
        when(sessionMapper.toDTO(any(Session.class))).thenReturn(sessionDTO); // map final entity back to DTO

        // Act
        SessionDTO resultDTO = sessionService.scheduleSessionByProfessional(sessionDTO);

        // Assert
        assertNotNull(resultDTO);
        assertEquals(sessionDTO.getUserId(), user.getId()); // Check if user ID is correctly set from original DTO
        // In a real scenario, the returned DTO would now also have professionalId, professionalName etc.
        // sessionDTO after mapping might be enriched with IDs and names by the mapper if configured

        verify(professionalRepository).findByUserEmail(professionalUser.getEmail());
        verify(userRepository).findById(user.getId());
        verify(sessionMapper).toEntity(sessionDTO);
        verify(sessionRepository).save(session); // verify that the session passed to save had professional and user set
        assertEquals(SessionStatus.SCHEDULED, session.getStatus()); // Status should be set before save
        assertEquals(professional, session.getProfessional());
        assertEquals(user, session.getUser());
        verify(sessionMapper).toDTO(session);
    }

    @Test
    void testScheduleSessionByProfessional_ProfessionalNotFound() {
        // Arrange
        when(securityContext.getAuthentication()).thenReturn(authentication);
        SecurityContextHolder.setContext(securityContext);
        when(authentication.getName()).thenReturn("unknown@example.com");
        when(professionalRepository.findByUserEmail("unknown@example.com")).thenReturn(Optional.empty());

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
        when(securityContext.getAuthentication()).thenReturn(authentication);
        SecurityContextHolder.setContext(securityContext);
        when(authentication.getName()).thenReturn(professionalUser.getEmail());

        when(professionalRepository.findByUserEmail(professionalUser.getEmail())).thenReturn(Optional.of(professional));
        Long nonExistentUserId = 99L;
        sessionDTO.setUserId(nonExistentUserId); // Set DTO to use a non-existent user ID
        when(userRepository.findById(nonExistentUserId)).thenReturn(Optional.empty());

        // Act & Assert
        EntityNotFoundException exception = assertThrows(EntityNotFoundException.class, () -> {
            sessionService.scheduleSessionByProfessional(sessionDTO);
        });
        assertEquals("User not found with ID: " + nonExistentUserId, exception.getMessage());
        
        verify(professionalRepository).findByUserEmail(professionalUser.getEmail());
        verify(userRepository).findById(nonExistentUserId);
        verify(sessionRepository, never()).save(any(Session.class));
    }
}
