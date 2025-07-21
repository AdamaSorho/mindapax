package com.adamasorho.mindapax_backend.service.impl;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;
import org.springframework.web.multipart.MultipartFile;

import com.adamasorho.mindapax_backend.service.FileStorageService;
import org.springframework.context.annotation.Profile;

@Service
@Profile("filesystem")
public class FileStorageServiceImpl implements FileStorageService {
  private final Path fileStorageLocation;

    public FileStorageServiceImpl(@Value("${app.file-storage.upload-dir:uploads}") String uploadDir) {
        this.fileStorageLocation = Paths.get(uploadDir).toAbsolutePath().normalize();
        
        try {
            Files.createDirectories(this.fileStorageLocation);
        } catch (IOException ex) {
            throw new RuntimeException("Could not create the directory where the uploaded files will be stored", ex);
        }
    }

    @Override
    public String storeFile(MultipartFile file, String subdirectory) {
        try {
            // Create subdirectory if it doesn't exist
            Path targetLocation = this.fileStorageLocation.resolve(subdirectory);
            Files.createDirectories(targetLocation);
            
            // Generate a unique file name to prevent collisions
            String originalFileName = Optional.ofNullable(file.getOriginalFilename())
                .map(StringUtils::cleanPath)
                .orElseThrow(() -> new RuntimeException("Original file name is null"));
            String fileExtension = "";
            
            int dotIndex = originalFileName.lastIndexOf('.');
            if (dotIndex > 0) {
                fileExtension = originalFileName.substring(dotIndex);
            }
            
            String uniqueFileName = UUID.randomUUID().toString() + fileExtension;
            
            // Store the file
            Path filePath = targetLocation.resolve(uniqueFileName);
            Files.copy(file.getInputStream(), filePath, StandardCopyOption.REPLACE_EXISTING);
            
            return subdirectory + "/" + uniqueFileName;
        } catch (IOException ex) {
            throw new RuntimeException("Could not store file " + file.getOriginalFilename(), ex);
        }
    }

    @Override
    public List<String> storeFiles(MultipartFile[] files, String subdirectory) {
        List<String> filePaths = new ArrayList<>();
        for (MultipartFile file : files) {
            filePaths.add(storeFile(file, subdirectory));
        }
        return filePaths;
    }

    public boolean deleteFile(String filePath) {
        try {
            Path path = this.fileStorageLocation.resolve(filePath);
            return Files.deleteIfExists(path);
        } catch (IOException ex) {
            return false;
        }
    }

    @Override
    public String getFileUrl(String key) {
        return "/uploads/" + key;
    }
}
