package com.adamasorho.mindapax_backend.model;

import java.time.LocalDateTime;

import org.hibernate.annotations.UpdateTimestamp;

import jakarta.persistence.*;
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
    private User user;

    @Lob
    private String preferencesJson; // freeform JSON blob for personalization (sleep, stressors, habits, etc.)

    @Lob
    private String notes; // optional longer context or biography

    // Becomes true once the user has saved any non-empty preferences or notes at least once.
    private boolean completed = false;

    @UpdateTimestamp
    private LocalDateTime updatedAt;
}
