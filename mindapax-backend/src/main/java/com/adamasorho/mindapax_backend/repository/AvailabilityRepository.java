package com.adamasorho.mindapax_backend.repository;

import java.time.LocalDate;
import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.adamasorho.mindapax_backend.model.Availability;

@Repository
public interface AvailabilityRepository extends JpaRepository<Availability, Long> {
  List<Availability> findByProfessionalIdAndDateOrderByStartTimeAsc(Long professionalId, LocalDate date);
  List<Availability> findByProfessionalIdOrderByDateAscStartTimeAsc(Long professionalId);
}
