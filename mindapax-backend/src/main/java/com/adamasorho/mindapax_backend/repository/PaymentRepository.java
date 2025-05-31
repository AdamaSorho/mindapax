package com.adamasorho.mindapax_backend.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.adamasorho.mindapax_backend.model.Payment;

@Repository
public interface PaymentRepository extends JpaRepository<Payment, Long> {
  
}
