package com.adamasorho.mindapax_backend.dto.payments;

import lombok.AllArgsConstructor;
import lombok.Data;

@Data
@AllArgsConstructor
public class CheckoutResponse {
    private Long paymentId;
    private String checkoutUrl;
}

