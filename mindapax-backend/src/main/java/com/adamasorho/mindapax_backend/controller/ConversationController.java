package com.adamasorho.mindapax_backend.controller;

import org.springframework.data.domain.Pageable;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.adamasorho.mindapax_backend.dto.request.conversationRequest;
import com.adamasorho.mindapax_backend.dto.response.ConversationResponse;
import com.adamasorho.mindapax_backend.dto.response.PageResponse;
import com.adamasorho.mindapax_backend.mapper.ConversationMapper;
import com.adamasorho.mindapax_backend.mapper.MessageMapper;
import com.adamasorho.mindapax_backend.service.ConversationService;
import com.adamasorho.mindapax_backend.service.MessageService;

import io.swagger.v3.oas.annotations.parameters.RequestBody;
import jakarta.validation.Valid;
import lombok.AllArgsConstructor;

@RestController
@RequestMapping("/api/v1/conversations")
@AllArgsConstructor
public class ConversationController {
  private final ConversationService conversationService;
  private final MessageService messageService;
  private final ConversationMapper conversationMapper;
  private final MessageMapper messageMapper;

  @PostMapping
  public ResponseEntity<ConversationResponse> startConversation(@RequestBody @Valid conversationRequest conversationRequest) {
    ConversationResponse conversationResponse = conversationMapper.toDTO(
      conversationService.startOrGetConversation(
        conversationRequest.getUserId(),
        conversationRequest.getProfessionalId()));
    conversationResponse.setLastMessage(messageMapper.toDTO(messageService.getLastMessage(conversationResponse.getId())));

    return ResponseEntity.ok(conversationResponse);
  }

  @GetMapping("/{userId}")
  public ResponseEntity<PageResponse<ConversationResponse>> getConversationsByUser(@PathVariable Long userId, 
    @PageableDefault(size = 10) Pageable pageable) {
    return ResponseEntity.ok(
      new PageResponse<ConversationResponse>(
      conversationService.getConversationsByUser(userId, pageable) // Service now returns Page<ConversationResponse>
      )
    );
  }
}
