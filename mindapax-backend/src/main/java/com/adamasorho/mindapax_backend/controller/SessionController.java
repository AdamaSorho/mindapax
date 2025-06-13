package com.adamasorho.mindapax_backend.controller;

import java.time.OffsetDateTime;
import java.util.List;

import com.adamasorho.mindapax_backend.dto.ZoomSignatureResponse;
import com.adamasorho.mindapax_backend.model.enums.SessionMode;
import com.adamasorho.mindapax_backend.security.CustomUserDetails;
import com.adamasorho.mindapax_backend.service.ZoomService;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.web.PageableDefault;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

import com.adamasorho.mindapax_backend.dto.SessionDTO;
import com.adamasorho.mindapax_backend.dto.SessionTimeFilter;
import com.adamasorho.mindapax_backend.mapper.SessionMapper;
import com.adamasorho.mindapax_backend.model.Session;
import com.adamasorho.mindapax_backend.model.enums.SessionStatus;
import com.adamasorho.mindapax_backend.service.SessionService;

import jakarta.validation.Valid;
import lombok.AllArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@RestController
@RequestMapping("/api/v1/sessions")
@AllArgsConstructor
@Slf4j
public class SessionController {
  private final SessionService serviceService;
  private final SessionMapper sessionMapper;
  private final ZoomService zoomService;

  @PostMapping
  public ResponseEntity<SessionDTO> create(@RequestBody SessionDTO dto) {
    return ResponseEntity.ok(serviceService.createSession(dto));
  }

  @GetMapping("/{id}")
  public ResponseEntity<SessionDTO> get(@PathVariable Long id) {
    return ResponseEntity.ok(serviceService.getSessionById(id));
  }

  @GetMapping
  public ResponseEntity<List<SessionDTO>> getAll() {
    return ResponseEntity.ok(serviceService.getAllSessions());
  }

  @GetMapping("/user/{userId}")
  public ResponseEntity<List<SessionDTO>> getByUser(@PathVariable Long userId) {
    return ResponseEntity.ok(serviceService.getSessionsByUserId(userId));
  }

  @PutMapping("/{id}/status")
  public ResponseEntity<SessionDTO> updateStatus(@PathVariable Long id, @RequestBody SessionDTO dto) {
    return ResponseEntity.ok(serviceService.updateSessionStatus(id, dto));
  }

  @DeleteMapping("/{id}")
  public ResponseEntity<Void> delete(@PathVariable Long id) {
    serviceService.deleteSession(id);
    return ResponseEntity.noContent().build();
  }

  @GetMapping("/by-user")
public ResponseEntity<Page<SessionDTO>> getSessionsByUser(
      @RequestParam Long userId,
      @RequestParam(required = false)
      @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) OffsetDateTime date,
      @RequestParam SessionTimeFilter filter,
      @RequestParam(required = false) SessionStatus status,
      @PageableDefault(size = 10) Pageable pageable) {

  OffsetDateTime effectiveDate = (date != null) ? date : OffsetDateTime.now();

  Page<Session> sessions = serviceService.getSessionsByUserAndTime(userId, effectiveDate, filter, status, pageable);
  Page<SessionDTO> dtos = sessions.map(sessionMapper::toDTO);

  return ResponseEntity.ok(dtos);
}

  @PostMapping("/professional/schedule")
  @PreAuthorize("hasRole('ROLE_PROFESSIONAL')")
  public ResponseEntity<SessionDTO> scheduleByProfessional(@RequestBody @Valid SessionDTO sessionDto) {
      SessionDTO createdSession = serviceService.scheduleSessionByProfessional(sessionDto);
      return ResponseEntity.status(HttpStatus.CREATED).body(createdSession);
  }

    @PostMapping("/{sessionId}/join-video")
    @PreAuthorize("hasAnyRole('ROLE_USER', 'ROLE_PROFESSIONAL')") // Ensure only authenticated users can access
    public ResponseEntity<ZoomSignatureResponse> joinVideoSession(@PathVariable Long sessionId) {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || !(authentication.getPrincipal() instanceof CustomUserDetails)) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "User not authenticated");
        }
        CustomUserDetails currentUserDetails = (CustomUserDetails) authentication.getPrincipal();
        Long currentUserId = currentUserDetails.getUser().getId();

        Session session = serviceService.getSessionEntityById(sessionId); // Uses new service method
        if (session == null) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Session not found");
        }

        if (session.getMode() != SessionMode.VIDEO) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Session is not a video session");
        }

        // Validate user is part of the session
        Long clientUserId = session.getUser().getId();
        Long professionalUserId = session.getProfessional().getUser().getId();

        boolean isClient = currentUserId.equals(clientUserId);
        boolean isProfessional = currentUserId.equals(professionalUserId);

        if (!isClient && !isProfessional) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "User not part of this session");
        }

        // Determine Zoom role (e.g., Professional is host (1), Client is attendee (0))
        int zoomRole = isProfessional ? 1 : 0;

        // Use session ID as the meeting number for simplicity.
        if (session.getZoomMeetingId() == null || session.getZoomMeetingId().trim().isEmpty()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Zoom meeting ID is not configured for this session.");
        }
        String meetingNumber = session.getZoomMeetingId();

        String signature = zoomService.generateSignature(meetingNumber, zoomRole);
        String sdkKey = zoomService.getSdkKey();

        return ResponseEntity.ok(new ZoomSignatureResponse(sdkKey, meetingNumber, signature));
    }
}
