package com.adamasorho.mindapax_backend.service;

import com.adamasorho.mindapax_backend.dto.payments.CheckoutRequest;
import com.adamasorho.mindapax_backend.dto.payments.CheckoutResponse;
import com.adamasorho.mindapax_backend.dto.payments.CinetPayWebhookPayload;
import com.adamasorho.mindapax_backend.model.Payment;
import com.adamasorho.mindapax_backend.model.User;

public interface CinetPayService {
    CheckoutResponse createCheckout(User user, CheckoutRequest req);
    Payment verifyAndUpdateByExternalRef(String externalRef);
    Payment handleWebhook(CinetPayWebhookPayload payload);
}
