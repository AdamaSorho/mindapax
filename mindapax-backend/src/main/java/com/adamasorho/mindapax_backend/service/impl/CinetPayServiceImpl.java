package com.adamasorho.mindapax_backend.service.impl;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.BodyInserters;
import org.springframework.web.reactive.function.client.WebClient;

import com.adamasorho.mindapax_backend.dto.payments.CheckoutRequest;
import com.adamasorho.mindapax_backend.dto.payments.CheckoutResponse;
import com.adamasorho.mindapax_backend.dto.payments.CinetPayWebhookPayload;
import com.adamasorho.mindapax_backend.model.Payment;
import com.adamasorho.mindapax_backend.model.User;
import com.adamasorho.mindapax_backend.model.enums.PaymentStatus;
import com.adamasorho.mindapax_backend.repository.PaymentRepository;
import com.adamasorho.mindapax_backend.service.CinetPayService;
// import com.adamasorho.mindapax_backend.service.SubscriptionService;

import lombok.RequiredArgsConstructor;
import reactor.core.publisher.Mono;

@Service
@RequiredArgsConstructor
public class CinetPayServiceImpl implements CinetPayService {

    private final PaymentRepository paymentRepository;
    private final WebClient.Builder webClientBuilder;
    // Break circular dependency: do not inject SubscriptionService here

    @Value("${payments.cinetpay.apiKey:}")
    private String apiKey;

    @Value("${payments.cinetpay.siteId:}")
    private String siteId;

    @Value("${payments.cinetpay.baseUrl:https://api-checkout.cinetpay.com}")
    private String baseUrl;

    @Value("${payments.cinetpay.defaultReturnUrl:https://example.com/payments/return}")
    private String defaultReturnUrl;

    @Value("${payments.cinetpay.notifyUrl:https://example.com/api/v1/payments/webhook/cinetpay}")
    private String notifyUrl;

    @Override
    public CheckoutResponse createCheckout(User user, CheckoutRequest req) {
        String externalRef = UUID.randomUUID().toString().replace("-", "");
        String currency = (req.getCurrency() == null || req.getCurrency().isBlank()) ? "XOF" : req.getCurrency();
        String description = (req.getDescription() == null || req.getDescription().isBlank()) ? "Mindapax payment" : req.getDescription();

        Payment payment = new Payment();
        payment.setUser(user);
        payment.setAmount(req.getAmount());
        payment.setCurrency(currency);
        payment.setPaymentMethod(req.getPaymentMethod());
        payment.setPaymentDate(LocalDateTime.now());
        payment.setStatus(PaymentStatus.PENDING);
        payment.setProvider("CINETPAY");
        payment.setExternalRef(externalRef);
        payment.setDescription(description);
        payment = paymentRepository.save(payment);

        // Build CinetPay checkout request (v2)
        Map<String, Object> payload = new HashMap<>();
        payload.put("apikey", apiKey);
        payload.put("site_id", siteId);
        payload.put("transaction_id", externalRef);
        payload.put("amount", req.getAmount());
        payload.put("currency", currency);
        payload.put("description", description);
        payload.put("notify_url", notifyUrl);
        payload.put("return_url", (req.getReturnUrl() == null || req.getReturnUrl().isBlank()) ? defaultReturnUrl : req.getReturnUrl());
        // optional customer fields (email, name, phone) could be added when available

        String checkoutUrl = null;
        try {
            var client = webClientBuilder.baseUrl(baseUrl).build();
            // CinetPay v2 create payment endpoint (documented as /v2/payment)
            Map<String, Object> response = client.post()
                .uri("/v2/payment")
                .contentType(MediaType.APPLICATION_JSON)
                .body(BodyInserters.fromValue(payload))
                .retrieve()
                .bodyToMono(Map.class)
                .onErrorResume(e -> Mono.just(Map.of()))
                .blockOptional()
                .orElse(Map.of());

            // Extract URL (naming varies; we try common keys)
            Object data = response.get("data");
            if (data instanceof Map<?, ?> m) {
                Object link = m.get("payment_url");
                if (link == null) link = m.get("checkout_url");
                if (link == null) link = m.get("url");
                if (link != null) checkoutUrl = link.toString();
            }
        } catch (Exception e) {
            // swallow and proceed with null URL; client can retry
        }

        if (checkoutUrl == null || checkoutUrl.isBlank()) {
            // Fallback to a placeholder to avoid nulls in clients
            checkoutUrl = "";
        }
        payment.setCheckoutUrl(checkoutUrl);
        paymentRepository.save(payment);
        return new CheckoutResponse(payment.getId(), checkoutUrl);
    }

    @Override
    public Payment verifyAndUpdateByExternalRef(String externalRef) {
        var optional = paymentRepository.findByExternalRef(externalRef);
        if (optional.isEmpty()) return null;
        Payment payment = optional.get();

        try {
            var client = webClientBuilder.baseUrl(baseUrl).build();
            Map<String, Object> payload = Map.of(
                "apikey", apiKey,
                "site_id", siteId,
                "transaction_id", externalRef
            );
            Map<String, Object> response = client.post()
                .uri("/v2/payment/check")
                .contentType(MediaType.APPLICATION_JSON)
                .body(BodyInserters.fromValue(payload))
                .retrieve()
                .bodyToMono(Map.class)
                .onErrorResume(e -> Mono.just(Map.of()))
                .blockOptional()
                .orElse(Map.of());

            String status = extractStatus(response);
            if (status != null) {
                if (isSuccess(status)) {
                    payment.setStatus(PaymentStatus.COMPLETED);
                } else if (isFailed(status)) {
                    payment.setStatus(PaymentStatus.FAILED);
                }
                paymentRepository.save(payment);
            }
        } catch (Exception e) {
            // ignore errors; caller can retry
        }
        return payment;
    }

    @Override
    public Payment handleWebhook(CinetPayWebhookPayload payload) {
        if (payload == null || payload.getTransaction_id() == null) return null;
        // Always verify with provider to avoid spoofed notifications
        return verifyAndUpdateByExternalRef(payload.getTransaction_id());
    }

    private static String extractStatus(Map<String, Object> resp) {
        if (resp == null) return null;
        Object d = resp.get("data");
        if (d instanceof Map<?, ?> m) {
            Object s = m.get("status");
            if (s != null) return s.toString();
        }
        Object s = resp.get("status");
        return s != null ? s.toString() : null;
    }

    private static boolean isSuccess(String status) {
        String s = status.toUpperCase();
        return s.contains("ACCEPTED") || s.contains("SUCCESS") || s.equals("PAID");
    }

    private static boolean isFailed(String status) {
        String s = status.toUpperCase();
        return s.contains("FAILED") || s.contains("REFUSED") || s.contains("CANCELED") || s.contains("DECLINED");
    }
}
