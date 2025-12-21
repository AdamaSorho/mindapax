package com.adamasorho.mindapax_backend.service;

import java.util.List;
import java.util.Optional;

import com.adamasorho.mindapax_backend.dto.request.MicroSessionRequest;
import com.adamasorho.mindapax_backend.model.MicroSession;
import com.adamasorho.mindapax_backend.model.User;
import com.adamasorho.mindapax_backend.model.enums.SelfGuidedDomain;

public interface MicroSessionService {
    List<MicroSession> list(Optional<SelfGuidedDomain> domain, Optional<String> outcome);
    MicroSession get(Long id);
    MicroSession create(MicroSessionRequest request);
    MicroSession update(Long id, MicroSessionRequest request);
    void delete(Long id);
    com.adamasorho.mindapax_backend.dto.response.microsession.MicroSessionCompletionResponse complete(User user, Long id);
}
