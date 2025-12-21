package com.adamasorho.mindapax_backend.repository;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.adamasorho.mindapax_backend.model.User;
import com.adamasorho.mindapax_backend.model.enums.UserRole;

@Repository
public interface UserRepository extends JpaRepository<User, Long> {
  Optional<User> findByEmail(String email);
  boolean existsByEmail(String email);
  List<User> findByRole(UserRole role);
} 
