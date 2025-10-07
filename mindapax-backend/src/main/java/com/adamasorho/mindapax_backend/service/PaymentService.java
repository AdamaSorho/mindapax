package com.adamasorho.mindapax_backend.service;

import java.util.List;

import com.adamasorho.mindapax_backend.dto.PaymentDTO;

public interface PaymentService {
  PaymentDTO createPayment(PaymentDTO dto);
  List<PaymentDTO> getPaymentsByUser(Long userId);
  PaymentDTO getPayment(Long id);
}
