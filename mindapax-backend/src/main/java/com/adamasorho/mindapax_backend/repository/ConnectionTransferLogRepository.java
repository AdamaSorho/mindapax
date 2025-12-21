package com.adamasorho.mindapax_backend.repository;

import java.time.OffsetDateTime;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.adamasorho.mindapax_backend.model.ConnectionTransferLog;
import com.adamasorho.mindapax_backend.model.Professional;

@Repository
public interface ConnectionTransferLogRepository extends JpaRepository<ConnectionTransferLog, Long> {
  long countByFromProfessionalAndCreatedAtAfter(Professional professional, OffsetDateTime timestamp);
}
