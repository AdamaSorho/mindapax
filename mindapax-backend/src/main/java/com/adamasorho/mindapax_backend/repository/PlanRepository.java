package com.adamasorho.mindapax_backend.repository;

import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;
import com.adamasorho.mindapax_backend.model.Plan;

public interface PlanRepository extends JpaRepository<Plan, Long> {
    List<Plan> findByActiveTrueOrderByPriceAsc();
}

