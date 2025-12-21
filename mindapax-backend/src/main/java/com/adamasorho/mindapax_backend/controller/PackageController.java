package com.adamasorho.mindapax_backend.controller;

import java.util.List;

import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.adamasorho.mindapax_backend.dto.payments.CheckoutResponse;
import com.adamasorho.mindapax_backend.dto.subscription.PlanDTO;
import com.adamasorho.mindapax_backend.dto.subscription.SubscriptionDTO;
import com.adamasorho.mindapax_backend.model.User;
import com.adamasorho.mindapax_backend.security.CustomUserDetails;
import com.adamasorho.mindapax_backend.service.SubscriptionService;

import lombok.RequiredArgsConstructor;

@RestController
@RequestMapping("/api/v1/packages")
@RequiredArgsConstructor
public class PackageController {

    private final SubscriptionService subscriptionService;

    @GetMapping
    public ResponseEntity<List<PlanDTO>> listPlans() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null || !(auth.getPrincipal() instanceof CustomUserDetails)) {
            return ResponseEntity.status(401).build();
        }
        User user = ((CustomUserDetails) auth.getPrincipal()).getUser();
        return ResponseEntity.ok(subscriptionService.listPlans(user));
    }

    @PostMapping("/{planId}/subscribe")
    public ResponseEntity<CheckoutResponse> subscribe(@PathVariable Long planId) {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null || !(auth.getPrincipal() instanceof CustomUserDetails)) {
            return ResponseEntity.status(401).build();
        }
        User user = ((CustomUserDetails) auth.getPrincipal()).getUser();
        CheckoutResponse resp = subscriptionService.subscribeToPlan(user, planId);
        return ResponseEntity.ok(resp);
    }

    @GetMapping("/me")
    public ResponseEntity<List<SubscriptionDTO>> mySubscriptions() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null || !(auth.getPrincipal() instanceof CustomUserDetails)) {
            return ResponseEntity.status(401).build();
        }
        User user = ((CustomUserDetails) auth.getPrincipal()).getUser();
        return ResponseEntity.ok(subscriptionService.listMySubscriptions(user));
    }
}
