package com.adamasorho.mindapax_backend.model;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import com.adamasorho.mindapax_backend.model.enums.SelfGuidedDifficulty;
import com.adamasorho.mindapax_backend.model.enums.SelfGuidedDomain;
import com.fasterxml.jackson.annotation.JsonIgnore;

import jakarta.persistence.CascadeType;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.OneToMany;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Entity
@Data
@NoArgsConstructor
@AllArgsConstructor
public class SelfGuidedGoal {

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
    private SelfGuidedDomain domain;

    private String outcome;

    @Column(nullable = false)
    private String action;

    @Column(nullable = false)
    private int targetPerWeek;

    @Column(nullable = false)
    private int minutesPerTask;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private SelfGuidedDifficulty difficulty;

    @Column(nullable = false)
    private int xp = 0;

    @Column(nullable = false)
    private int streak = 0;

    private LocalDate lastProgressDate;

    @OneToMany(mappedBy = "goal", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<SelfGuidedTask> tasks = new ArrayList<>();

    @CreationTimestamp
    private LocalDateTime createdAt;

    @UpdateTimestamp
    private LocalDateTime updatedAt;
}
