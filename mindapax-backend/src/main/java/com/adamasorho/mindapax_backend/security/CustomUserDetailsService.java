package com.adamasorho.mindapax_backend.security;

import jakarta.persistence.EntityNotFoundException;
import lombok.AllArgsConstructor;

import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.stereotype.Service;

import com.adamasorho.mindapax_backend.model.User;
import com.adamasorho.mindapax_backend.repository.UserRepository;

@Service
@AllArgsConstructor
public class CustomUserDetailsService implements UserDetailsService {

    private final UserRepository repo;

    @Override
    public CustomUserDetails loadUserByUsername(String email) {
        User user = repo.findByEmail(email)
                .orElseThrow(() -> new EntityNotFoundException("User not found"));
        return new CustomUserDetails(user);
    }
}

