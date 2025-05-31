package com.adamasorho.mindapax_backend.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class CertificationDTO {
  private Long id;
  private String filePath;
  private String name;
  private String fileType;
  private Long fileSize;
}
