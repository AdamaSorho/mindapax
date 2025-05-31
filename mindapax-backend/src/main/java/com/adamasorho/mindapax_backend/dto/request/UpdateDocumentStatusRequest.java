package com.adamasorho.mindapax_backend.dto.request;

import com.adamasorho.mindapax_backend.model.enums.DocumentStatus;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class UpdateDocumentStatusRequest {
    private DocumentStatus status;
    private String adminNote;
}

