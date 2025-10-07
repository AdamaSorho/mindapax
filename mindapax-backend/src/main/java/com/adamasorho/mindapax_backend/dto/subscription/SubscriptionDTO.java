package com.adamasorho.mindapax_backend.dto.subscription;

import java.time.OffsetDateTime;

import com.adamasorho.mindapax_backend.model.enums.SubscriptionStatus;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class SubscriptionDTO {
    private Long id;
    private Long planId;
    private String planName;
    private Double planPrice;
    private String planCurrency;
    private SubscriptionStatus status;
    private OffsetDateTime currentPeriodStart;
    private OffsetDateTime currentPeriodEnd;
    private Integer remainingSessions;
    private Long lastPaymentId;
}

