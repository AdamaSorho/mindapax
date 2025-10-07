package com.adamasorho.mindapax_backend.dto.payments;

import com.adamasorho.mindapax_backend.model.enums.PaymentMethod;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class CheckoutRequest {
    @NotNull
    @Min(1)
    private Double amount;

    // e.g., XOF (default), USD
    private String currency = "XOF";

    // CARD or MOBILE_MONEY; for CinetPay HPP this may just influence messaging/routing
    private PaymentMethod paymentMethod = PaymentMethod.MOBILE_MONEY;

    // Optional description shown to customer
    private String description;

    // Optional client return URL; if null, server default is used
    private String returnUrl;
}

