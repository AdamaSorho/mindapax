package com.adamasorho.mindapax_backend.dto.request;

import java.time.LocalDate;
import java.time.LocalTime;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class AvailabilityRequest {
  private LocalDate date;
  private LocalTime startTime;
  private LocalTime endTime;
}

