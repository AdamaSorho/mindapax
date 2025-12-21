package com.adamasorho.mindapax_backend.dto.request;

import org.springframework.web.multipart.MultipartFile;

import lombok.Data;

@Data
public class UserProfileUpdateRequest {
  private String firstName;
  private String lastName;
  private String phone;
  private String location;
  private Boolean removeAvatar;
  private MultipartFile avatar;
}
