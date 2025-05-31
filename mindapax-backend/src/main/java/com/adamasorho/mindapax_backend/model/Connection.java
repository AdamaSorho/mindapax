package com.adamasorho.mindapax_backend.model;

import java.time.LocalDateTime;

import org.hibernate.annotations.CreationTimestamp;

import com.adamasorho.mindapax_backend.model.enums.ConnectionStatus;
import com.adamasorho.mindapax_backend.model.enums.Specialization;
import com.adamasorho.mindapax_backend.model.enums.UrgencyStatus;

import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Entity
@Table(name = "connections", uniqueConstraints = {
    @UniqueConstraint(columnNames = {"user_id", "professional_id"})
})
@Data
@AllArgsConstructor
@NoArgsConstructor
public class Connection {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne
    private User user;

    @ManyToOne
    private Professional professional;

    @Enumerated(EnumType.STRING)
    private ConnectionStatus status = ConnectionStatus.PENDING;

    @Enumerated(EnumType.STRING)
    private Specialization requestType;

    private String message;

    @Enumerated(EnumType.STRING)
    private UrgencyStatus urgencyStatus;

    @CreationTimestamp
    private LocalDateTime createdAt;
}

