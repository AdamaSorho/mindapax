package com.adamasorho.mindapax_backend.service.impl;

import io.awspring.cloud.s3.S3Resource;
import io.awspring.cloud.s3.S3Template;
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
import java.util.function.Consumer;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class S3StorageServiceTest {

    @Mock
    private S3Template s3Template;

    private S3StorageService s3StorageService;

    private final String BUCKET_NAME = "test-bucket";

    @BeforeEach
    void setUp() {
        s3StorageService = new S3StorageService(s3Template, BUCKET_NAME);
    }

    @Test
    void storeFile_shouldUploadFileToS3AndReturnKey() throws IOException {
        // Arrange
        MockMultipartFile multipartFile = new MockMultipartFile("file", "test.txt", "text/plain", "test data".getBytes());
        String subdirectory = "test-subdir";
        String expectedKeyPattern = subdirectory + "/[a-f0-9\\-]{36}\\.txt";

        // Mock S3Template behavior
        S3Resource mockS3Resource = org.mockito.Mockito.mock(S3Resource.class);
        when(s3Template.upload(eq(BUCKET_NAME), any(String.class), any(InputStream.class), any(Consumer.class)))
                .thenReturn(mockS3Resource);


        // Act
        String fileKey = s3StorageService.storeFile(multipartFile, subdirectory);

        // Assert
        assertNotNull(fileKey);
        assertTrue(fileKey.matches(expectedKeyPattern));

        ArgumentCaptor<Consumer<PutObjectRequest.Builder>> aclCaptor = ArgumentCaptor.forClass(Consumer.class);
        verify(s3Template).upload(eq(BUCKET_NAME), eq(fileKey), any(InputStream.class), aclCaptor.capture());

        // Verify ACL is set to private
        PutObjectRequest.Builder builder = PutObjectRequest.builder();
        aclCaptor.getValue().accept(builder);
        assertEquals(ObjectCannedACL.PRIVATE.toString(), builder.build().acl().toString());


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

        when(s3Template.upload(eq(BUCKET_NAME), any(String.class), any(InputStream.class), any(Consumer.class)))
                .thenThrow(new IOException("S3 upload failed"));
        // Act & Assert
        RuntimeException exception = assertThrows(RuntimeException.class, () -> {
            s3StorageService.storeFile(multipartFile, subdirectory);
        });
        assertTrue(exception.getMessage().contains("Could not store file test.txt"));
    }

    @Test
    void deleteFile_shouldCallS3TemplateDeleteObject() {
        // Arrange
        String filePath = "test-subdir/test-file.txt";

        // Act
        boolean result = s3StorageService.deleteFile(filePath);

        // Assert
        assertTrue(result);
        verify(s3Template).deleteObject(BUCKET_NAME, filePath);
    }

    @Test
    void deleteFile_shouldReturnFalseWhenExceptionOccurs() {
        // Arrange
        String filePath = "test-subdir/test-file.txt";
        org.mockito.Mockito.doThrow(new RuntimeException("S3 delete failed")).when(s3Template).deleteObject(BUCKET_NAME, filePath);

        // Act
        boolean result = s3StorageService.deleteFile(filePath);

        // Assert
        assertFalse(result);
        verify(s3Template).deleteObject(BUCKET_NAME, filePath);
    }

    @Test
    void storeFiles_shouldStoreAllFilesAndReturnKeys() throws IOException {
        // Arrange
        MockMultipartFile file1 = new MockMultipartFile("file1", "test1.txt", "text/plain", "test data 1".getBytes());
        MockMultipartFile file2 = new MockMultipartFile("file2", "test2.txt", "text/plain", "test data 2".getBytes());
        MultipartFile[] files = {file1, file2};
        String subdirectory = "test-subdir";

        S3Resource mockS3Resource = org.mockito.Mockito.mock(S3Resource.class);
        when(s3Template.upload(eq(BUCKET_NAME), any(String.class), any(InputStream.class), any(Consumer.class)))
                .thenReturn(mockS3Resource);

        // Act
        List<String> fileKeys = s3StorageService.storeFiles(files, subdirectory);

        // Assert
        assertEquals(2, fileKeys.size());
        assertTrue(fileKeys.get(0).startsWith(subdirectory + "/"));
        assertTrue(fileKeys.get(1).startsWith(subdirectory + "/"));
    }
}
