package com.ekride.rides;

import com.ekride.common.ApiResponse;
import com.ekride.rides.dto.CreateRideRequest;
import com.ekride.rides.dto.RideDto;
import com.ekride.security.CustomUserDetails;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/rides")
public class RideController {
    private final RideService rideService;

    public RideController(RideService rideService) {
        this.rideService = rideService;
    }

    @PostMapping
    public ResponseEntity<ApiResponse<RideDto>> createRide(
            @AuthenticationPrincipal CustomUserDetails userDetails,
            @Valid @RequestBody CreateRideRequest request) {
        RideDto ride = rideService.createRide(userDetails.getUser().getId(), request);
        return ResponseEntity.ok(ApiResponse.ok("Ride created successfully", ride));
    }

    @GetMapping("/{rideId}")
    public ResponseEntity<ApiResponse<RideDto>> getRide(@PathVariable Long rideId) {
        RideDto ride = rideService.getRideById(rideId);
        return ResponseEntity.ok(ApiResponse.ok(ride));
    }

    @GetMapping
    public ResponseEntity<ApiResponse<List<RideDto>>> getMyRides(@AuthenticationPrincipal CustomUserDetails userDetails) {
        List<RideDto> list = rideService.getRidesForUser(userDetails.getUser().getId());
        return ResponseEntity.ok(ApiResponse.ok(list));
    }

    @PutMapping("/{rideId}/status")
    public ResponseEntity<ApiResponse<RideDto>> updateStatus(
            @AuthenticationPrincipal CustomUserDetails userDetails,
            @PathVariable Long rideId,
            @RequestBody Map<String, String> body) {
        RideStatus status = RideStatus.valueOf(body.get("status").toUpperCase());
        RideDto updated = rideService.updateRideStatus(rideId, status, userDetails.getUser().getId());
        return ResponseEntity.ok(ApiResponse.ok("Ride status updated", updated));
    }
}
