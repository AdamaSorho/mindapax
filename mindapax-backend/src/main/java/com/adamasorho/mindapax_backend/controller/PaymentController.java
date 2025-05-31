package com.adamasorho.mindapax_backend.controller;

import java.util.List;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.adamasorho.mindapax_backend.dto.PaymentDTO;
import com.adamasorho.mindapax_backend.service.PaymentService;

import lombok.AllArgsConstructor;

@RestController
@RequestMapping("/api/v1/payments")
@AllArgsConstructor
public class PaymentController {
  private final PaymentService service;

  @PostMapping
  public ResponseEntity<PaymentDTO> create(@RequestBody PaymentDTO dto) {
    return ResponseEntity.ok(service.createPayment(dto));
  }

  @GetMapping("/user/{userId}")
  public ResponseEntity<List<PaymentDTO>> getByUser(@PathVariable Long userId) {
    return ResponseEntity.ok(service.getPaymentsByUser(userId));
  }
}
