package com.adamasorho.mindapax_backend.service.impl;

import com.adamasorho.mindapax_backend.service.FileStorageService;
import io.awspring.cloud.s3.S3Template;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;
import org.springframework.web.multipart.MultipartFile;
import software.amazon.awssdk.services.s3.model.ObjectCannedACL;
import software.amazon.awssdk.services.s3.model.PutObjectRequest;

import java.io.IOException;
import java.util.function.Consumer;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Service
@Profile("s3")
public class S3StorageService implements FileStorageService {

    private final S3Template s3Template;
    private final String bucketName;

    public S3StorageService(S3Template s3Template, @Value("${spring.cloud.aws.s3.bucket-name}") String bucketName) {
        this.s3Template = s3Template;
        this.bucketName = bucketName;
    }

    @Override
    public String storeFile(MultipartFile file, String subdirectory) {
        String originalFileName = Optional.ofNullable(file.getOriginalFilename())
                .map(StringUtils::cleanPath)
                .orElseThrow(() -> new RuntimeException("Original file name is null"));
        String fileExtension = "";
        int dotIndex = originalFileName.lastIndexOf('.');
        if (dotIndex > 0) {
            fileExtension = originalFileName.substring(dotIndex);
        }
        String uniqueFileName = UUID.randomUUID().toString() + fileExtension;
        String key = subdirectory + "/" + uniqueFileName;

        try {
            Consumer<PutObjectRequest.Builder> putObjectRequestCallback = builder -> builder
                    .acl(ObjectCannedACL.PRIVATE)
                    .contentType(file.getContentType());

            s3Template.upload(bucketName, key, file.getInputStream(), putObjectRequestCallback);
            return key;
        } catch (IOException e) {
            throw new RuntimeException("Could not store file " + originalFileName, e);
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

    @Override
    public boolean deleteFile(String filePath) {
        try {
            s3Template.deleteObject(bucketName, filePath);
            return true;
        } catch (Exception e) {
            // Log the exception
            return false;
        }
    }
}
