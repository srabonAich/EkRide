package com.ekride.location;

import com.ekride.common.ApiResponse;
import com.ekride.security.CustomUserDetails;
import org.springframework.http.ResponseEntity;
import org.springframework.messaging.handler.annotation.DestinationVariable;
import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.handler.annotation.Payload;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/location")
public class LocationController {
    private final LocationService locationService;

    public LocationController(LocationService locationService) {
        this.locationService = locationService;
    }

    @PostMapping("/update")
    public ResponseEntity<ApiResponse<LocationUpdate>> updateLocation(
            @AuthenticationPrincipal CustomUserDetails userDetails,
            @RequestBody LocationUpdateDto dto) {
        if (userDetails != null) {
            dto.setUserId(userDetails.getUser().getId());
        }
        LocationUpdate saved = locationService.saveAndBroadcastLocation(dto);
        return ResponseEntity.ok(ApiResponse.ok(saved));
    }

    @GetMapping("/rides/{rideId}")
    public ResponseEntity<ApiResponse<List<LocationUpdate>>> getRideLocations(@PathVariable Long rideId) {
        List<LocationUpdate> list = locationService.getRecentLocations(rideId);
        return ResponseEntity.ok(ApiResponse.ok(list));
    }

    // WebSocket STOMP endpoint for client sending /app/rides/{rideId}/location
    @MessageMapping("/rides/{rideId}/location")
    public void handleWebSocketLocation(@DestinationVariable Long rideId, @Payload LocationUpdateDto dto) {
        dto.setRideId(rideId);
        locationService.saveAndBroadcastLocation(dto);
    }
}
