package com.adamasorho.mindapax_backend.repository;

import java.time.OffsetDateTime;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.adamasorho.mindapax_backend.model.Session;
import com.adamasorho.mindapax_backend.model.enums.SessionStatus;

@Repository
public interface SessionRepository extends JpaRepository<Session, Long> {
  Page<Session> findByUserIdAndStartTimeBeforeAndStatus(Long userId, OffsetDateTime startTime, SessionStatus status, Pageable pageable);
  Page<Session> findByUserIdAndStartTimeBefore(Long userId, OffsetDateTime startTime, Pageable pageable);

  Page<Session> findByUserIdAndStartTimeGreaterThanEqualAndStatus(Long userId, OffsetDateTime startTime, SessionStatus status, Pageable pageable);
  Page<Session> findByUserIdAndStartTimeGreaterThanEqual(Long userId, OffsetDateTime startTime, Pageable pageable);

  Page<Session> findByProfessionalIdAndStartTimeBeforeAndStatus(Long professionalId, OffsetDateTime startTime, SessionStatus status, Pageable pageable);
  Page<Session> findByProfessionalIdAndStartTimeBefore(Long professionalId, OffsetDateTime startTime, Pageable pageable);

  Page<Session> findByProfessionalIdAndStartTimeGreaterThanEqualAndStatus(Long professionalId, OffsetDateTime startTime, SessionStatus status, Pageable pageable);
  Page<Session> findByProfessionalIdAndStartTimeGreaterThanEqual(Long professionalId, OffsetDateTime startTime, Pageable pageable);

  long countByUserIdAndStartTimeAfter(Long userId, OffsetDateTime startTime);
}
