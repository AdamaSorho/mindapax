package com.adamasorho.mindapax_backend.service.impl;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.stream.Collectors;

import org.springframework.stereotype.Service;
import com.adamasorho.mindapax_backend.exception.CheckoutUnavailableException;
import org.springframework.transaction.annotation.Transactional;

import com.adamasorho.mindapax_backend.dto.payments.CheckoutRequest;
import com.adamasorho.mindapax_backend.dto.payments.CheckoutResponse;
import com.adamasorho.mindapax_backend.dto.subscription.PlanDTO;
import com.adamasorho.mindapax_backend.dto.subscription.SubscriptionDTO;
import com.adamasorho.mindapax_backend.mapper.PlanMapper;
import com.adamasorho.mindapax_backend.mapper.SubscriptionMapper;
import com.adamasorho.mindapax_backend.model.Payment;
import com.adamasorho.mindapax_backend.model.Plan;
import com.adamasorho.mindapax_backend.model.Subscription;
import com.adamasorho.mindapax_backend.model.User;
import com.adamasorho.mindapax_backend.model.enums.PaymentMethod;
import com.adamasorho.mindapax_backend.model.enums.PaymentStatus;
import com.adamasorho.mindapax_backend.model.enums.SubscriptionStatus;
import com.adamasorho.mindapax_backend.repository.PaymentRepository;
import com.adamasorho.mindapax_backend.repository.PlanRepository;
import com.adamasorho.mindapax_backend.repository.SubscriptionRepository;
import com.adamasorho.mindapax_backend.service.CinetPayService;
import com.adamasorho.mindapax_backend.service.SubscriptionService;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class SubscriptionServiceImpl implements SubscriptionService {

    private final PlanRepository planRepo;
    private final SubscriptionRepository subRepo;
    private final PaymentRepository paymentRepo;
    private final PlanMapper planMapper;
    private final SubscriptionMapper subMapper;
    private final CinetPayService cinetPay;

    @Override
    @Transactional(readOnly = true)
    public List<PlanDTO> listPlans() {
        return planRepo.findByActiveTrueOrderByPriceAsc().stream()
            .map(planMapper::toDTO)
            .collect(Collectors.toList());
    }

    @Override
    @Transactional
    public CheckoutResponse subscribeToPlan(User user, Long planId) {
        Plan plan = planRepo.findById(planId).orElseThrow();
        // Create payment checkout first
        CheckoutRequest req = new CheckoutRequest();
        req.setAmount(plan.getPrice());
        req.setCurrency(plan.getCurrency());
        req.setPaymentMethod(PaymentMethod.MOBILE_MONEY); // user can choose channel on HPP
        req.setDescription("Subscription: " + plan.getName());
        CheckoutResponse pay = cinetPay.createCheckout(user, req);

        // If provider failed to return a usable checkout URL, do NOT create a subscription
        if (pay == null || pay.getCheckoutUrl() == null || pay.getCheckoutUrl().isBlank()) {
            // Mark payment as FAILED if it was created
            if (pay != null) {
                paymentRepo.findById(pay.getPaymentId()).ifPresent(p -> {
                    p.setStatus(PaymentStatus.FAILED);
                    paymentRepo.save(p);
                });
            }
            // Signal upstream error to client (avoid 200 with empty URL)
            throw new CheckoutUnavailableException("Checkout provider unavailable. Please try again later.");
        }

        // Link subscription to payment
        Payment payment = paymentRepo.findById(pay.getPaymentId()).orElseThrow();
        Subscription sub = new Subscription();
        sub.setUser(user);
        sub.setPlan(plan);
        sub.setStatus(SubscriptionStatus.PENDING);
        sub.setLastPayment(payment);
        subRepo.save(sub);
        return pay;
    }

    @Override
    @Transactional(readOnly = true)
    public List<SubscriptionDTO> listMySubscriptions(User user) {
        return subRepo.findByUserOrderByIdDesc(user).stream()
            .map(subMapper::toDTO)
            .collect(Collectors.toList());
    }

    @Override
    @Transactional
    public void onPaymentUpdated(Payment payment) {
        if (payment == null || payment.getId() == null) return;
        subRepo.findByLastPayment(payment).ifPresent(sub -> {
            if (payment.getStatus() == PaymentStatus.COMPLETED) {
                // Activate subscription period: now to +1 month
                OffsetDateTime now = OffsetDateTime.now();
                sub.setStatus(SubscriptionStatus.ACTIVE);
                sub.setCurrentPeriodStart(now);
                sub.setCurrentPeriodEnd(now.plusMonths(1));
                if (sub.getPlan() != null) {
                    sub.setRemainingSessions(sub.getPlan().getSessionAllowance());
                }
                subRepo.save(sub);
            }
        });
    }

    @Override
    @Transactional
    public void cancel(User user, Long subscriptionId) {
        Subscription sub = subRepo.findById(subscriptionId).orElseThrow();
        if (!sub.getUser().getId().equals(user.getId())) {
            throw new RuntimeException("Not allowed");
        }
        sub.setStatus(SubscriptionStatus.CANCELED);
        subRepo.save(sub);
    }
}
