package com.adamasorho.mindapax_backend.repository;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.stereotype.Repository;

import java.util.Optional;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.stereotype.Repository;

import com.adamasorho.mindapax_backend.model.Professional;
import com.adamasorho.mindapax_backend.model.enums.ProfessionalStatus;

@Repository
public interface ProfessionalRepository extends JpaRepository<Professional, Long>, JpaSpecificationExecutor<Professional> {
  Page<Professional> findByStatus(ProfessionalStatus status, Pageable pageable);
  Optional<Professional> findByUserEmail(String email);
}
