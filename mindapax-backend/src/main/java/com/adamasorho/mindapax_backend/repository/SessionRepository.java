package com.adamasorho.mindapax_backend.repository;

import java.time.LocalDateTime;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.adamasorho.mindapax_backend.model.Session;
import com.adamasorho.mindapax_backend.model.enums.SessionStatus;

@Repository
public interface SessionRepository extends JpaRepository<Session, Long> {
  Page<Session> findByUserIdAndStartTimeBeforeAndStatus(Long userId, LocalDateTime startTime, SessionStatus status, Pageable pageable);
  Page<Session> findByUserIdAndStartTimeBefore(Long userId, LocalDateTime startTime, Pageable pageable);

  Page<Session> findByUserIdAndStartTimeGreaterThanEqualAndStatus(Long userId, LocalDateTime startTime, SessionStatus status, Pageable pageable);
  Page<Session> findByUserIdAndStartTimeGreaterThanEqual(Long userId, LocalDateTime startTime, Pageable pageable);
}
