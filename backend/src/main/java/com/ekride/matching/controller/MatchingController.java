package com.ekride.matching.controller;

import com.ekride.common.ApiResponse;
import com.ekride.matching.dto.CandidatePassengerDto;
import com.ekride.matching.dto.MatchRequest;
import com.ekride.matching.dto.CustomPoolRequest;
import com.ekride.matching.dto.RouteOptionDto;
import com.ekride.matching.service.PassengerDiscoveryService;
import com.ekride.routes.dto.LocationDto;
import com.ekride.security.CustomUserDetails;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/rides")
public class MatchingController {
    private final PassengerDiscoveryService discoveryService;

    public MatchingController(PassengerDiscoveryService discoveryService) {
        this.discoveryService = discoveryService;
    }

    @GetMapping("/nearby")
    public ResponseEntity<ApiResponse<List<CandidatePassengerDto>>> getNearbyPassengers(
            @RequestParam double lat,
            @RequestParam double lng,
            @RequestParam(required = false, defaultValue = "23.7937") double destLat,
            @RequestParam(required = false, defaultValue = "90.4066") double destLng,
            @RequestParam(required = false, defaultValue = "Campus Departure Gate") String address) {
        LocationDto origin = new LocationDto(lat, lng, address);
        LocationDto dest = new LocationDto(destLat, destLng, "Destination Hub");
        List<CandidatePassengerDto> candidates = discoveryService.findNearbyActivePassengers(origin, dest, 1);
        return ResponseEntity.ok(ApiResponse.ok(candidates));
    }

    @PostMapping("/options")
    public ResponseEntity<ApiResponse<List<RouteOptionDto>>> getRouteOptions(
            @AuthenticationPrincipal CustomUserDetails userDetails,
            @RequestBody MatchRequest request) {
        Long userId = userDetails != null ? userDetails.getUser().getId() : 1L;
        String userName = userDetails != null ? userDetails.getUser().getFullName() : "Current Passenger";

        List<RouteOptionDto> options = discoveryService.generateFeasibleRouteOptions(
                request.getOrigin(),
                request.getDestination(),
                userId,
                userName,
                request.getSeatsRequired() != null ? request.getSeatsRequired() : 1);

        return ResponseEntity.ok(ApiResponse.ok(options));
    }

    @PostMapping("/custom-pool")
    public ResponseEntity<ApiResponse<RouteOptionDto>> getCustomPool(
            @AuthenticationPrincipal CustomUserDetails userDetails,
            @RequestBody CustomPoolRequest request) {
        Long userId = userDetails != null ? userDetails.getUser().getId() : 1L;
        String userName = userDetails != null ? userDetails.getUser().getFullName() : "Current Passenger";

        RouteOptionDto option = discoveryService.buildPoolForCandidates(
                request.getOrigin(),
                request.getDestination(),
                userId,
                userName,
                request.getSelectedCandidateIds());

        return ResponseEntity.ok(ApiResponse.ok(option));
    }
}