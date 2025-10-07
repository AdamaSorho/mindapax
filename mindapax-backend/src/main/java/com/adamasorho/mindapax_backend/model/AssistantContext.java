package com.adamasorho.mindapax_backend.model;

import java.time.LocalDateTime;

import org.hibernate.annotations.UpdateTimestamp;

import jakarta.persistence.*;
import com.fasterxml.jackson.annotation.JsonIgnore;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Entity
@Data
@NoArgsConstructor
@AllArgsConstructor
public class AssistantContext {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @OneToOne(optional = false)
    @JsonIgnore
    private User user;

    @Column(columnDefinition = "TEXT")
    private String preferencesJson; // freeform JSON blob for personalization (sleep, stressors, habits, etc.)

    @Column(columnDefinition = "TEXT")
    private String notes; // optional longer context or biography

    // Becomes true once the user has saved any non-empty preferences or notes at least once.
    private boolean completed = false;

    @UpdateTimestamp
    private LocalDateTime updatedAt;
}
