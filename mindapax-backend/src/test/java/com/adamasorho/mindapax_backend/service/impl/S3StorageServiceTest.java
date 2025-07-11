package com.adamasorho.mindapax_backend.service.impl;

import software.amazon.awssdk.core.sync.RequestBody;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.DeleteObjectRequest;
import software.amazon.awssdk.services.s3.model.DeleteObjectResponse;
import software.amazon.awssdk.services.s3.model.PutObjectResponse;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.web.multipart.MultipartFile;
import software.amazon.awssdk.services.s3.model.ObjectCannedACL;
import software.amazon.awssdk.services.s3.model.PutObjectRequest;

import java.io.IOException;
import java.io.InputStream;


import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class S3StorageServiceTest {

    @Mock
    private S3Client s3Client;

    private S3StorageService s3StorageService;

    private final String BUCKET_NAME = "test-bucket";

    @BeforeEach
    void setUp() {
        s3StorageService = new S3StorageService(s3Client, BUCKET_NAME);
    }

    @Test
    void storeFile_shouldUploadFileToS3AndReturnKey() throws IOException {
        // Arrange
        MockMultipartFile multipartFile = new MockMultipartFile("file", "test.txt", "text/plain", "test data".getBytes());
        String subdirectory = "test-subdir";
        String expectedKeyPattern = subdirectory + "/[a-f0-9\\-]{36}\\.txt";

        // Mock S3Client behavior
        when(s3Client.putObject(any(PutObjectRequest.class), any(RequestBody.class)))
                .thenReturn(PutObjectResponse.builder().build());

        // Act
        String fileKey = s3StorageService.storeFile(multipartFile, subdirectory);

        // Assert
        assertNotNull(fileKey);
        assertTrue(fileKey.matches(expectedKeyPattern));

        ArgumentCaptor<PutObjectRequest> putObjectRequestCaptor = ArgumentCaptor.forClass(PutObjectRequest.class);
        ArgumentCaptor<RequestBody> requestBodyCaptor = ArgumentCaptor.forClass(RequestBody.class);
        verify(s3Client).putObject(putObjectRequestCaptor.capture(), requestBodyCaptor.capture());

        PutObjectRequest capturedRequest = putObjectRequestCaptor.getValue();
        assertEquals(BUCKET_NAME, capturedRequest.bucket());
        assertEquals(fileKey, capturedRequest.key());
        assertEquals(ObjectCannedACL.PRIVATE, capturedRequest.acl());
        assertEquals("text/plain", capturedRequest.contentType());
        assertEquals(multipartFile.getSize(), requestBodyCaptor.getValue().contentLength());
    }

    @Test
    void storeFile_shouldThrowRuntimeExceptionWhenOriginalFileNameIsNull() {
        // Arrange
        MockMultipartFile multipartFile = new MockMultipartFile("file", null, "text/plain", "test data".getBytes());
        String subdirectory = "test-subdir";

        // Act & Assert
        RuntimeException exception = assertThrows(RuntimeException.class, () -> {
            s3StorageService.storeFile(multipartFile, subdirectory);
        });
        assertEquals("Original file name is null", exception.getMessage());
    }

    @Test
    void storeFile_shouldThrowRuntimeExceptionWhenIOExceptionOccurs() throws IOException {
        // Arrange
        MockMultipartFile multipartFile = new MockMultipartFile("file", "test.txt", "text/plain", "test data".getBytes());
        String subdirectory = "test-subdir";

        when(s3Client.putObject(any(PutObjectRequest.class), any(RequestBody.class)))
                .thenThrow(new RuntimeException("S3 putObject failed")); // Use a generic SdkClientException or specific S3Exception if needed

        // Act & Assert
        RuntimeException exception = assertThrows(RuntimeException.class, () -> {
            s3StorageService.storeFile(multipartFile, subdirectory);
        });
        // The message comes from the service, not the S3 SDK directly in this case, as it catches and re-throws.
        assertTrue(exception.getMessage().contains("Could not store file test.txt"));
    }

    @Test
    void deleteFile_shouldCallS3ClientDeleteObject() {
        // Arrange
        String filePath = "test-subdir/test-file.txt";
        when(s3Client.deleteObject(any(DeleteObjectRequest.class)))
                .thenReturn(DeleteObjectResponse.builder().build());

        // Act
        boolean result = s3StorageService.deleteFile(filePath);

        // Assert
        assertTrue(result);
        ArgumentCaptor<DeleteObjectRequest> deleteObjectRequestCaptor = ArgumentCaptor.forClass(DeleteObjectRequest.class);
        verify(s3Client).deleteObject(deleteObjectRequestCaptor.capture());
        assertEquals(BUCKET_NAME, deleteObjectRequestCaptor.getValue().bucket());
        assertEquals(filePath, deleteObjectRequestCaptor.getValue().key());
    }

    @Test
    void deleteFile_shouldReturnFalseWhenExceptionOccurs() {
        // Arrange
        String filePath = "test-subdir/test-file.txt";
        when(s3Client.deleteObject(any(DeleteObjectRequest.class)))
                .thenThrow(new RuntimeException("S3 deleteObject failed"));

        // Act
        boolean result = s3StorageService.deleteFile(filePath);

        // Assert
        assertFalse(result);
        verify(s3Client).deleteObject(any(DeleteObjectRequest.class));
    }

    @Test
    void storeFiles_shouldStoreAllFilesAndReturnKeys() throws IOException {
        // Arrange
        MockMultipartFile file1 = new MockMultipartFile("file1", "test1.txt", "text/plain", "test data 1".getBytes());
        MockMultipartFile file2 = new MockMultipartFile("file2", "test2.txt", "text/plain", "test data 2".getBytes());
        MultipartFile[] files = {file1, file2};
        String subdirectory = "test-subdir";

        when(s3Client.putObject(any(PutObjectRequest.class), any(RequestBody.class)))
                .thenReturn(PutObjectResponse.builder().build());

        // Act
        List<String> fileKeys = s3StorageService.storeFiles(files, subdirectory);

        // Assert
        assertEquals(2, fileKeys.size());
        assertTrue(fileKeys.get(0).startsWith(subdirectory + "/"));
        assertTrue(fileKeys.get(1).startsWith(subdirectory + "/"));
    }
}
