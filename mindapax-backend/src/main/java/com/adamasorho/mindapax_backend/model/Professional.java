package com.adamasorho.mindapax_backend.model;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

import org.hibernate.annotations.CreationTimestamp;

import com.adamasorho.mindapax_backend.model.enums.ProfessionalStatus;
import com.adamasorho.mindapax_backend.model.enums.Specialization;

import jakarta.persistence.CascadeType;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.MapsId;
import jakarta.persistence.OneToMany;
import jakarta.persistence.OneToOne;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Entity
@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class Professional {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private Specialization specialization; // MENTAL_HEALTH, COACHING, FINANCIAL_WELLNESS
    private String bio;
    
    @OneToMany(mappedBy = "professional", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<Certification> certifications = new ArrayList<>();

    private Double hourlyRate;

    @Column(nullable = false)
    private Integer yearsOfExperience;

    @Column(nullable = false)
    private String resumeFilePath;

    @Column(length = 1024)
    private String resumeFileUrl;

    @OneToOne
    @JoinColumn(name = "user_id")
    @MapsId
    private User user;

    @OneToMany(mappedBy = "professional", cascade = CascadeType.ALL)
    private List<Session> sessions;

    @Enumerated(EnumType.STRING)
    private ProfessionalStatus status = ProfessionalStatus.PENDING;

    @Column
    private boolean verified = false;

    private String rejectionNote;
    private String zoomMeetingId;
    private String zoomMeetingPassword;
    
    @CreationTimestamp
    private LocalDateTime createdAt;
    private LocalDateTime statusUpdatedAt;
    private Integer rating;
}
