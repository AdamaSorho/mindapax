package com.adamasorho.mindapax_backend.dto;

import java.time.LocalDateTime;

import com.adamasorho.mindapax_backend.model.enums.PaymentMethod;
import com.adamasorho.mindapax_backend.model.enums.PaymentStatus;

import lombok.Data;

@Data
public class PaymentDTO {
  private Long id;
  private Long userId;
  private Double amount;
  private PaymentMethod paymentMethod;
  private PaymentStatus status;
  private LocalDateTime paymentDate;
  private String provider;
  private String currency;
  private String externalRef;
  private String checkoutUrl;
  private String description;
  private String metadataJson;
}
