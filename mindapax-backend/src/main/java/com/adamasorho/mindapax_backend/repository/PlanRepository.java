package com.adamasorho.mindapax_backend.repository;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

import com.adamasorho.mindapax_backend.model.Plan;

public interface PlanRepository extends JpaRepository<Plan, Long> {
    List<Plan> findByActiveTrueOrderByPriceAsc();
    Optional<Plan> findByNameIgnoreCase(String name);
}
