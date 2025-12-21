package com.adamasorho.mindapax_backend.service.impl;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;
import org.springframework.web.multipart.MultipartFile;

import com.adamasorho.mindapax_backend.exception.BadRequestException;
import java.util.List;

import com.adamasorho.mindapax_backend.model.User;
import com.adamasorho.mindapax_backend.model.enums.UserRole;
import com.adamasorho.mindapax_backend.repository.UserRepository;
import com.adamasorho.mindapax_backend.service.UserService;
import com.adamasorho.mindapax_backend.service.FileStorageService;
import com.adamasorho.mindapax_backend.dto.request.UserProfileUpdateRequest;

import jakarta.persistence.EntityNotFoundException;
import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class UserServiceImpl implements UserService {
  private final UserRepository userRepository;
  private final PasswordEncoder passwordEncoder;
  private final FileStorageService fileStorageService;
  @Value("${app.file-storage.max-avatar-size-bytes:2097152}")
  private long maxAvatarSizeBytes;

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
  public User updateProfile(Long id, UserProfileUpdateRequest request) {
    User existing = this.getUserById(id);

    if (StringUtils.hasText(request.getFirstName())) {
      existing.setFirstName(request.getFirstName().trim());
    }
    if (StringUtils.hasText(request.getLastName())) {
      existing.setLastName(request.getLastName().trim());
    }
    if (request.getPhone() != null) {
      String phone = request.getPhone().trim();
      existing.setPhone(phone.isEmpty() ? null : phone);
    }
    if (request.getLocation() != null) {
      String location = request.getLocation().trim();
      existing.setLocation(location.isEmpty() ? null : location);
    }

    boolean removeAvatar = Boolean.TRUE.equals(request.getRemoveAvatar());
    MultipartFile avatar = request.getAvatar();
    if (avatar != null && !avatar.isEmpty()) {
      if (maxAvatarSizeBytes > 0 && avatar.getSize() > maxAvatarSizeBytes) {
        double maxMb = maxAvatarSizeBytes / 1024.0 / 1024.0;
        throw new BadRequestException(
            String.format("Avatar exceeds maximum allowed size of %.1f MB", maxMb));
      }
      if (StringUtils.hasText(existing.getAvatarFilePath())) {
        fileStorageService.deleteFile(existing.getAvatarFilePath());
      }
      String storedPath = fileStorageService.storeFile(avatar, "avatars");
      existing.setAvatarFilePath(storedPath);
      existing.setAvatarUrl(fileStorageService.getFileUrl(storedPath));
      removeAvatar = false;
    }

    if (removeAvatar && StringUtils.hasText(existing.getAvatarFilePath())) {
      fileStorageService.deleteFile(existing.getAvatarFilePath());
      existing.setAvatarFilePath(null);
      existing.setAvatarUrl(null);
    }

    return userRepository.save(existing);
  }

  @Override
  public void deleteUser(Long id) {
    userRepository.deleteById(id);
  }

  @Override
  public List<User> getUsersByRole(UserRole role) {
    return userRepository.findByRole(role);
  }
}
