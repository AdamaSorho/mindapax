package com.adamasorho.mindapax_backend.model;

import java.time.OffsetDateTime;

import com.adamasorho.mindapax_backend.model.enums.SubscriptionStatus;
import jakarta.persistence.*;
import lombok.Data;

@Entity
@Data
public class Subscription {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(optional = false)
    private User user;

    @ManyToOne(optional = false)
    private Plan plan;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private SubscriptionStatus status = SubscriptionStatus.PENDING;

    private OffsetDateTime currentPeriodStart;
    private OffsetDateTime currentPeriodEnd;

    private Integer remainingSessions;

    @ManyToOne
    private Payment lastPayment; // last payment associated (for activation)
}

