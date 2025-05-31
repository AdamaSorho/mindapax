package com.adamasorho.mindapax_backend.service;

import java.time.LocalDate;
import java.util.List;

import com.adamasorho.mindapax_backend.model.Availability;

public interface AvailabilityService {
  Availability createAvailability(Long professionalId, Availability availability);
  List<Availability> getAvailability(Long professionalId, LocalDate date);
}

