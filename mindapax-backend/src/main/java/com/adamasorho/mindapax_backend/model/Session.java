package com.adamasorho.mindapax_backend.model;

import java.time.LocalDateTime;

import com.adamasorho.mindapax_backend.model.enums.SessionMode;
import com.adamasorho.mindapax_backend.model.enums.SessionStatus;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import lombok.Data;

@Entity
@Data
public class Session {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne
    @JoinColumn(name = "user_id")
    private User user;

    @ManyToOne
    @JoinColumn(name = "professional_id")
    private Professional professional;

    private LocalDateTime startTime;
    private LocalDateTime endTime;
    @Enumerated(EnumType.STRING)
    private SessionMode mode; // CHAT, VIDEO, MESSAGE
    @Enumerated(EnumType.STRING)
    private SessionStatus status; // SCHEDULED, COMPLETED, CANCELLED
    @Column(columnDefinition = "TEXT")
    private String notes;
}
