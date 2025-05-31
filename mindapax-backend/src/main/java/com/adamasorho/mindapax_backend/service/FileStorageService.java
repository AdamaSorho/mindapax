package com.adamasorho.mindapax_backend.service;

import java.util.List;

import org.springframework.web.multipart.MultipartFile;

public interface FileStorageService {
  String storeFile(MultipartFile file, String subdirectory);
  List<String> storeFiles(MultipartFile[] files, String subdirectory);
  boolean deleteFile(String filePath);
}
