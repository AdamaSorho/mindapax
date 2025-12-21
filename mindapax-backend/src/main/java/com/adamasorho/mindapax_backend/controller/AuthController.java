package com.adamasorho.mindapax_backend.controller;

import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import java.util.Map;

import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestPart;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.server.ResponseStatusException;

import com.adamasorho.mindapax_backend.dto.AuthResponse;
import com.adamasorho.mindapax_backend.dto.LogoutRequest;
import com.adamasorho.mindapax_backend.dto.RefreshTokenRequest;
import com.adamasorho.mindapax_backend.dto.UserDTO;
import com.adamasorho.mindapax_backend.dto.request.AuthRequest;
import com.adamasorho.mindapax_backend.dto.request.ForgotPasswordRequest;
import com.adamasorho.mindapax_backend.dto.request.LoginRequest;
import com.adamasorho.mindapax_backend.dto.request.ResetPasswordRequest;
import com.adamasorho.mindapax_backend.mapper.UserMapper;
import com.adamasorho.mindapax_backend.model.RefreshToken;
import com.adamasorho.mindapax_backend.model.User;
import com.adamasorho.mindapax_backend.model.enums.Specialization;
import com.adamasorho.mindapax_backend.model.enums.UserRole;
import com.adamasorho.mindapax_backend.security.CustomUserDetails;
import com.adamasorho.mindapax_backend.security.CustomUserDetailsService;
import com.adamasorho.mindapax_backend.security.JwtUtils;
import com.adamasorho.mindapax_backend.service.AuthService;
import com.adamasorho.mindapax_backend.service.PasswordResetService;
import com.adamasorho.mindapax_backend.service.RefreshTokenService;
import com.adamasorho.mindapax_backend.service.TwoFactorService;

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
    private final TwoFactorService twoFactorService;
    private final PasswordResetService passwordResetService;

    @PostMapping("/login")
    public ResponseEntity<AuthResponse> login(@RequestBody @Valid LoginRequest request) {
        Authentication auth = new UsernamePasswordAuthenticationToken(request.getEmail(), request.getPassword());
        authManager.authenticate(auth);

        CustomUserDetails userDetails = userDetailsService.loadUserByUsername(request.getEmail());
        User user = userDetails.getUser();

        if (user.isTwoFactorEnabled()) {
            String code = request.getTwoFactorCode();
            if (code == null || code.isBlank()) {
                throw new ResponseStatusException(
                    HttpStatus.UNAUTHORIZED, "TWO_FACTOR_CODE_REQUIRED");
            }
            if (!twoFactorService.verifyCode(user, code)) {
                throw new ResponseStatusException(
                    HttpStatus.UNAUTHORIZED, "INVALID_TWO_FACTOR_CODE");
            }
        }

        String accessToken = jwtUtils.generateAccessToken(userDetails);
        boolean rememberMe = Boolean.TRUE.equals(request.getRememberMe());
        RefreshToken refreshToken = refreshTokenService.createRefreshToken(user, rememberMe);

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
        if (requestToken == null || requestToken.isBlank()) {
            throw new org.springframework.web.server.ResponseStatusException(
                HttpStatus.UNAUTHORIZED, "Refresh token is required"
            );
        }

        RefreshToken refreshToken = refreshTokenService.findByToken(requestToken)
                .map(refreshTokenService::verifyExpiration)
                .orElseThrow(() -> new org.springframework.web.server.ResponseStatusException(
                    HttpStatus.UNAUTHORIZED, "Refresh token not found"
                ));

        User user = refreshToken.getUser();

        String newAccessToken = jwtUtils.generateAccessToken(user);
        RefreshToken newRefreshToken = refreshTokenService.createRefreshToken(
            user, refreshToken.isRememberMe()); // Optional: Rotate token

        Long expiresIn = 15 * 60L; // 15 minutes in seconds

        return ResponseEntity.ok(new AuthResponse(newAccessToken, newRefreshToken.getToken(), expiresIn));
    }

    @PostMapping("/logout")
    public ResponseEntity<String> logout(@RequestBody @Valid LogoutRequest request) {
        String refreshToken = request.getRefreshToken();

        // Make logout idempotent: if token is missing or already deleted, still respond OK.
        refreshTokenService.findByToken(refreshToken)
            .ifPresent(token -> refreshTokenService.deleteByUser(token.getUser()));

        return ResponseEntity.ok("Logout successful. Refresh token deleted.");
    }

    @PostMapping("/forgot-password")
    public ResponseEntity<Map<String, String>> forgotPassword(
        @RequestBody @Valid ForgotPasswordRequest request) {
        passwordResetService.initiateReset(request.getEmail());
        return ResponseEntity.ok(Map.of(
            "message", "If an account exists for that email, a reset link has been sent."));
    }

    @PostMapping("/reset-password")
    public ResponseEntity<Map<String, String>> resetPassword(
        @RequestBody @Valid ResetPasswordRequest request) {
        passwordResetService.resetPassword(request.getToken(), request.getNewPassword());
        return ResponseEntity.ok(Map.of("message", "Password updated successfully."));
    }

}
