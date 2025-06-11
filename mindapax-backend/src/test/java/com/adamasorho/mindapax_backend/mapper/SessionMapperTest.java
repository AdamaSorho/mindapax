package com.adamasorho.mindapax_backend.mapper;

import com.adamasorho.mindapax_backend.dto.SessionDTO;
import com.adamasorho.mindapax_backend.model.Session;
import com.adamasorho.mindapax_backend.model.User;
import com.adamasorho.mindapax_backend.model.Professional;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mapstruct.factory.Mappers;

import java.time.OffsetDateTime;

import static org.junit.jupiter.api.Assertions.*;

class SessionMapperTest {

    private SessionMapper sessionMapper;

    @BeforeEach
    void setUp() {
        sessionMapper = Mappers.getMapper(SessionMapper.class);
    }

    @Test
    void testToDTO_withZoomMeetingId() {
        Session session = new Session();
        session.setId(1L);
        session.setZoomMeetingId("testZoomId123");
        session.setStartTime(OffsetDateTime.now());
        // Required fields for Professional mapping
        Professional professional = new Professional();
        User profUser = new User();
        profUser.setFirstName("Test");
        profUser.setLastName("Professional");
        professional.setUser(profUser);
        professional.setSpecialization("Test Specialization");
        session.setProfessional(professional);


        SessionDTO dto = sessionMapper.toDTO(session);

        assertNotNull(dto);
        assertEquals("testZoomId123", dto.getZoomMeetingId());
    }

    @Test
    void testToDTO_withNullZoomMeetingId() {
        Session session = new Session();
        session.setId(1L);
        session.setZoomMeetingId(null);
        session.setStartTime(OffsetDateTime.now());
        // Required fields for Professional mapping
        Professional professional = new Professional();
        User profUser = new User();
        profUser.setFirstName("Test");
        profUser.setLastName("Professional");
        professional.setUser(profUser);
        professional.setSpecialization("Test Specialization");
        session.setProfessional(professional);

        SessionDTO dto = sessionMapper.toDTO(session);

        assertNotNull(dto);
        assertNull(dto.getZoomMeetingId());
    }

    @Test
    void testToEntity_withZoomMeetingId() {
        SessionDTO dto = new SessionDTO();
        dto.setId(1L);
        dto.setZoomMeetingId("testZoomId456");

        Session entity = sessionMapper.toEntity(dto);

        assertNotNull(entity);
        assertEquals("testZoomId456", entity.getZoomMeetingId());
    }

    @Test
    void testToEntity_withNullZoomMeetingId() {
        SessionDTO dto = new SessionDTO();
        dto.setId(1L);
        dto.setZoomMeetingId(null);

        Session entity = sessionMapper.toEntity(dto);

        assertNotNull(entity);
        assertNull(entity.getZoomMeetingId());
    }
}
