package com.adamasorho.mindapax_backend.service;

import org.springframework.web.multipart.MultipartFile;

import com.adamasorho.mindapax_backend.dto.request.AuthRequest;
import com.adamasorho.mindapax_backend.model.User;

public interface AuthService {
  User register(AuthRequest authRequest, MultipartFile resume, MultipartFile[] certifications);
}
