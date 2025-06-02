package com.adamasorho.mindapax_backend.repository;

import java.util.List;
import java.util.Optional;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.adamasorho.mindapax_backend.model.Connection;
import com.adamasorho.mindapax_backend.model.Professional;
import com.adamasorho.mindapax_backend.model.enums.ConnectionStatus;

@Repository
public interface ConnectionRepository extends JpaRepository<Connection, Long> {
  Optional<Connection> findByUserIdAndProfessionalId(Long userId, Long professionalId);
  List<Connection> findByUserId(Long userId);
  List<Connection> findByProfessionalId(Long professionalId);
  Page<Connection> findByProfessionalAndStatus(Professional professional, ConnectionStatus status, Pageable pageable);
  void deleteByUserIdAndProfessionalId(Long userId, Long professionalId);
}
