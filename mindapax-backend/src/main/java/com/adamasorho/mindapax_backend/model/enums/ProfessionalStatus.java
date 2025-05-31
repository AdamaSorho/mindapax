package com.adamasorho.mindapax_backend.model.enums;

public enum ProfessionalStatus {
  PENDING,      // Waiting for admin approval
  ACTIVE,       // Approved and currently available
  BLOCKED,      // Temporarily or permanently disabled by admin
  REJECTED,     // Rejected by admin
  DEACTIVATED   // Voluntarily or permanently deactivated
}

