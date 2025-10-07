package com.adamasorho.mindapax_backend.controller.admin;

import java.util.List;
import java.util.stream.Collectors;

import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import com.adamasorho.mindapax_backend.dto.subscription.PlanDTO;
import com.adamasorho.mindapax_backend.mapper.PlanMapper;
import com.adamasorho.mindapax_backend.model.Plan;
import com.adamasorho.mindapax_backend.repository.PlanRepository;

import lombok.RequiredArgsConstructor;

@RestController
@RequestMapping("/api/v1/admin/plans")
@PreAuthorize("hasRole('ADMIN')")
@RequiredArgsConstructor
public class PlanAdminController {
    private final PlanRepository planRepo;
    private final PlanMapper mapper;

    @GetMapping
    public ResponseEntity<List<PlanDTO>> list() {
        return ResponseEntity.ok(planRepo.findAll().stream().map(mapper::toDTO).collect(Collectors.toList()));
    }

    @PostMapping
    public ResponseEntity<PlanDTO> create(@RequestBody PlanDTO dto) {
        Plan p = mapper.toEntity(dto);
        p.setId(null);
        return ResponseEntity.ok(mapper.toDTO(planRepo.save(p)));
    }

    @PutMapping("/{id}")
    public ResponseEntity<PlanDTO> update(@PathVariable Long id, @RequestBody PlanDTO dto) {
        Plan existing = planRepo.findById(id).orElseThrow();
        Plan p = mapper.toEntity(dto);
        p.setId(existing.getId());
        return ResponseEntity.ok(mapper.toDTO(planRepo.save(p)));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        if (planRepo.existsById(id)) planRepo.deleteById(id);
        return ResponseEntity.noContent().build();
    }
}

