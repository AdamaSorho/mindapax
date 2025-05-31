package com.adamasorho.mindapax_backend.service.impl;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import com.adamasorho.mindapax_backend.exception.BadRequestException;
import com.adamasorho.mindapax_backend.model.User;
import com.adamasorho.mindapax_backend.repository.UserRepository;
import com.adamasorho.mindapax_backend.service.UserService;

import jakarta.persistence.EntityNotFoundException;
import lombok.AllArgsConstructor;

@Service
@AllArgsConstructor
public class UserServiceImpl implements UserService {
  private final UserRepository userRepository;
  private final PasswordEncoder passwordEncoder;

  @Override
  public User createUser(User user) {
    // Check if email already exists
    if (userRepository.existsByEmail(user.getEmail())) {
        throw new BadRequestException("Email is already in use");
    }
    user.setPassword(passwordEncoder.encode(user.getPassword()));

    return userRepository.save(user);
  }

  @Override
  public User getUserById(Long id) {
    return userRepository.findById(id)
        .orElseThrow(() -> new EntityNotFoundException("User not found"));
  }

  @Override
  public Page<User> getUsers(Pageable pageable) {
    return userRepository.findAll(pageable);
  }

  @Override
  public User updateUser(Long id, User user) {
    User existing = this.getUserById(id);

    existing.setFirstName(user.getFirstName());
    existing.setLastName(user.getLastName());
    existing.setPhone(user.getPhone());
    existing.setLocation(user.getLocation());
    // role and email can be updated conditionally

    return userRepository.save(existing);
  }

  @Override
  public void deleteUser(Long id) {
    userRepository.deleteById(id);
  }
}
