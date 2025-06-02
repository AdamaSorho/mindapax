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

    @InjectMocks
    private ProfessionalServiceImpl professionalService;

    private Professional professional;
    private User connectedUser1;
    private UserDTO connectedUserDTO1;
    private Connection connection1;
    private Pageable pageable;

    @BeforeEach
    void setUp() {
        professional = new Professional();
        professional.setId(1L);
        // professional.setUser(...); // Not strictly needed for these tests unless email lookup is also part of this service method

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
}
