package com.ekride.routes.service;

import com.ekride.config.GoogleMapsProperties;
import com.ekride.routes.dto.PlacePredictionDto;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.util.*;

@Service
public class GooglePlacesClient {
    private static final String AUTOCOMPLETE_URL = "https://places.googleapis.com/v1/places:autocomplete";
    private static final String PLACE_DETAILS_URL = "https://places.googleapis.com/v1/places/";

    private final GoogleMapsProperties googleProperties;
    private final RestTemplate restTemplate;
    private final ObjectMapper objectMapper;

    private final List<PlacePredictionDto> sampleLandmarks = List.of(
            new PlacePredictionDto("place_du_tsc", "TSC, Dhaka University", "Shahbagh, Dhaka", "Teacher-Student Centre (TSC), University of Dhaka", 23.7328, 90.3957),
            new PlacePredictionDto("place_du_curzon", "Curzon Hall, DU", "High Court Rd, Dhaka", "Curzon Hall, University of Dhaka", 23.7262, 90.4013),
            new PlacePredictionDto("place_buet", "BUET Campus", "Palashi, Dhaka", "Bangladesh University of Engineering and Technology", 23.7265, 90.3926),
            new PlacePredictionDto("place_brac", "BRAC University New Campus", "Merul Badda, Dhaka", "BRAC University, Pragati Sarani, Dhaka", 23.7716, 90.4253),
            new PlacePredictionDto("place_nsu", "North South University (NSU)", "Bashundhara R/A, Dhaka", "North South University, Bashundhara, Dhaka", 23.8151, 90.4255),
            new PlacePredictionDto("place_iub", "Independent University (IUB)", "Bashundhara R/A, Dhaka", "Independent University Bangladesh, Bashundhara, Dhaka", 23.8143, 90.4284),
            new PlacePredictionDto("place_dhanmondi32", "Dhanmondi 32", "Mirpur Rd, Dhanmondi, Dhaka", "Dhanmondi 32, Dhaka", 23.7465, 90.3760),
            new PlacePredictionDto("place_banani11", "Road 11, Banani", "Banani, Dhaka", "Road 11, Banani Commercial Area, Dhaka", 23.7937, 90.4066),
            new PlacePredictionDto("place_gulshan1", "Gulshan 1 Circle", "Gulshan Avenue, Dhaka", "Gulshan 1 Circle, Dhaka", 23.7785, 90.4172),
            new PlacePredictionDto("place_mirpur10", "Mirpur 10 Roundabout", "Mirpur, Dhaka", "Mirpur 10 Metro Station, Dhaka", 23.8071, 90.3685),
            new PlacePredictionDto("place_uttara3", "Uttara Sector 3", "Uttara, Dhaka", "Uttara Sector 3, Dhaka", 23.8687, 90.3986)
    );

    public GooglePlacesClient(GoogleMapsProperties googleProperties) {
        this.googleProperties = googleProperties;
        this.restTemplate = new RestTemplate();
        this.objectMapper = new ObjectMapper();
    }

    public List<PlacePredictionDto> autocomplete(String query) {
        if (query == null || query.trim().isEmpty()) {
            return sampleLandmarks.subList(0, 5);
        }

        String apiKey = googleProperties.getResolvedApiKey();
        if (apiKey != null && !apiKey.isEmpty()) {
            try {
                List<PlacePredictionDto> results = callGooglePlacesAutocomplete(query, apiKey);
                if (!results.isEmpty()) {
                    return results;
                }
            } catch (Exception ignored) {}
        }

        // Demo fallback filter
        String lower = query.trim().toLowerCase();
        List<PlacePredictionDto> matches = new ArrayList<>();
        for (PlacePredictionDto p : sampleLandmarks) {
            if (p.getFullText().toLowerCase().contains(lower) || p.getPrimaryText().toLowerCase().contains(lower)) {
                matches.add(p);
            }
        }
        if (matches.isEmpty()) {
            matches.add(new PlacePredictionDto("custom_" + Math.abs(query.hashCode()), query, "Dhaka, Bangladesh", query + ", Dhaka", 23.7808, 90.4152));
        }
        return matches;
    }

    public PlacePredictionDto getPlaceDetails(String placeId) {
        // 1. Check if it's one of our sample landmarks
        for (PlacePredictionDto p : sampleLandmarks) {
            if (p.getPlaceId().equals(placeId)) {
                return p;
            }
        }

        // 2. Fetch live coordinates from Google Places API New (GET /v1/places/{placeId})
        String apiKey = googleProperties.getResolvedApiKey();
        if (apiKey != null && !apiKey.isEmpty() && placeId != null && !placeId.startsWith("custom_")) {
            try {
                HttpHeaders headers = new HttpHeaders();
                headers.set("X-Goog-Api-Key", apiKey);
                headers.set("X-Goog-FieldMask", "id,displayName,formattedAddress,location");

                String cleanId = placeId.startsWith("places/") ? placeId : "places/" + placeId;
                HttpEntity<Void> entity = new HttpEntity<>(headers);
                ResponseEntity<String> response = restTemplate.exchange(
                        "https://places.googleapis.com/v1/" + cleanId,
                        HttpMethod.GET,
                        entity,
                        String.class);

                if (response.getStatusCode().is2xxSuccessful() && response.getBody() != null) {
                    JsonNode root = objectMapper.readTree(response.getBody());
                    double lat = root.path("location").path("latitude").asDouble(23.7808);
                    double lng = root.path("location").path("longitude").asDouble(90.4152);
                    String fullText = root.path("formattedAddress").asText();
                    String primaryText = root.path("displayName").path("text").asText(fullText);

                    return new PlacePredictionDto(placeId, primaryText, fullText, fullText, lat, lng);
                }
            } catch (Exception ignored) {}
        }

        // Fallback default coordinate in Dhaka center
        return new PlacePredictionDto(placeId, "Selected Place", "Dhaka, Bangladesh", "Selected Location, Dhaka", 23.7808, 90.4152);
    }

    private List<PlacePredictionDto> callGooglePlacesAutocomplete(String input, String apiKey) throws Exception {
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        headers.set("X-Goog-Api-Key", apiKey);

        Map<String, Object> body = Map.of(
                "input", input,
                "includedRegionCodes", List.of("bd"),
                "locationBias", Map.of(
                        "circle", Map.of(
                                "center", Map.of("latitude", 23.8103, "longitude", 90.4125),
                                "radius", 25000.0
                        )
                )
        );

        HttpEntity<Map<String, Object>> entity = new HttpEntity<>(body, headers);
        ResponseEntity<String> response = restTemplate.exchange(AUTOCOMPLETE_URL, HttpMethod.POST, entity, String.class);

        List<PlacePredictionDto> results = new ArrayList<>();
        if (response.getStatusCode().is2xxSuccessful() && response.getBody() != null) {
            JsonNode root = objectMapper.readTree(response.getBody());
            JsonNode suggestions = root.path("suggestions");
            for (JsonNode sug : suggestions) {
                JsonNode pred = sug.path("placePrediction");
                String placeId = pred.path("placeId").asText("");
                String fullText = pred.path("text").path("text").asText("");
                String mainText = pred.path("structuredFormat").path("mainText").path("text").asText("");
                String secText = pred.path("structuredFormat").path("secondaryText").path("text").asText("");

                results.add(new PlacePredictionDto(placeId, mainText, secText, fullText, null, null));
            }
        }
        return results;
    }
}
