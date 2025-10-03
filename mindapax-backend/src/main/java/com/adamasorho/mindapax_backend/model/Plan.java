package com.adamasorho.mindapax_backend.model;

import com.adamasorho.mindapax_backend.model.enums.BillingCycle;
import jakarta.persistence.*;
import java.util.ArrayList;
import java.util.List;
import lombok.Data;

@Entity
@Data
public class Plan {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String name;

    @Column(nullable = false)
    private Double price;

    @Column(nullable = false)
    private String currency = "XOF"; // default

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private BillingCycle billingCycle = BillingCycle.MONTHLY;

    @Column(columnDefinition = "TEXT")
    private String description;

    @Column(nullable = false)
    private boolean active = true;

    // Optional: credits included per cycle
    @Column(nullable = false)
    private Integer sessionAllowance = 0;

    // Human-readable feature bullets shown in pricing
    @ElementCollection
    @CollectionTable(name = "plan_features", joinColumns = @JoinColumn(name = "plan_id"))
    @Column(name = "feature", nullable = false)
    private List<String> features = new ArrayList<>();
}
