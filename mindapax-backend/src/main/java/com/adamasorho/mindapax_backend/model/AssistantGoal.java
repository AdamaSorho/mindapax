package com.adamasorho.mindapax_backend.model;

import java.time.LocalDateTime;

import org.hibernate.annotations.CreationTimestamp;
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
public class AssistantGoal {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(optional = false)
    @JsonIgnore
    private User user;

    @Column(nullable = false)
    private String title;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private Frequency frequency; // DAILY, WEEKLY, MONTHLY

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private Status status = Status.SUGGESTED; // SUGGESTED, ACTIVE, COMPLETED, SKIPPED

    @CreationTimestamp
    private LocalDateTime createdAt;

    @UpdateTimestamp
    private LocalDateTime updatedAt;

    public enum Frequency { DAILY, WEEKLY, MONTHLY }
    public enum Status { SUGGESTED, ACTIVE, COMPLETED, SKIPPED }
}
