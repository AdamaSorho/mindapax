package com.adamasorho.mindapax_backend.dto.payments;

import lombok.Data;

// Minimal capture of CinetPay webhook payload needed to reconcile
@Data
public class CinetPayWebhookPayload {
    private String transaction_id; // our externalRef
    private String status; // e.g., SUCCESS, FAILED, REFUSED, CANCELED
    private String currency;
    private String amount;
    private String payment_method;
    private String description;
    private String signature; // if provided, optional verify in future
}

