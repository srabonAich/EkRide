import re

file_path = 'backend/src/main/java/com/ekride/routes/service/GoogleRoutesClient.java'

with open(file_path, 'r') as f:
    code = f.read()

# Replace computeOsrmRoute with directional bearings implementation
old_compute_osrm = """    private RouteCalculationResult computeOsrmRoute(LocationDto origin, LocationDto destination, List<LocationDto> waypoints) throws Exception {
        StringBuilder coords = new StringBuilder();
        coords.append(String.format(Locale.US, "%.6f,%.6f", origin.getLng(), origin.getLat()));
        if (waypoints != null) {
            for (LocationDto wp : waypoints) {
                coords.append(String.format(Locale.US, ";%.6f,%.6f", wp.getLng(), wp.getLat()));
            }
        }
        coords.append(String.format(Locale.US, ";%.6f,%.6f", destination.getLng(), destination.getLat()));

        String osrmUrl = "http://router.project-osrm.org/route/v1/driving/" + coords.toString() + "?overview=full&geometries=polyline&alternatives=true&continue_straight=true";

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
        throw new RuntimeException("OSRM returned non-OK status");
    }"""

new_compute_osrm = """    private RouteCalculationResult computeOsrmRoute(LocationDto origin, LocationDto destination, List<LocationDto> waypoints) throws Exception {
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
                // Intermediate corridor & detour stops: constrain approach heading (+/- 60 deg).
                // This strictly forbids snapping across physical medians to opposing carriageways!
                LocationDto prev = allPts.get(i - 1);
                double b = RoutePolylineUtils.calculateBearing(prev.getLat(), prev.getLng(), pt.getLat(), pt.getLng());
                bearings.append(String.format(Locale.US, "%d,60", Math.round(b)));
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
    }"""

if old_compute_osrm in code:
    code = code.replace(old_compute_osrm, new_compute_osrm)
    with open(file_path, 'w') as f:
        f.write(code)
    print("Updated computeOsrmRoute with directional bearings successfully!")
else:
    print("Could not find old computeOsrmRoute block in GoogleRoutesClient.java")
