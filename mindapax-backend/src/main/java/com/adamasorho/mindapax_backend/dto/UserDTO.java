package com.adamasorho.mindapax_backend.dto;

import com.adamasorho.mindapax_backend.model.enums.UserRole;

import lombok.Data;

@Data
public class UserDTO {
  private Long id;
  private String firstName;
  private String lastName;
  private String email;
  private UserRole role;
  private String phone;
  private String location;
  private boolean emailVerified;
  private boolean active;
}
