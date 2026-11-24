package com.ekride.routes.controller;

import com.ekride.common.ApiResponse;
import com.ekride.routes.dto.*;
import com.ekride.routes.service.GooglePlacesClient;
import com.ekride.routes.service.RouteService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/routes")
public class RoutesController {
    private final RouteService routeService;
    private final GooglePlacesClient googlePlacesClient;

    public RoutesController(RouteService routeService, GooglePlacesClient googlePlacesClient) {
        this.routeService = routeService;
        this.googlePlacesClient = googlePlacesClient;
    }

    @PostMapping("/calculate")
    public ResponseEntity<ApiResponse<RouteCalculationResult>> calculateRoute(@RequestBody RouteCompareRequest request) {
        RouteCalculationResult result = routeService.calculateWaypointRoute(
                request.getOrigin(),
                request.getDestination(),
                request.getIntermediateWaypoints());
        return ResponseEntity.ok(ApiResponse.ok(result));
    }

    @GetMapping("/autocomplete")
    public ResponseEntity<ApiResponse<List<PlacePredictionDto>>> autocomplete(@RequestParam(name = "query", required = false) String query) {
        List<PlacePredictionDto> list = googlePlacesClient.autocomplete(query);
        return ResponseEntity.ok(ApiResponse.ok(list));
    }

    @GetMapping("/place-details")
    public ResponseEntity<ApiResponse<PlacePredictionDto>> getPlaceDetails(@RequestParam(name = "placeId") String placeId) {
        PlacePredictionDto details = googlePlacesClient.getPlaceDetails(placeId);
        return ResponseEntity.ok(ApiResponse.ok(details));
    }
}
