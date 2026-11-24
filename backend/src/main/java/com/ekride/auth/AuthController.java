package com.ekride.auth;

import com.ekride.auth.dto.AuthRequest;
import com.ekride.auth.dto.AuthResponse;
import com.ekride.auth.dto.RegisterRequest;
import com.ekride.common.ApiResponse;
import com.ekride.security.JwtService;
import com.ekride.users.User;
import com.ekride.users.UserRepository;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/auth")
public class AuthController {
    private final AuthenticationManager authenticationManager;
    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;

    public AuthController(
            AuthenticationManager authenticationManager,
            UserRepository userRepository,
            PasswordEncoder passwordEncoder,
            JwtService jwtService) {
        this.authenticationManager = authenticationManager;
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
        this.jwtService = jwtService;
    }

    @PostMapping("/register")
    public ResponseEntity<ApiResponse<AuthResponse>> register(@Valid @RequestBody RegisterRequest request) {
        if (userRepository.existsByEmail(request.getEmail().trim().toLowerCase())) {
            throw new IllegalArgumentException("User with this email already exists");
        }

        User user = new User();
        user.setEmail(request.getEmail().trim().toLowerCase());
        user.setPasswordHash(passwordEncoder.encode(request.getPassword()));
        user.setFullName(request.getFullName().trim());
        user.setPhone(request.getPhone());
        user.setUniversity(request.getUniversity());
        user.setStudentId(request.getStudentId());
        user.setRole(request.getRole() != null ? request.getRole() : com.ekride.users.Role.PASSENGER);
        user = userRepository.save(user);

        String token = jwtService.generateToken(user.getId(), user.getEmail(), user.getRole().name());
        AuthResponse response = new AuthResponse(
                token, user.getId(), user.getEmail(), user.getFullName(),
                user.getPhone(), user.getUniversity(), user.getStudentId(),
                user.getRole(), user.getRating());
        return ResponseEntity.ok(ApiResponse.ok("Registration successful", response));
    }

    @PostMapping("/login")
    public ResponseEntity<ApiResponse<AuthResponse>> login(@Valid @RequestBody AuthRequest request) {
        authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(request.getEmail().trim().toLowerCase(), request.getPassword()));

        User user = userRepository.findByEmail(request.getEmail().trim().toLowerCase())
                .orElseThrow(() -> new IllegalArgumentException("Invalid credentials"));

        String token = jwtService.generateToken(user.getId(), user.getEmail(), user.getRole().name());
        AuthResponse response = new AuthResponse(
                token, user.getId(), user.getEmail(), user.getFullName(),
                user.getPhone(), user.getUniversity(), user.getStudentId(),
                user.getRole(), user.getRating());
        return ResponseEntity.ok(ApiResponse.ok("Login successful", response));
    }
}
