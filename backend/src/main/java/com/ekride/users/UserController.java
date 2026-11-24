package com.ekride.users;

import com.ekride.common.ApiResponse;
import com.ekride.security.CustomUserDetails;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/v1/users")
public class UserController {
    private final UserService userService;

    public UserController(UserService userService) {
        this.userService = userService;
    }

    @GetMapping("/me")
    public ResponseEntity<ApiResponse<User>> getCurrentUser(@AuthenticationPrincipal CustomUserDetails userDetails) {
        User user = userService.getById(userDetails.getUser().getId());
        return ResponseEntity.ok(ApiResponse.ok(user));
    }

    @PutMapping("/me")
    public ResponseEntity<ApiResponse<User>> updateProfile(
            @AuthenticationPrincipal CustomUserDetails userDetails,
            @RequestBody Map<String, String> payload) {
        User updated = userService.updateProfile(
                userDetails.getUser().getId(),
                payload.get("fullName"),
                payload.get("phone"),
                payload.get("university"),
                payload.get("studentId"));
        return ResponseEntity.ok(ApiResponse.ok("Profile updated", updated));
    }

    @PostMapping("/switch-role")
    public ResponseEntity<ApiResponse<User>> switchRole(
            @AuthenticationPrincipal CustomUserDetails userDetails,
            @RequestBody Map<String, String> payload) {
        Role newRole = Role.valueOf(payload.get("role").toUpperCase());
        User updated = userService.switchRole(userDetails.getUser().getId(), newRole);
        return ResponseEntity.ok(ApiResponse.ok("Role switched to " + newRole, updated));
    }
}
