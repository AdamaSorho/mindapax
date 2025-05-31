package com.adamasorho.mindapax_backend.controller;

import org.springframework.data.domain.Pageable;
import org.springframework.data.web.PageableDefault;
import org.springframework.data.web.SortDefault;
import org.springframework.data.web.SortDefault.SortDefaults;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.data.domain.Sort;

import com.adamasorho.mindapax_backend.dto.MessageDTO;
import com.adamasorho.mindapax_backend.dto.response.PageResponse;
import com.adamasorho.mindapax_backend.mapper.MessageMapper;
import com.adamasorho.mindapax_backend.service.MessageService;

import jakarta.validation.Valid;
import lombok.AllArgsConstructor;

@RestController
@RequestMapping("/api/v1/messages")
@AllArgsConstructor
public class MessageController {
  private final MessageService messageService;
  private final MessageMapper messageMapper;

  @PostMapping
  public ResponseEntity<MessageDTO> send(@RequestBody @Valid MessageDTO dto) {
    // Message message = messageMapper.toEntity(dto);
    
    return ResponseEntity.ok(messageMapper.toDTO(messageService.sendMessage(dto)));
  }

    @GetMapping
    public ResponseEntity<PageResponse<MessageDTO>> getMessages(
            @RequestParam Long conversationId,
            @PageableDefault(size = 10) 
            @SortDefaults({
                @SortDefault(sort = "timestamp", direction = Sort.Direction.DESC)
            })
            Pageable pageable) {
        return ResponseEntity.ok(
            new PageResponse<MessageDTO>(
                messageService.getMessageHistory(conversationId, pageable)
                    .map(messageMapper::toDTO)
            )
        );
    }
}
