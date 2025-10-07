package com.adamasorho.mindapax_backend.service;

import java.util.List;

import com.adamasorho.mindapax_backend.dto.payments.CheckoutResponse;
import com.adamasorho.mindapax_backend.dto.subscription.SubscriptionDTO;
import com.adamasorho.mindapax_backend.model.Payment;
import com.adamasorho.mindapax_backend.model.User;

public interface SubscriptionService {
    List<com.adamasorho.mindapax_backend.dto.subscription.PlanDTO> listPlans();
    CheckoutResponse subscribeToPlan(User user, Long planId);
    List<SubscriptionDTO> listMySubscriptions(User user);
    void onPaymentUpdated(Payment payment);
    void cancel(User user, Long subscriptionId);
}

