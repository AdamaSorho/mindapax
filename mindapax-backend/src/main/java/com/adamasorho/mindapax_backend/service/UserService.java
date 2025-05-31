package com.adamasorho.mindapax_backend.service;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

import com.adamasorho.mindapax_backend.model.User;

public interface UserService {
  User createUser(User user);
  User getUserById(Long id);
  Page<User> getUsers(Pageable pageable);
  User updateUser(Long id, User user);
  void deleteUser(Long id);
}
