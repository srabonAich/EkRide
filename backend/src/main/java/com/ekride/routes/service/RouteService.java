package com.ekride.routes.service;

import com.ekride.routes.dto.LocationDto;
import com.ekride.routes.dto.RouteCalculationResult;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class RouteService {
    private final GoogleRoutesClient googleRoutesClient;

    public RouteService(GoogleRoutesClient googleRoutesClient) {
        this.googleRoutesClient = googleRoutesClient;
    }

    public RouteCalculationResult calculateDirectRoute(LocationDto origin, LocationDto destination) {
        return googleRoutesClient.computeRoute(origin, destination, List.of());
    }

    public RouteCalculationResult calculateWaypointRoute(LocationDto origin, LocationDto destination, List<LocationDto> waypoints) {
        return googleRoutesClient.computeRoute(origin, destination, waypoints);
    }
}
