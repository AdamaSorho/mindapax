package com.adamasorho.mindapax_backend.model;

import java.time.OffsetDateTime;

import org.hibernate.annotations.CreationTimestamp;

import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import lombok.Data;

@Entity
@Table(name = "connection_transfer_log")
@Data
public class ConnectionTransferLog {
  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Long id;

  @ManyToOne(optional = false)
  @JoinColumn(name = "connection_id", nullable = false)
  private Connection connection;

  @ManyToOne(optional = false)
  @JoinColumn(name = "from_professional_id", nullable = false)
  private Professional fromProfessional;

  @ManyToOne(optional = false)
  @JoinColumn(name = "to_professional_id", nullable = false)
  private Professional toProfessional;

  @ManyToOne(optional = false)
  @JoinColumn(name = "user_id", nullable = false)
  private User user;

  private String reason;

  private boolean escalated;

  @CreationTimestamp
  private OffsetDateTime createdAt;
}
