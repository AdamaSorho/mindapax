package com.adamasorho.mindapax_backend.controller;

import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestPart;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import com.adamasorho.mindapax_backend.dto.AuthResponse;
import com.adamasorho.mindapax_backend.dto.LogoutRequest;
import com.adamasorho.mindapax_backend.dto.RefreshTokenRequest;
import com.adamasorho.mindapax_backend.dto.UserDTO;
import com.adamasorho.mindapax_backend.dto.request.AuthRequest;
import com.adamasorho.mindapax_backend.dto.request.LoginRequest;
import com.adamasorho.mindapax_backend.dto.response.MessageResponse;
import com.adamasorho.mindapax_backend.mapper.UserMapper;
import com.adamasorho.mindapax_backend.model.RefreshToken;
import com.adamasorho.mindapax_backend.model.User;
import com.adamasorho.mindapax_backend.model.enums.Specialization;
import com.adamasorho.mindapax_backend.model.enums.UserRole;
import com.adamasorho.mindapax_backend.security.CustomUserDetails;
import com.adamasorho.mindapax_backend.security.CustomUserDetailsService;
import com.adamasorho.mindapax_backend.security.JwtUtils;
import com.adamasorho.mindapax_backend.service.AuthService;
import com.adamasorho.mindapax_backend.service.RefreshTokenService;

import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.AllArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@Tag(name = "Authentication")
@RestController
@RequestMapping("/api/v1/auth")
@AllArgsConstructor
@Slf4j
public class AuthController {

    private final AuthenticationManager authManager;
    private final CustomUserDetailsService userDetailsService;
    private final JwtUtils jwtUtils;
    private final RefreshTokenService refreshTokenService;
    private final UserMapper userMapper;
    private final AuthService authService;

    @PostMapping("/login")
    public ResponseEntity<AuthResponse> login(@RequestBody @Valid LoginRequest request) {
        Authentication auth = new UsernamePasswordAuthenticationToken(request.getEmail(), request.getPassword());
        authManager.authenticate(auth);

        CustomUserDetails userDetails = userDetailsService.loadUserByUsername(request.getEmail());
        String accessToken = jwtUtils.generateAccessToken(userDetails);
        RefreshToken refreshToken = refreshTokenService.createRefreshToken(userDetails.getUser());

        Long expiresIn = 15 * 60L; // 15 minutes in seconds

        return ResponseEntity.ok(new AuthResponse(accessToken, refreshToken.getToken(), expiresIn));
    }
    
    @PostMapping(value = "/register", consumes = {MediaType.MULTIPART_FORM_DATA_VALUE})
    public ResponseEntity<UserDTO> register(
        @RequestPart("firstName") String firstName,
        @RequestPart("lastName") String lastName,
        @RequestPart("email") String email,
        @RequestPart("password") String password,
        @RequestPart("role") String role,
        @RequestPart("agreeTerms") String agreeTerms,
        @RequestPart(value = "professionalDetails.specialization", required = false) String specialization,
        @RequestPart(value = "professionalDetails.experienceYears", required = false) String experienceYears,
        @RequestPart(value = "resume", required = false) MultipartFile resume,
        @RequestPart(value = "certifications", required = false) MultipartFile[] certifications
    ) {
        AuthRequest.ProfessionalDetailsDto professionalDetails = null;

        if (role.equals(UserRole.PROFESSIONAL.name())){ 
            log.debug("Professional details: specialization={}, experienceYears={}", specialization, experienceYears);
            professionalDetails = AuthRequest.ProfessionalDetailsDto.builder()
                .specialization(Specialization.valueOf(specialization))
                .experienceYears(Integer.parseInt(experienceYears))
                .build();
        }
        else{
            log.debug("User creation, role={}, email={}", role, UserRole.PROFESSIONAL.name());
        }

        AuthRequest request = AuthRequest.builder()
                .firstName(firstName)
                .lastName(lastName)
                .email(email)
                .password(password)
                .role(UserRole.valueOf(role))
                .agreeTerms(Boolean.parseBoolean(agreeTerms))
                .professionalDetails(professionalDetails)
                .build();
        
        return ResponseEntity.status(HttpStatus.CREATED)
            .body(userMapper.toDTO(authService.register(request, resume, certifications)));
    }

    @PostMapping("/refresh-token")
    public ResponseEntity<AuthResponse> refreshToken(@RequestBody RefreshTokenRequest request) {
        String requestToken = request.getRefreshToken();

        RefreshToken refreshToken = refreshTokenService.findByToken(requestToken)
                .map(refreshTokenService::verifyExpiration)
                .orElseThrow(() -> new RuntimeException("Refresh token not found"));

        User user = refreshToken.getUser();

        String newAccessToken = jwtUtils.generateAccessToken(user);
        RefreshToken newRefreshToken = refreshTokenService.createRefreshToken(user); // Optional: Rotate token

        Long expiresIn = 15 * 60L; // 15 minutes in seconds

        return ResponseEntity.ok(new AuthResponse(newAccessToken, newRefreshToken.getToken(), expiresIn));
    }

    @PostMapping("/logout")
    public ResponseEntity<MessageResponse> logout(@RequestBody @Valid LogoutRequest request) {
        String refreshToken = request.getRefreshToken();
        
        RefreshToken token = refreshTokenService.findByToken(refreshToken)
                .orElseThrow(() -> new RuntimeException("Refresh token not found"));

        refreshTokenService.deleteByUser(token.getUser());

        return ResponseEntity.ok(new MessageResponse("Logout successful. Refresh token deleted."));
    }

}

