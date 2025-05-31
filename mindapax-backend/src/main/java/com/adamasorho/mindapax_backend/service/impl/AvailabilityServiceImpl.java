package com.adamasorho.mindapax_backend.service.impl;

import java.time.LocalDate;
import java.util.List;

import org.springframework.stereotype.Service;

import com.adamasorho.mindapax_backend.model.Availability;
import com.adamasorho.mindapax_backend.model.Professional;
import com.adamasorho.mindapax_backend.repository.AvailabilityRepository;
import com.adamasorho.mindapax_backend.repository.ProfessionalRepository;
import com.adamasorho.mindapax_backend.service.AvailabilityService;

import jakarta.persistence.EntityNotFoundException;
import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class AvailabilityServiceImpl implements AvailabilityService {

    private final AvailabilityRepository availabilityRepository;
    private final ProfessionalRepository professionalRepository;

    @Override
    public Availability createAvailability(Long professionalId, Availability availability) {
        Professional professional = professionalRepository.findById(professionalId)
                .orElseThrow(() -> new EntityNotFoundException("Professional not found"));

        availability.setProfessional(professional);
        
        return availabilityRepository.save(availability);
    }

    @Override
    public List<Availability> getAvailability(Long professionalId, LocalDate date) {
        return availabilityRepository.findByProfessionalIdAndDate(professionalId, date);
    }
}

