package com.adamasorho.mindapax_backend.controller;

import java.time.LocalDate;
import java.util.List;

import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.adamasorho.mindapax_backend.dto.request.AvailabilityRequest;
import com.adamasorho.mindapax_backend.dto.response.AvailabilityResponse;
import com.adamasorho.mindapax_backend.mapper.AvailabilityMapper;
import com.adamasorho.mindapax_backend.model.Availability;
import com.adamasorho.mindapax_backend.service.AvailabilityService;

import lombok.RequiredArgsConstructor;

@RestController
@RequestMapping("/api/v1/availabilities")
@RequiredArgsConstructor
public class AvailabilityController {

    private final AvailabilityService availabilityService;
    private final AvailabilityMapper availabilityMapper;

    @PostMapping("/{professionalId}")
    @PreAuthorize("hasRole('PROFESSIONAL')")
    public ResponseEntity<AvailabilityResponse> addAvailability(
            @PathVariable Long professionalId,
            @RequestBody AvailabilityRequest request) {

      AvailabilityResponse availabilityResponse = availabilityMapper.toResponse(
              availabilityService.createAvailability(professionalId, 
              availabilityMapper.toEntity(request)));

      return ResponseEntity.ok(availabilityResponse);
    }

    @GetMapping("/{professionalId}")
    public ResponseEntity<List<AvailabilityResponse>> getAvailability(
            @PathVariable Long professionalId,
            @RequestParam(required = false) 
            @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        List<Availability> result = date != null
                ? availabilityService.getAvailability(professionalId, date)
                : availabilityService.getAvailability(professionalId, null);
                
        return ResponseEntity.ok(result.stream().map(availabilityMapper::toResponse).toList());
    }
}

