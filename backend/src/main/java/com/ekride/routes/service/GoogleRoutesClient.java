package com.ekride.routes.service;

import com.ekride.config.GoogleMapsProperties;
import com.ekride.routes.dto.LocationDto;
import com.ekride.routes.dto.RouteCalculationResult;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.util.*;

@Service
public class GoogleRoutesClient {
    private static final String ROUTES_URL = "https://routes.googleapis.com/directions/v2:computeRoutes";

    private final GoogleMapsProperties googleProperties;
    private final RestTemplate restTemplate;
    private final ObjectMapper objectMapper;
    private final Map<String, RouteCalculationResult> routeCache = new java.util.concurrent.ConcurrentHashMap<>();

    private String buildCacheKey(LocationDto origin, LocationDto destination, List<LocationDto> waypoints) {
        StringBuilder sb = new StringBuilder();
        sb.append(String.format(Locale.US, "%.4f,%.4f->%.4f,%.4f", origin.getLat(), origin.getLng(), destination.getLat(), destination.getLng()));
        if (waypoints != null && !waypoints.isEmpty()) {
            sb.append("|wp:");
            for (LocationDto wp : waypoints) {
                sb.append(String.format(Locale.US, "[%.4f,%.4f]", wp.getLat(), wp.getLng()));
            }
        }
        return sb.toString();
    }

    public GoogleRoutesClient(GoogleMapsProperties googleProperties) {
        this.googleProperties = googleProperties;
        this.restTemplate = new RestTemplate();
        this.objectMapper = new ObjectMapper();
    }

    public RouteCalculationResult computeRoute(LocationDto origin, LocationDto destination, List<LocationDto> intermediateWaypoints) {
        String cacheKey = buildCacheKey(origin, destination, intermediateWaypoints);
        RouteCalculationResult cached = routeCache.get(cacheKey);
        if (cached != null) {
            return cached;
        }

        RouteCalculationResult result = null;
        String apiKey = googleProperties.getResolvedApiKey();

        if (apiKey != null && !apiKey.isEmpty()) {
            try {
                result = callGoogleRoutesApi(origin, destination, intermediateWaypoints, apiKey);
            } catch (Exception e) {
                System.err.println("Google Routes API failed (" + e.getMessage() + "), attempting OSRM real-road routing...");
            }
        }

        if (result == null) {
            // Secondary real-road routing engine: OSRM (zero quota, real street geometry)
            try {
                result = computeOsrmRoute(origin, destination, intermediateWaypoints);
            } catch (Exception ex) {
                System.err.println("OSRM routing failed (" + ex.getMessage() + "), falling back to simulated corridor.");
            }
        }

        if (result == null) {
            // Fallback demo / Haversine simulation
            result = computeSimulatedRoute(origin, destination, intermediateWaypoints);
        }

        if (result != null) {
            routeCache.put(cacheKey, result);
        }

        return result;
    }

    private RouteCalculationResult callGoogleRoutesApi(LocationDto origin, LocationDto destination, List<LocationDto> waypoints, String apiKey) throws Exception {
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        headers.set("X-Goog-Api-Key", apiKey);
        headers.set("X-Goog-FieldMask", "routes.duration,routes.distanceMeters,routes.polyline.encodedPolyline,routes.description");

        Map<String, Object> originNode = Map.of("location", Map.of("latLng", Map.of("latitude", origin.getLat(), "longitude", origin.getLng())));
        Map<String, Object> destNode = Map.of("location", Map.of("latLng", Map.of("latitude", destination.getLat(), "longitude", destination.getLng())));

        Map<String, Object> requestBody = new HashMap<>();
        requestBody.put("origin", originNode);
        requestBody.put("destination", destNode);
        requestBody.put("travelMode", "DRIVE");
        requestBody.put("routingPreference", "TRAFFIC_AWARE");

        if (waypoints != null && !waypoints.isEmpty()) {
            List<Map<String, Object>> intermediates = new ArrayList<>();
            for (LocationDto wp : waypoints) {
                intermediates.add(Map.of("location", Map.of("latLng", Map.of("latitude", wp.getLat(), "longitude", wp.getLng()))));
            }
            requestBody.put("intermediates", intermediates);
        }

        HttpEntity<Map<String, Object>> entity = new HttpEntity<>(requestBody, headers);
        ResponseEntity<String> response = restTemplate.exchange(ROUTES_URL, HttpMethod.POST, entity, String.class);

        if (response.getStatusCode().is2xxSuccessful() && response.getBody() != null) {
            JsonNode root = objectMapper.readTree(response.getBody());
            JsonNode routes = root.path("routes");
            if (routes.isArray() && routes.size() > 0) {
                JsonNode firstRoute = routes.get(0);
                long distanceMeters = firstRoute.path("distanceMeters").asLong();
                String durationStr = firstRoute.path("duration").asText("0s").replace("s", "");
                long durationSeconds = Long.parseLong(durationStr);
                String polyline = firstRoute.path("polyline").path("encodedPolyline").asText("");
                String description = firstRoute.path("description").asText("Google Traffic-Aware Best Route");

                return new RouteCalculationResult(distanceMeters, durationSeconds, polyline, false, description);
            }
        }

        throw new RuntimeException("No routes found from Google Routes API");
    }

