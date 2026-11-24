package com.ekride.vehicles;

import com.ekride.common.ApiResponse;
import com.ekride.security.CustomUserDetails;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/vehicles")
public class VehicleController {
    private final VehicleService vehicleService;

    public VehicleController(VehicleService vehicleService) {
        this.vehicleService = vehicleService;
    }

    @GetMapping("/my")
    public ResponseEntity<ApiResponse<List<Vehicle>>> getMyVehicles(@AuthenticationPrincipal CustomUserDetails userDetails) {
        List<Vehicle> list = vehicleService.getVehiclesByDriver(userDetails.getUser().getId());
        return ResponseEntity.ok(ApiResponse.ok(list));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<Vehicle>> addVehicle(
            @AuthenticationPrincipal CustomUserDetails userDetails,
            @RequestBody Map<String, Object> payload) {
        Vehicle vehicle = vehicleService.registerVehicle(
                userDetails.getUser().getId(),
                (String) payload.get("make"),
                (String) payload.get("model"),
                (String) payload.get("licensePlate"),
                payload.get("totalSeats") != null ? Integer.parseInt(payload.get("totalSeats").toString()) : 4,
                (String) payload.get("color"));
        return ResponseEntity.ok(ApiResponse.ok("Vehicle registered", vehicle));
    }
}
