package com.adamasorho.mindapax_backend.service;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

import com.adamasorho.mindapax_backend.model.User;
import java.util.List;

import com.adamasorho.mindapax_backend.dto.request.UserProfileUpdateRequest;
import com.adamasorho.mindapax_backend.model.enums.UserRole;

public interface UserService {
  User createUser(User user);
  User getUserById(Long id);
  Page<User> getUsers(Pageable pageable);
  User updateUser(Long id, User user);
  User updateProfile(Long id, UserProfileUpdateRequest request);
  void deleteUser(Long id);
  List<User> getUsersByRole(UserRole role);
}