    private RouteCalculationResult computeOsrmRoute(LocationDto origin, LocationDto destination, List<LocationDto> waypoints) throws Exception {
        List<LocationDto> allPts = new ArrayList<>();
        allPts.add(origin);
        if (waypoints != null) {
            allPts.addAll(waypoints);
        }
        allPts.add(destination);

        StringBuilder coords = new StringBuilder();
        StringBuilder bearings = new StringBuilder();

        for (int i = 0; i < allPts.size(); i++) {
            LocationDto pt = allPts.get(i);
            if (i > 0) {
                coords.append(";");
                bearings.append(";");
            }
            coords.append(String.format(Locale.US, "%.6f,%.6f", pt.getLng(), pt.getLat()));

            if (i == 0 || i == allPts.size() - 1) {
                // Origin & Destination endpoints: unrestricted departure/arrival (0,180 allows any entrance)
                bearings.append("0,180");
            } else {
                // Intermediate corridor & detour stops: constrain approach heading (+/- 45 deg).
                // Strictly use the forward road segment bearing to eliminate opposing-carriageway snaps & U-turns!
                Double b = pt.getBearing();
                if (b == null) {
                    LocationDto next = (i < allPts.size() - 1) ? allPts.get(i + 1) : destination;
                    b = RoutePolylineUtils.calculateBearing(pt.getLat(), pt.getLng(), next.getLat(), next.getLng());
                }
                bearings.append(String.format(Locale.US, "%d,45", Math.round(b)));
            }
        }

        // Try first with strict continue_straight=true and directional bearings constraint
        String osrmUrl = "http://router.project-osrm.org/route/v1/driving/" + coords.toString()
                + "?overview=full&geometries=polyline&alternatives=true&continue_straight=true&bearings=" + bearings.toString();

        try {
            ResponseEntity<String> response = restTemplate.getForEntity(osrmUrl, String.class);
            if (response.getStatusCode().is2xxSuccessful() && response.getBody() != null) {
                JsonNode root = objectMapper.readTree(response.getBody());
                if ("Ok".equalsIgnoreCase(root.path("code").asText())) {
                    JsonNode routes = root.path("routes");
                    if (routes.isArray() && routes.size() > 0) {
                        JsonNode bestRoute = routes.get(0);
                        for (int i = 1; i < routes.size(); i++) {
                            JsonNode r = routes.get(i);
                            if (r.path("duration").asDouble() < bestRoute.path("duration").asDouble()) {
                                bestRoute = r;
                            }
                        }
                        long distanceMeters = Math.round(bestRoute.path("distance").asDouble());
                        long durationSeconds = Math.round(bestRoute.path("duration").asDouble());
                        String polyline = bestRoute.path("geometry").asText("");
                        return new RouteCalculationResult(distanceMeters, durationSeconds, polyline, false, "OSRM Optimal Road Corridor");
                    }
                }
            }
        } catch (Exception ex) {
            System.err.println("OSRM with directional bearings failed (" + ex.getMessage() + "), retrying without bearings constraint...");
        }

        // Fallback retry without bearings if a strict one-way blocked the graph search
        String fallbackUrl = "http://router.project-osrm.org/route/v1/driving/" + coords.toString()
                + "?overview=full&geometries=polyline&alternatives=true&continue_straight=true";
        ResponseEntity<String> fbResponse = restTemplate.getForEntity(fallbackUrl, String.class);
        if (fbResponse.getStatusCode().is2xxSuccessful() && fbResponse.getBody() != null) {
            JsonNode root = objectMapper.readTree(fbResponse.getBody());
            if ("Ok".equalsIgnoreCase(root.path("code").asText())) {
                JsonNode routes = root.path("routes");
                if (routes.isArray() && routes.size() > 0) {
                    JsonNode bestRoute = routes.get(0);
                    long distanceMeters = Math.round(bestRoute.path("distance").asDouble());
                    long durationSeconds = Math.round(bestRoute.path("duration").asDouble());
                    String polyline = bestRoute.path("geometry").asText("");
                    return new RouteCalculationResult(distanceMeters, durationSeconds, polyline, false, "OSRM Road Corridor");
                }
            }
        }

        throw new RuntimeException("OSRM returned non-OK status");
    }

    private RouteCalculationResult computeSimulatedRoute(LocationDto origin, LocationDto destination, List<LocationDto> waypoints) {
        List<LocationDto> allPoints = new ArrayList<>();
        allPoints.add(origin);
        if (waypoints != null) {
            allPoints.addAll(waypoints);
        }
        allPoints.add(destination);

        double totalDistance = 0;
        List<double[]> polyPoints = new ArrayList<>();

        for (int i = 0; i < allPoints.size() - 1; i++) {
            LocationDto p1 = allPoints.get(i);
            LocationDto p2 = allPoints.get(i + 1);
            double dist = RoutePolylineUtils.haversineDistanceMeters(p1.getLat(), p1.getLng(), p2.getLat(), p2.getLng());
            totalDistance += (dist * 1.35);

            int steps = 10;
            for (int s = 0; s < steps; s++) {
                double f = (double) s / steps;
                double lat = p1.getLat() + f * (p2.getLat() - p1.getLat());
                double lng = p1.getLng() + f * (p2.getLng() - p1.getLng());
                polyPoints.add(new double[]{lat, lng});
            }
        }
        polyPoints.add(new double[]{destination.getLat(), destination.getLng()});

        long durationSeconds = Math.round(totalDistance / 6.1);
        String encodedPolyline = RoutePolylineUtils.encode(polyPoints);

        return new RouteCalculationResult((long) totalDistance, durationSeconds, encodedPolyline, true, "Simulated Corridors (Demo Mode)");
    }
}
