package com.adamasorho.mindapax_backend.model;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import com.adamasorho.mindapax_backend.model.enums.SelfGuidedDomain;

import jakarta.persistence.CollectionTable;
import jakarta.persistence.Column;
import jakarta.persistence.ElementCollection;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Entity
@Data
@NoArgsConstructor
@AllArgsConstructor
public class MicroSession {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String title;

    @Column(nullable = false, length = 500)
    private String description;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private SelfGuidedDomain domain;

    @ElementCollection
    @CollectionTable(name = "micro_session_outcomes", joinColumns = @JoinColumn(name = "micro_session_id"))
    @Column(name = "outcome")
    private List<String> outcomes = new ArrayList<>();

    @Column(nullable = false)
    private int minutes;

    @ElementCollection
    @CollectionTable(name = "micro_session_steps", joinColumns = @JoinColumn(name = "micro_session_id"))
    @Column(name = "step")
    private List<String> steps = new ArrayList<>();

    @CreationTimestamp
    private LocalDateTime createdAt;

    @UpdateTimestamp
    private LocalDateTime updatedAt;
}
