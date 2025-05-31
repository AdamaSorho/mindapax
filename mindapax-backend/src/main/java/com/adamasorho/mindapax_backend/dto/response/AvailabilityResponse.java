package com.adamasorho.mindapax_backend.dto.response;

import java.time.LocalDate;
import java.time.LocalTime;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class AvailabilityResponse {
  private Long id;
  private LocalDate date;
  private LocalTime startTime;
  private LocalTime endTime;
  private Long professionalId;
}
