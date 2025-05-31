package com.adamasorho.mindapax_backend.integration;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.MethodOrderer;
import org.junit.jupiter.api.Order;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.TestMethodOrder;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;

import com.adamasorho.mindapax_backend.model.User;
import com.adamasorho.mindapax_backend.model.enums.UserRole;
import com.adamasorho.mindapax_backend.repository.UserRepository;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;

import jakarta.transaction.Transactional;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;

@SpringBootTest
@AutoConfigureMockMvc
@Transactional
@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
public class AuthControllerIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    private static String refreshToken;
    private static String accessToken;

    @BeforeEach
    void setup() {
        if (!userRepository.existsByEmail("testuser@example.com")) {
            User user = new User();
            user.setFirstName("Test");
            user.setLastName("User");
            user.setEmail("testuser@example.com");
            user.setPassword(passwordEncoder.encode("password123"));
            user.setRole(UserRole.USER);
            userRepository.save(user);
        }
    }

    @Test
    @Order(1)
    public void testLogin() throws Exception {
        String json = """
        {
            "email": "testuser@example.com",
            "password": "password123"
        }
        """;

        MvcResult result = mockMvc.perform(post("/api/v1/auth/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content(json))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.accessToken").exists())
                .andExpect(jsonPath("$.refreshToken").exists())
                .andReturn();

        String response = result.getResponse().getContentAsString();
        ObjectMapper mapper = new ObjectMapper();
        JsonNode root = mapper.readTree(response);
        accessToken = root.get("accessToken").asText();
        refreshToken = root.get("refreshToken").asText();
    }

    @Test
    @Order(2)
    public void testRefreshToken() throws Exception {
        String json = """
        {
            "refreshToken": "%s"
        }
        """.formatted(refreshToken);

        MvcResult result = mockMvc.perform(post("/api/v1/auth/refresh-token")
                .contentType(MediaType.APPLICATION_JSON)
                .content(json))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.accessToken").exists())
                .andExpect(jsonPath("$.refreshToken").exists())
                .andReturn();

        String response = result.getResponse().getContentAsString();
        ObjectMapper mapper = new ObjectMapper();
        JsonNode root = mapper.readTree(response);
        accessToken = root.get("accessToken").asText();
        refreshToken = root.get("refreshToken").asText();
    }

    @Test
    @Order(3)
    public void testLogout() throws Exception {
        String json = """
        {
            "refreshToken": "%s"
        }
        """.formatted(refreshToken);

        mockMvc.perform(post("/api/v1/auth/logout")
                .contentType(MediaType.APPLICATION_JSON)
                .content(json))
                .andExpect(status().isOk())
                .andExpect(content().string("Logout successful. Refresh token deleted."));
    }

    @Test
    @Order(4)
    public void testRefreshAfterLogoutFails() throws Exception {
        String json = """
        {
            "refreshToken": "%s"
        }
        """.formatted(refreshToken);

        mockMvc.perform(post("/api/v1/auth/refresh-token")
                .contentType(MediaType.APPLICATION_JSON)
                .content(json))
                .andExpect(status().is4xxClientError());
    }
}

