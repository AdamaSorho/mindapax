package com.adamasorho.mindapax_backend.service.impl;

import java.util.List;
import java.util.stream.Collectors;

import org.springframework.stereotype.Service;

import com.adamasorho.mindapax_backend.dto.PaymentDTO;
import com.adamasorho.mindapax_backend.mapper.PaymentMapper;
import com.adamasorho.mindapax_backend.repository.PaymentRepository;
import com.adamasorho.mindapax_backend.service.PaymentService;

@Service
public class PaymentServiceImpl implements PaymentService {
  private final PaymentRepository repository;
  private final PaymentMapper mapper;

  public PaymentServiceImpl(PaymentRepository repository, PaymentMapper mapper) {
      this.repository = repository;
      this.mapper = mapper;
  }

  @Override
  public PaymentDTO createPayment(PaymentDTO dto) {
    return mapper.toDTO(repository.save(mapper.toEntity(dto)));
  }

  @Override
  public List<PaymentDTO> getPaymentsByUser(Long userId) {
    return repository.findAll().stream()
            .filter(p -> p.getUser().getId().equals(userId))
            .map(mapper::toDTO)
            .collect(Collectors.toList());
  }

  @Override
  public PaymentDTO getPayment(Long id) {
    return repository.findById(id).map(mapper::toDTO).orElse(null);
  }
}
