package com.adamasorho.mindapax_backend.controller;

import java.time.LocalDate;
import java.util.HashSet;
import java.util.Set;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.web.PageableDefault;
import org.springframework.data.web.SortDefault;
import org.springframework.data.web.SortDefault.SortDefaults;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.adamasorho.mindapax_backend.dto.ProfessionalDTO;
import com.adamasorho.mindapax_backend.dto.UserDTO; // Added UserDTO import
import com.adamasorho.mindapax_backend.dto.response.PageResponse;
import com.adamasorho.mindapax_backend.mapper.ProfessionalMapper;
import com.adamasorho.mindapax_backend.model.Professional;
import com.adamasorho.mindapax_backend.model.enums.ProfessionalStatus;
import com.adamasorho.mindapax_backend.model.enums.Specialization;
import com.adamasorho.mindapax_backend.repository.ProfessionalRepository; // Added ProfessionalRepository import
import com.adamasorho.mindapax_backend.security.CustomUserDetails;
import com.adamasorho.mindapax_backend.service.ProfessionalService;

import jakarta.persistence.EntityNotFoundException; // Added EntityNotFoundException
import lombok.extern.slf4j.Slf4j;

@RestController
@RequestMapping("/api/v1/professionals")
@Slf4j
// @AllArgsConstructor // If you add a field, constructor injection is better
public class ProfessionalController {
  private final ProfessionalService professionalService;
  private final ProfessionalMapper professionalMapper;
  private final ProfessionalRepository professionalRepository; // Added

  // Constructor injection for all fields
  @Autowired
  public ProfessionalController(
      ProfessionalService professionalService,
      ProfessionalMapper professionalMapper,
      ProfessionalRepository professionalRepository) {
    this.professionalService = professionalService;
    this.professionalMapper = professionalMapper;
    this.professionalRepository = professionalRepository;
  }

  @PostMapping
  public ResponseEntity<ProfessionalDTO> create(@RequestBody ProfessionalDTO dto) {
    Professional professional = professionalMapper.toEntity(dto);

    return ResponseEntity.ok(professionalMapper.toDTO(professionalService.createProfessional(professional)));
  }

  @GetMapping("/{id}")
  public ResponseEntity<ProfessionalDTO> get(@PathVariable Long id) {
      return ResponseEntity.ok(professionalMapper.toDTO(professionalService.getProfessionalById(id)));
  }

  @GetMapping
  public ResponseEntity<PageResponse<ProfessionalDTO>> getAll(
    @RequestParam(required = false) String firstName,
    @RequestParam(required = false) String lastName,
    @RequestParam(required = false) Specialization specialization,
    @RequestParam(required = false) Integer experience,
    @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate availabilityDate,
    @RequestParam(required = false, defaultValue = "false") boolean availableOnly,
    @RequestParam(required = false, defaultValue = "false") boolean excludeConnected,
    @RequestParam(required = false) ProfessionalStatus status,
    @AuthenticationPrincipal UserDetails userDetails,
    @PageableDefault(size = 10) 
    @SortDefaults({@SortDefault(sort = "id", direction = Sort.Direction.DESC)}) Pageable pageable
  ) {
    Set<GrantedAuthority> authorities = new HashSet<>(userDetails.getAuthorities());
    Long requesterUserId = null;
    if (userDetails instanceof CustomUserDetails cud) {
      requesterUserId = cud.getUser().getId();
    }

    return ResponseEntity.ok(
        new PageResponse<ProfessionalDTO>(
          professionalService.getProfessionals(firstName, lastName, specialization, 
            experience, availabilityDate, availableOnly, status, excludeConnected, requesterUserId, authorities, pageable)
            .map(professionalMapper::toDTO)
        )
    );
  }

  @PutMapping("/{id}")
  public ResponseEntity<ProfessionalDTO> update(@PathVariable Long id, @RequestBody ProfessionalDTO dto) {
    Professional professional = professionalMapper.toEntity(dto);

    return ResponseEntity.ok(professionalMapper.toDTO(professionalService.updateProfessional(id, professional)));
  }

  @DeleteMapping("/{id}")
  public ResponseEntity<Void> delete(@PathVariable Long id) {
    professionalService.deleteProfessional(id);
    
    return ResponseEntity.noContent().build();
  }

  @PatchMapping("/{id}/status")
    public ResponseEntity<Void> updateProfessionalStatus(
            @PathVariable Long id,
            @RequestParam ProfessionalStatus status,
            @RequestParam(required = false) String rejectionNote,
            @AuthenticationPrincipal UserDetails userDetails) {
      Set<GrantedAuthority> authorities = new HashSet<>(userDetails.getAuthorities());

      professionalService.updateProfessionalStatus(id, status, rejectionNote, authorities);

      return ResponseEntity.ok().build();
    }

  @GetMapping("/status")
  public ResponseEntity<PageResponse<ProfessionalDTO>> getProfessionalsByStatus(
          @RequestParam ProfessionalStatus status,
          @AuthenticationPrincipal UserDetails userDetails,
          @PageableDefault(size = 10)
          @SortDefaults({
            @SortDefault(sort = "id", direction = Sort.Direction.DESC)
          }) Pageable pageable) {
      
      Set<GrantedAuthority> authorities = new HashSet<>(userDetails.getAuthorities());
      
      Page<Professional> page = professionalService.findProfessionalsByStatus(status, authorities, pageable);
      PageResponse<ProfessionalDTO> response = new PageResponse<>(page.map(professionalMapper::toDTO));

      return ResponseEntity.ok(response);
  }

  @GetMapping("/me/connected-users")
  @PreAuthorize("hasRole('PROFESSIONAL')")
  public ResponseEntity<Page<UserDTO>> getMyConnectedUsers(
          Authentication authentication,
          @PageableDefault(size = 20) Pageable pageable) {

      String professionalEmail = authentication.getName(); // Assuming email is username from UserDetails
      log.info("Professional authenticated name: {}", professionalEmail);

      Professional professional = professionalRepository.findByUserEmail(professionalEmail)
              .orElseThrow(() -> new EntityNotFoundException("Professional not found for email: " + professionalEmail));

      Page<UserDTO> connectedUsers = professionalService.getConnectedUsers(professional.getId(), pageable);
      return ResponseEntity.ok(connectedUsers);
  }

  @GetMapping("/me")
  @PreAuthorize("hasRole('PROFESSIONAL')")
  public ResponseEntity<ProfessionalDTO> getMyProfessionalProfile(Authentication authentication) {
      String email = authentication.getName();
      log.info("Fetching professional profile for authenticated user: {}", email);
      Professional professional = professionalRepository.findByUserEmail(email)
              .orElseThrow(() -> new EntityNotFoundException("Professional not found for email: " + email));
      return ResponseEntity.ok(professionalMapper.toDTO(professional));
  }
}
