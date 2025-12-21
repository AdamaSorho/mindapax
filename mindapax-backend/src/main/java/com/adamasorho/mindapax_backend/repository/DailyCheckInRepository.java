package com.adamasorho.mindapax_backend.repository;

import java.time.LocalDate;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

import com.adamasorho.mindapax_backend.model.DailyCheckIn;
import com.adamasorho.mindapax_backend.model.User;

public interface DailyCheckInRepository extends JpaRepository<DailyCheckIn, Long> {
    Optional<DailyCheckIn> findByUserAndDate(User user, LocalDate date);
}
