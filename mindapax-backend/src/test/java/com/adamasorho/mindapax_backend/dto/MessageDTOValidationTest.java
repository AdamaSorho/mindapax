package com.adamasorho.mindapax_backend.dto;

import jakarta.validation.ConstraintViolation;
import jakarta.validation.Validation;
import jakarta.validation.Validator;
import jakarta.validation.ValidatorFactory;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;

import java.util.Set;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

public class MessageDTOValidationTest {

    private static Validator validator;

    @BeforeAll
    public static void setUpValidator() {
        ValidatorFactory factory = Validation.buildDefaultValidatorFactory();
        validator = factory.getValidator();
    }

    @Test
    public void testValidMessageDTO() {
        MessageDTO dto = new MessageDTO();
        dto.setSenderId(1L);
        dto.setContent("Valid content");
        // conversationId is not Blank/Null constrained
        // isRead has no validation

        Set<ConstraintViolation<MessageDTO>> violations = validator.validate(dto);
        assertTrue(violations.isEmpty(), "Should be no violations for a valid DTO");
    }

    @Test
    public void testMessageDTO_nullSenderId_expectViolation() {
        MessageDTO dto = new MessageDTO();
        dto.setSenderId(null); // Invalid
        dto.setContent("Some content");

        Set<ConstraintViolation<MessageDTO>> violations = validator.validate(dto);
        assertEquals(1, violations.size(), "Should be one violation for null senderId");
        ConstraintViolation<MessageDTO> violation = violations.iterator().next();
        assertEquals("Sender ID is required", violation.getMessage());
        assertEquals("senderId", violation.getPropertyPath().toString());
    }

    @Test
    public void testMessageDTO_blankContent_expectViolation() {
        MessageDTO dto = new MessageDTO();
        dto.setSenderId(1L);
        dto.setContent(""); // Invalid (blank)

        Set<ConstraintViolation<MessageDTO>> violations = validator.validate(dto);
        assertEquals(1, violations.size(), "Should be one violation for blank content");
        ConstraintViolation<MessageDTO> violation = violations.iterator().next();
        assertEquals("Content is required", violation.getMessage()); // Assuming this is the message from @NotBlank
        assertEquals("content", violation.getPropertyPath().toString());
    }

    @Test
    public void testMessageDTO_nullContent_expectViolation() {
        MessageDTO dto = new MessageDTO();
        dto.setSenderId(1L);
        dto.setContent(null); // Invalid (null for @NotBlank)

        Set<ConstraintViolation<MessageDTO>> violations = validator.validate(dto);
        assertEquals(1, violations.size(), "Should be one violation for null content");
        ConstraintViolation<MessageDTO> violation = violations.iterator().next();
        assertEquals("Content is required", violation.getMessage());
        assertEquals("content", violation.getPropertyPath().toString());
    }

    @Test
    public void testMessageDTO_multipleViolations() {
        MessageDTO dto = new MessageDTO();
        dto.setSenderId(null); // Invalid
        dto.setContent("");    // Invalid

        Set<ConstraintViolation<MessageDTO>> violations = validator.validate(dto);
        assertEquals(2, violations.size(), "Should be two violations");
    }
}
