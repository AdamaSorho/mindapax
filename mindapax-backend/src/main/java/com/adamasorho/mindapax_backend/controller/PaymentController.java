package com.adamasorho.mindapax_backend.controller;

import java.util.List;

import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.adamasorho.mindapax_backend.dto.PaymentDTO;
import com.adamasorho.mindapax_backend.dto.payments.CheckoutRequest;
import com.adamasorho.mindapax_backend.dto.payments.CheckoutResponse;
import com.adamasorho.mindapax_backend.dto.payments.CinetPayWebhookPayload;
import com.adamasorho.mindapax_backend.model.User;
import com.adamasorho.mindapax_backend.security.CustomUserDetails;
import com.adamasorho.mindapax_backend.service.PaymentService;
import com.adamasorho.mindapax_backend.service.CinetPayService;
import com.adamasorho.mindapax_backend.service.SubscriptionService;

import lombok.AllArgsConstructor;

@RestController
@RequestMapping("/api/v1/payments")
@AllArgsConstructor
public class PaymentController {
  private final PaymentService service;
  private final CinetPayService cinetPayService;
  private final SubscriptionService subscriptionService;

  @PostMapping
  public ResponseEntity<PaymentDTO> create(@RequestBody PaymentDTO dto) {
    return ResponseEntity.ok(service.createPayment(dto));
  }

  @GetMapping("/user/{userId}")
  public ResponseEntity<List<PaymentDTO>> getByUser(@PathVariable Long userId) {
    return ResponseEntity.ok(service.getPaymentsByUser(userId));
  }

  @GetMapping("/{id}")
  public ResponseEntity<PaymentDTO> getPayment(@PathVariable Long id) {
    PaymentDTO dto = service.getPayment(id);
    if (dto == null) return ResponseEntity.notFound().build();
    return ResponseEntity.ok(dto);
  }

  // Phase 1: CinetPay checkout for authenticated user
  @PostMapping("/checkout")
  public ResponseEntity<CheckoutResponse> createCheckout(@RequestBody CheckoutRequest request) {
    Authentication auth = SecurityContextHolder.getContext().getAuthentication();
    if (auth == null || !(auth.getPrincipal() instanceof CustomUserDetails)) {
      return ResponseEntity.status(401).build();
    }
    User user = ((CustomUserDetails) auth.getPrincipal()).getUser();
    CheckoutResponse resp = cinetPayService.createCheckout(user, request);
    return ResponseEntity.ok(resp);
  }

  // Public webhook endpoint – CinetPay will notify here
  @PostMapping("/webhook/cinetpay")
  public ResponseEntity<Void> cinetpayWebhook(@RequestBody(required = false) CinetPayWebhookPayload payload) {
    try {
      var payment = cinetPayService.handleWebhook(payload);
      if (payment != null) {
        try { subscriptionService.onPaymentUpdated(payment); } catch (Exception ignored) {}
      }
    } catch (Exception ignored) {}
    return ResponseEntity.ok().build();
  }
}
