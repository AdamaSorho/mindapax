package com.adamasorho.mindapax_backend.dto.request;

import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class TransferConnectionRequest {
  @NotNull
  private Long professionalId;
  private String reason;
}

