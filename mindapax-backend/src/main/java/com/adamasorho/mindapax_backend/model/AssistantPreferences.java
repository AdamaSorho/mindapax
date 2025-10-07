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
public class AssistantPreferences {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @OneToOne(optional = false)
    @JsonIgnore
    private User user;

    private boolean useContext = true;
    private boolean includeProgress = true;
    private boolean suggestGoals = true;

    @UpdateTimestamp
    private LocalDateTime updatedAt;
}
