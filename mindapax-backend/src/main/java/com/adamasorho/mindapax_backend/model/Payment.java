package com.adamasorho.mindapax_backend.model;

import java.time.LocalDateTime;

import com.adamasorho.mindapax_backend.model.enums.PaymentMethod;
import com.adamasorho.mindapax_backend.model.enums.PaymentStatus;

import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import lombok.Data;

@Entity
@Data
public class Payment {
  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Long id;

  @ManyToOne
  @JoinColumn(name = "user_id")
  private User user;

  private Double amount;
  @Enumerated(EnumType.STRING)
  private PaymentMethod paymentMethod; // CARD, PAYPAL, MOBILE_MONEY
  private LocalDateTime paymentDate;
  @Enumerated(EnumType.STRING)
  private PaymentStatus status; // PENDING, COMPLETED, FAILED

  // Phase 1 CinetPay integration fields
  private String provider; // e.g., CINETPAY
  private String currency; // e.g., XOF, USD
  private String externalRef; // provider transaction/reference id
  private String checkoutUrl; // hosted payment page
  private String description; // human readable purpose

  @jakarta.persistence.Column(columnDefinition = "TEXT")
  private String metadataJson; // optional provider payloads
}
