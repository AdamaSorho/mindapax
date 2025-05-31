package com.adamasorho.mindapax_backend.model.enums;

public enum ConnectionStatus {
  PENDING,
  ACCEPTED,
  TRANSFERRED, // Transferred to another professional
  ESCALATED, // Escalated to admin
  BLOCKED
}

