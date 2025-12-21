package com.adamasorho.mindapax_backend.dto.payments;

import java.time.OffsetDateTime;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class CheckoutResponse {
    private Long paymentId;
    private String checkoutUrl;
    private boolean requiresPayment;
    private Long subscriptionId;
    private OffsetDateTime activeUntil;
}
