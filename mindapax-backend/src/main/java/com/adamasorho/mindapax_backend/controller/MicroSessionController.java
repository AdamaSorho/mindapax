package com.adamasorho.mindapax_backend.controller;

import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.adamasorho.mindapax_backend.dto.request.MicroSessionRequest;
import com.adamasorho.mindapax_backend.dto.response.microsession.MicroSessionCompletionResponse;
import com.adamasorho.mindapax_backend.dto.response.microsession.MicroSessionResponse;
import com.adamasorho.mindapax_backend.model.MicroSession;
import com.adamasorho.mindapax_backend.model.User;
import com.adamasorho.mindapax_backend.model.enums.SelfGuidedDomain;
import com.adamasorho.mindapax_backend.security.CustomUserDetails;
import com.adamasorho.mindapax_backend.service.MicroSessionService;

import lombok.AllArgsConstructor;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;

@RestController
@RequestMapping("/api/v1/micro-sessions")
@AllArgsConstructor
public class MicroSessionController {

    private final MicroSessionService microSessionService;

    @GetMapping
    public ResponseEntity<List<MicroSessionResponse>> list(
            @RequestParam(required = false) SelfGuidedDomain domain,
            @RequestParam(required = false) String outcome) {
        List<MicroSession> sessions = microSessionService.list(
            Optional.ofNullable(domain),
            Optional.ofNullable(outcome));
        return ResponseEntity.ok(sessions.stream()
            .map(MicroSessionResponse::fromEntity)
            .collect(Collectors.toList()));
    }

    @GetMapping("/{id}")
    public ResponseEntity<MicroSessionResponse> get(@PathVariable Long id) {
        return ResponseEntity.ok(MicroSessionResponse.fromEntity(microSessionService.get(id)));
    }

    @PostMapping
    @PreAuthorize("hasRole('ROLE_ADMIN')")
    public ResponseEntity<MicroSessionResponse> create(@RequestBody MicroSessionRequest request) {
        MicroSession session = microSessionService.create(request);
        return ResponseEntity.ok(MicroSessionResponse.fromEntity(session));
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasRole('ROLE_ADMIN')")
    public ResponseEntity<MicroSessionResponse> update(
            @PathVariable Long id,
            @RequestBody MicroSessionRequest request) {
        MicroSession session = microSessionService.update(id, request);
        return ResponseEntity.ok(MicroSessionResponse.fromEntity(session));
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('ROLE_ADMIN')")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        microSessionService.delete(id);
        return ResponseEntity.noContent().build();
    }

    @PostMapping("/{id}/complete")
    public ResponseEntity<MicroSessionCompletionResponse> complete(@PathVariable Long id) {
        User user = currentUser();
        return ResponseEntity.ok(microSessionService.complete(user, id));
    }

    private User currentUser() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null || !(auth.getPrincipal() instanceof CustomUserDetails)) {
            throw new org.springframework.web.server.ResponseStatusException(
                org.springframework.http.HttpStatus.UNAUTHORIZED, "User not authenticated");
        }
        return ((CustomUserDetails) auth.getPrincipal()).getUser();
    }
}
