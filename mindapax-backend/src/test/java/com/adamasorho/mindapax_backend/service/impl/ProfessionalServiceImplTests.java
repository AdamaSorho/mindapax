package com.adamasorho.mindapax_backend.service.impl;

import com.adamasorho.mindapax_backend.dto.UserDTO;
import com.adamasorho.mindapax_backend.mapper.UserMapper;
import com.adamasorho.mindapax_backend.model.Connection;
import com.adamasorho.mindapax_backend.model.Professional;
import com.adamasorho.mindapax_backend.model.User;
import com.adamasorho.mindapax_backend.model.enums.ConnectionStatus;
import com.adamasorho.mindapax_backend.repository.ConnectionRepository;
import com.adamasorho.mindapax_backend.repository.ProfessionalRepository;
import jakarta.persistence.EntityNotFoundException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;

import java.util.Collections;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class ProfessionalServiceImplTests {

    @Mock
    private ProfessionalRepository professionalRepository;

    @Mock
    private ConnectionRepository connectionRepository;

    @Mock
    private UserMapper userMapper;

    @Mock // Added ZoomService mock
    private ZoomService zoomService;

    @InjectMocks
    private ProfessionalServiceImpl professionalService;

    private Professional professional;
    private User professionalUser; // Added for professional's user details
    private User connectedUser1;
    private UserDTO connectedUserDTO1;
    private Connection connection1;
    private Pageable pageable;

    @BeforeEach
    void setUp() {
        professionalUser = new User(); // Initialize professional's user
        professionalUser.setId(1L);
        professionalUser.setFirstName("Test");
        professionalUser.setLastName("Professional");

        professional = new Professional();
        professional.setId(1L);
        professional.setUser(professionalUser); // Set user for professional
        professional.setStatus(com.adamasorho.mindapax_backend.model.enums.ProfessionalStatus.PENDING); // Default status
        professional.setZoomMeetingId(null); // Default zoomMeetingId

        connectedUser1 = new User();
        connectedUser1.setId(10L);
        connectedUser1.setFirstName("Connected");
        connectedUser1.setLastName("UserOne");

        connectedUserDTO1 = new UserDTO();
        connectedUserDTO1.setId(connectedUser1.getId());
        connectedUserDTO1.setFirstName(connectedUser1.getFirstName());
        connectedUserDTO1.setLastName(connectedUser1.getLastName());

        connection1 = new Connection();
        connection1.setId(100L);
        connection1.setProfessional(professional);
        connection1.setUser(connectedUser1);
        connection1.setStatus(ConnectionStatus.ACCEPTED);

        pageable = PageRequest.of(0, 10);
    }

    @Test
    void testGetConnectedUsers_Success() {
        // Arrange
        List<Connection> connectionsList = Collections.singletonList(connection1);
        Page<Connection> connectionsPage = new PageImpl<>(connectionsList, pageable, connectionsList.size());

        when(professionalRepository.findById(professional.getId())).thenReturn(Optional.of(professional));
        when(connectionRepository.findByProfessionalAndStatus(professional, ConnectionStatus.ACCEPTED, pageable))
                .thenReturn(connectionsPage);
        when(userMapper.toDTO(connectedUser1)).thenReturn(connectedUserDTO1);

        // Act
        Page<UserDTO> result = professionalService.getConnectedUsers(professional.getId(), pageable);

        // Assert
        assertNotNull(result);
        assertEquals(1, result.getTotalElements());
        assertEquals(1, result.getContent().size());
        assertEquals(connectedUserDTO1.getId(), result.getContent().get(0).getId());
        assertEquals(connectedUserDTO1.getFirstName(), result.getContent().get(0).getFirstName());

        verify(professionalRepository).findById(professional.getId());
        verify(connectionRepository).findByProfessionalAndStatus(professional, ConnectionStatus.ACCEPTED, pageable);
        verify(userMapper).toDTO(connectedUser1);
    }

    @Test
    void testGetConnectedUsers_ProfessionalNotFound() {
        // Arrange
        Long nonExistentProfessionalId = 99L;
        when(professionalRepository.findById(nonExistentProfessionalId)).thenReturn(Optional.empty());

        // Act & Assert
        EntityNotFoundException exception = assertThrows(EntityNotFoundException.class, () -> {
            professionalService.getConnectedUsers(nonExistentProfessionalId, pageable);
        });
        assertEquals("Professional not found with ID: " + nonExistentProfessionalId, exception.getMessage());

        verify(professionalRepository).findById(nonExistentProfessionalId);
        verify(connectionRepository, never()).findByProfessionalAndStatus(any(), any(), any());
    }

    @Test
    void testGetConnectedUsers_NoConnections() {
        // Arrange
        Page<Connection> emptyConnectionsPage = new PageImpl<>(Collections.emptyList(), pageable, 0);

        when(professionalRepository.findById(professional.getId())).thenReturn(Optional.of(professional));
        when(connectionRepository.findByProfessionalAndStatus(professional, ConnectionStatus.ACCEPTED, pageable))
                .thenReturn(emptyConnectionsPage);

        // Act
        Page<UserDTO> result = professionalService.getConnectedUsers(professional.getId(), pageable);

        // Assert
        assertNotNull(result);
        assertTrue(result.isEmpty());
        assertEquals(0, result.getTotalElements());

        verify(professionalRepository).findById(professional.getId());
        verify(connectionRepository).findByProfessionalAndStatus(professional, ConnectionStatus.ACCEPTED, pageable);
        verify(userMapper, never()).toDTO(any(User.class));
    }

    // --- Tests for updateProfessionalStatus ---

    @Test
    void updateProfessionalStatus_toActive_zoomIdNull_createsZoomMeeting() {
        // Arrange
        Long professionalId = professional.getId();
        com.adamasorho.mindapax_backend.model.enums.ProfessionalStatus newStatus = com.adamasorho.mindapax_backend.model.enums.ProfessionalStatus.ACTIVE;
        professional.setStatus(com.adamasorho.mindapax_backend.model.enums.ProfessionalStatus.PENDING); // Ensure initial status is not ACTIVE
        professional.setZoomMeetingId(null);
        String expectedZoomMeetingId = "zoom123";
        java.util.Set<org.springframework.security.core.GrantedAuthority> authorities = java.util.Set.of(new org.springframework.security.core.authority.SimpleGrantedAuthority("ROLE_ADMIN"));


        when(professionalRepository.findById(professionalId)).thenReturn(Optional.of(professional));
        when(zoomService.createPermanentMeetingForProfessional(professionalUser.getFirstName() + " " + professionalUser.getLastName()))
                .thenReturn(expectedZoomMeetingId);
        when(professionalRepository.save(any(Professional.class))).thenAnswer(invocation -> invocation.getArgument(0));

        // Act
        professionalService.updateProfessionalStatus(professionalId, newStatus, null, authorities);

        // Assert
        ArgumentCaptor<Professional> professionalCaptor = ArgumentCaptor.forClass(Professional.class);
        verify(professionalRepository).save(professionalCaptor.capture());
        Professional savedProfessional = professionalCaptor.getValue();

        assertEquals(newStatus, savedProfessional.getStatus());
        assertEquals(expectedZoomMeetingId, savedProfessional.getZoomMeetingId());
        assertNotNull(savedProfessional.getStatusUpdatedAt());
        verify(zoomService, times(1)).createPermanentMeetingForProfessional(anyString());
    }

    @Test
    void updateProfessionalStatus_toActive_zoomIdExists_doesNotCreateZoomMeeting() {
        // Arrange
        Long professionalId = professional.getId();
        com.adamasorho.mindapax_backend.model.enums.ProfessionalStatus newStatus = com.adamasorho.mindapax_backend.model.enums.ProfessionalStatus.ACTIVE;
        professional.setStatus(com.adamasorho.mindapax_backend.model.enums.ProfessionalStatus.PENDING);
        professional.setZoomMeetingId("existingZoomId");
        java.util.Set<org.springframework.security.core.GrantedAuthority> authorities = java.util.Set.of(new org.springframework.security.core.authority.SimpleGrantedAuthority("ROLE_ADMIN"));


        when(professionalRepository.findById(professionalId)).thenReturn(Optional.of(professional));
        when(professionalRepository.save(any(Professional.class))).thenAnswer(invocation -> invocation.getArgument(0));

        // Act
        professionalService.updateProfessionalStatus(professionalId, newStatus, null, authorities);

        // Assert
        ArgumentCaptor<Professional> professionalCaptor = ArgumentCaptor.forClass(Professional.class);
        verify(professionalRepository).save(professionalCaptor.capture());
        Professional savedProfessional = professionalCaptor.getValue();

        assertEquals(newStatus, savedProfessional.getStatus());
        assertEquals("existingZoomId", savedProfessional.getZoomMeetingId()); // Should remain unchanged
        verify(zoomService, never()).createPermanentMeetingForProfessional(anyString());
    }

    @Test
    void updateProfessionalStatus_toActive_alreadyActive_zoomIdNull_doesNotCreateZoomMeeting() {
        // Arrange
        Long professionalId = professional.getId();
        com.adamasorho.mindapax_backend.model.enums.ProfessionalStatus newStatus = com.adamasorho.mindapax_backend.model.enums.ProfessionalStatus.ACTIVE;
        professional.setStatus(com.adamasorho.mindapax_backend.model.enums.ProfessionalStatus.ACTIVE); // Already ACTIVE
        professional.setZoomMeetingId(null); // Zoom ID is null
        java.util.Set<org.springframework.security.core.GrantedAuthority> authorities = java.util.Set.of(new org.springframework.security.core.authority.SimpleGrantedAuthority("ROLE_ADMIN"));

        when(professionalRepository.findById(professionalId)).thenReturn(Optional.of(professional));
        when(professionalRepository.save(any(Professional.class))).thenAnswer(invocation -> invocation.getArgument(0));

        // Act
        professionalService.updateProfessionalStatus(professionalId, newStatus, null, authorities);

        // Assert
        ArgumentCaptor<Professional> professionalCaptor = ArgumentCaptor.forClass(Professional.class);
        verify(professionalRepository).save(professionalCaptor.capture());
        Professional savedProfessional = professionalCaptor.getValue();

        assertEquals(newStatus, savedProfessional.getStatus());
        assertNull(savedProfessional.getZoomMeetingId()); // Should remain null
        verify(zoomService, never()).createPermanentMeetingForProfessional(anyString());
    }

    @Test
    void updateProfessionalStatus_toActive_zoomServiceThrowsException_zoomIdNull() {
        // Arrange
        Long professionalId = professional.getId();
        com.adamasorho.mindapax_backend.model.enums.ProfessionalStatus newStatus = com.adamasorho.mindapax_backend.model.enums.ProfessionalStatus.ACTIVE;
        professional.setStatus(com.adamasorho.mindapax_backend.model.enums.ProfessionalStatus.PENDING);
        professional.setZoomMeetingId(null);
        java.util.Set<org.springframework.security.core.GrantedAuthority> authorities = java.util.Set.of(new org.springframework.security.core.authority.SimpleGrantedAuthority("ROLE_ADMIN"));


        when(professionalRepository.findById(professionalId)).thenReturn(Optional.of(professional));
        when(zoomService.createPermanentMeetingForProfessional(anyString())).thenThrow(new RuntimeException("Zoom API error"));
        when(professionalRepository.save(any(Professional.class))).thenAnswer(invocation -> invocation.getArgument(0));

        // Act
        professionalService.updateProfessionalStatus(professionalId, newStatus, null, authorities);

        // Assert
        ArgumentCaptor<Professional> professionalCaptor = ArgumentCaptor.forClass(Professional.class);
        verify(professionalRepository).save(professionalCaptor.capture());
        Professional savedProfessional = professionalCaptor.getValue();

        assertEquals(newStatus, savedProfessional.getStatus());
        assertNull(savedProfessional.getZoomMeetingId()); // Should be null as Zoom call failed
        verify(zoomService, times(1)).createPermanentMeetingForProfessional(anyString());
    }

    @Test
    void updateProfessionalStatus_toRejected_doesNotCreateZoomMeeting() {
        // Arrange
        Long professionalId = professional.getId();
        com.adamasorho.mindapax_backend.model.enums.ProfessionalStatus newStatus = com.adamasorho.mindapax_backend.model.enums.ProfessionalStatus.REJECTED;
        String rejectionNote = "Not qualified";
        professional.setStatus(com.adamasorho.mindapax_backend.model.enums.ProfessionalStatus.PENDING);
        java.util.Set<org.springframework.security.core.GrantedAuthority> authorities = java.util.Set.of(new org.springframework.security.core.authority.SimpleGrantedAuthority("ROLE_ADMIN"));


        when(professionalRepository.findById(professionalId)).thenReturn(Optional.of(professional));
        when(professionalRepository.save(any(Professional.class))).thenAnswer(invocation -> invocation.getArgument(0));

        // Act
        professionalService.updateProfessionalStatus(professionalId, newStatus, rejectionNote, authorities);

        // Assert
        ArgumentCaptor<Professional> professionalCaptor = ArgumentCaptor.forClass(Professional.class);
        verify(professionalRepository).save(professionalCaptor.capture());
        Professional savedProfessional = professionalCaptor.getValue();

        assertEquals(newStatus, savedProfessional.getStatus());
        assertEquals(rejectionNote, savedProfessional.getRejectionNote());
        assertNull(savedProfessional.getZoomMeetingId()); // Should remain unchanged (null in this setup)
        verify(zoomService, never()).createPermanentMeetingForProfessional(anyString());
    }

    @Test
    void updateProfessionalStatus_toActive_nonAdmin_throwsAccessDenied() {
        // Arrange
        Long professionalId = professional.getId();
        com.adamasorho.mindapax_backend.model.enums.ProfessionalStatus newStatus = com.adamasorho.mindapax_backend.model.enums.ProfessionalStatus.ACTIVE;
        java.util.Set<org.springframework.security.core.GrantedAuthority> authorities = java.util.Set.of(new org.springframework.security.core.authority.SimpleGrantedAuthority("ROLE_USER")); // Non-admin

        // No need to mock repository or zoomService as it should fail before that

        // Act & Assert
        AccessDeniedException exception = assertThrows(AccessDeniedException.class, () -> {
            professionalService.updateProfessionalStatus(professionalId, newStatus, null, authorities);
        });
        assertEquals("Only ADMIN can set ACTIVE status.", exception.getMessage());
        verify(professionalRepository, never()).findById(anyLong());
        verify(zoomService, never()).createPermanentMeetingForProfessional(anyString());
        verify(professionalRepository, never()).save(any(Professional.class));
    }

     @Test
    void updateProfessionalStatus_clearRejectionNoteWhenNotRejectedOrPending() {
        // Arrange
        Long professionalId = professional.getId();
        professional.setStatus(com.adamasorho.mindapax_backend.model.enums.ProfessionalStatus.REJECTED); // Start with a status that has a rejection note
        professional.setRejectionNote("Initial note");
        com.adamasorho.mindapax_backend.model.enums.ProfessionalStatus newStatus = com.adamasorho.mindapax_backend.model.enums.ProfessionalStatus.ACTIVE;
        java.util.Set<org.springframework.security.core.GrantedAuthority> authorities = java.util.Set.of(new org.springframework.security.core.authority.SimpleGrantedAuthority("ROLE_ADMIN"));


        when(professionalRepository.findById(professionalId)).thenReturn(Optional.of(professional));
        when(zoomService.createPermanentMeetingForProfessional(anyString())).thenReturn("zoom789"); // Assume zoom creation succeeds
        when(professionalRepository.save(any(Professional.class))).thenAnswer(invocation -> invocation.getArgument(0));

        // Act
        professionalService.updateProfessionalStatus(professionalId, newStatus, "This note should be cleared", authorities);

        // Assert
        ArgumentCaptor<Professional> professionalCaptor = ArgumentCaptor.forClass(Professional.class);
        verify(professionalRepository).save(professionalCaptor.capture());
        Professional savedProfessional = professionalCaptor.getValue();

        assertEquals(newStatus, savedProfessional.getStatus());
        assertNull(savedProfessional.getRejectionNote(), "Rejection note should be cleared for ACTIVE status");
    }
}
