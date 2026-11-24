package com.ekride.matching;

import com.ekride.config.FareProperties;
import com.ekride.config.MatchingProperties;
import com.ekride.fare.service.FareCalculationService;
import com.ekride.matching.dto.CandidatePassengerDto;
import com.ekride.matching.dto.RouteOptionDto;
import com.ekride.matching.service.RouteInsertionEngine;
import com.ekride.routes.dto.LocationDto;
import com.ekride.routes.dto.RouteCalculationResult;
import com.ekride.routes.service.RouteService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;

import java.math.BigDecimal;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;

class RouteInsertionEngineTest {

    private RouteService routeService;
    private FareCalculationService fareService;
    private MatchingProperties matchingProperties;
    private RouteInsertionEngine engine;

    @BeforeEach
    void setUp() {
        routeService = Mockito.mock(RouteService.class);
        FareProperties fareProps = new FareProperties();
        fareService = new FareCalculationService(fareProps);
        matchingProperties = new MatchingProperties();
        engine = new RouteInsertionEngine(routeService, fareService, matchingProperties);
    }

    @Test
    @DisplayName("Should evaluate candidate insertion and generate shared option with savings")
    void testEvaluateCandidateInsertion() {
        LocationDto origin = new LocationDto(23.7328, 90.3957, "TSC, DU");
        LocationDto dest = new LocationDto(23.7937, 90.4066, "Banani 11");

        RouteCalculationResult baseline = new RouteCalculationResult(8000L, 1200L, "poly_base", false, "Baseline");
        when(routeService.calculateWaypointRoute(any(), any(), any()))
                .thenReturn(new RouteCalculationResult(9200L, 1400L, "poly_combined", false, "Combined"));

        CandidatePassengerDto candidate = new CandidatePassengerDto();
        candidate.setRideId(101L);
        candidate.setPassengerId(2L);
        candidate.setPassengerName("Nusrat Jahan");
        candidate.setUniversity("BRAC University");
        candidate.setRating(4.9);
        candidate.setPickupLat(23.7400);
        candidate.setPickupLng(90.3990);
        candidate.setPickupAddress("Shahbagh");
        candidate.setDropoffLat(23.7850);
        candidate.setDropoffLng(90.4020);
        candidate.setDropoffAddress("Mohakhali");
        candidate.setAvailableSeats(3);

        RouteOptionDto option = engine.evaluateCandidateInsertion(origin, dest, candidate, 1L, "Abrar Rahman", baseline, 1);

        assertNotNull(option);
        assertEquals(9200L, option.getTotalDistanceMeters());
        assertEquals(1200L, option.getExtraDistanceMeters());
        assertEquals(200L, option.getExtraDurationSeconds());
        assertTrue(option.getEstimatedSavings().compareTo(BigDecimal.ZERO) > 0, "Passenger must save on shared ride");
        assertEquals(4, option.getStops().size(), "Stops must contain Origin, Pickup, Dropoff, Destination");
    }

    @Test
    @DisplayName("Should sequence candidate behind origin and ahead of destination in forward monotonic order")
    void testCandidateBehindOriginAndAheadOfDestination() {
        LocationDto origin = new LocationDto(23.7328, 90.3957, "TSC, DU");
        LocationDto dest = new LocationDto(23.7937, 90.4066, "Banani 11");

        RouteCalculationResult baseline = new RouteCalculationResult(7500L, 1200L, "poly_base", false, "Baseline");
        when(routeService.calculateWaypointRoute(any(), any(), any()))
                .thenReturn(new RouteCalculationResult(13500L, 1600L, "poly_combined", false, "Combined"));

        CandidatePassengerDto rohan = new CandidatePassengerDto();
        rohan.setRideId(114L);
        rohan.setPassengerId(14L);
        rohan.setPassengerName("Rohan Farooq");
        rohan.setUniversity("AIUB");
        rohan.setRating(4.9);
        rohan.setPickupLat(23.7220); // Chankharpul (~1.5km behind TSC)
        rohan.setPickupLng(90.4000);
        rohan.setPickupAddress("Chankharpul");
        rohan.setDropoffLat(23.8200); // Kuril (~3km ahead of Banani)
        rohan.setDropoffLng(90.4200);
        rohan.setDropoffAddress("Kuril Flyover");
        rohan.setAvailableSeats(3);

        RouteOptionDto option = engine.evaluateCandidateInsertion(origin, dest, rohan, 1L, "Abrar Rahman", baseline, 1);

        assertNotNull(option, "Rohan should be accepted as a valid forward corridor candidate");
        assertEquals(4, option.getStops().size());
        // Verify exact forward sequence: Rohan Pickup -> User Origin -> User Destination -> Rohan Dropoff
        assertEquals("PICKUP", option.getStops().get(0).getType());
        assertEquals("Rohan Farooq", option.getStops().get(0).getPassengerName());
        assertEquals("ORIGIN", option.getStops().get(1).getType());
        assertEquals("Abrar Rahman", option.getStops().get(1).getPassengerName());
        assertEquals("DESTINATION", option.getStops().get(2).getType());
        assertEquals("Abrar Rahman", option.getStops().get(2).getPassengerName());
        assertEquals("DROPOFF", option.getStops().get(3).getType());
        assertEquals("Rohan Farooq", option.getStops().get(3).getPassengerName());
    }

    @Test
    @DisplayName("Should sequence multi-passenger pool (Quad Pool) starting from behind origin and ending ahead of destination")
    void testQuadPoolSequenceForwardOrder() {
        LocationDto origin = new LocationDto(23.7328, 90.3957, "TSC, DU");
        LocationDto dest = new LocationDto(23.7937, 90.4066, "Banani 11");

        RouteCalculationResult baseline = new RouteCalculationResult(7500L, 1200L, "poly_base", false, "Baseline");
        when(routeService.calculateWaypointRoute(any(), any(), any()))
                .thenReturn(new RouteCalculationResult(13500L, 1600L, "poly_quad", false, "Quad Combined"));

        CandidatePassengerDto nusrat = new CandidatePassengerDto();
        nusrat.setRideId(101L);
        nusrat.setPassengerId(2L);
        nusrat.setPassengerName("Nusrat Jahan");
        nusrat.setUniversity("BRAC");
        nusrat.setRating(4.9);
        nusrat.setPickupLat(23.7328); // At TSC
        nusrat.setPickupLng(90.3957);
        nusrat.setPickupAddress("TSC");
        nusrat.setDropoffLat(23.7937); // At Banani 11
        nusrat.setDropoffLng(90.4066);
        nusrat.setDropoffAddress("Banani 11");
        nusrat.setAvailableSeats(3);

        CandidatePassengerDto tanvir = new CandidatePassengerDto();
        tanvir.setRideId(102L);
        tanvir.setPassengerId(3L);
        tanvir.setPassengerName("Tanvir Hasan");
        tanvir.setUniversity("NSU");
        tanvir.setRating(4.9);
        tanvir.setPickupLat(23.7371); // Shahbagh
        tanvir.setPickupLng(90.3956);
        tanvir.setPickupAddress("Shahbagh");
        tanvir.setDropoffLat(23.7806); // Mohakhali
        tanvir.setDropoffLng(90.3986);
        tanvir.setDropoffAddress("Mohakhali");
        tanvir.setAvailableSeats(3);

        CandidatePassengerDto rohan = new CandidatePassengerDto();
        rohan.setRideId(114L);
        rohan.setPassengerId(14L);
        rohan.setPassengerName("Rohan Farooq");
        rohan.setUniversity("AIUB");
        rohan.setRating(4.9);
        rohan.setPickupLat(23.7220); // Chankharpul
        rohan.setPickupLng(90.4000);
        rohan.setPickupAddress("Chankharpul");
        rohan.setDropoffLat(23.8200); // Kuril
        rohan.setDropoffLng(90.4200);
        rohan.setDropoffAddress("Kuril");
        rohan.setAvailableSeats(3);

        List<CandidatePassengerDto> candidates = List.of(nusrat, tanvir, rohan);
        RouteOptionDto quadOption = engine.buildMultiPassengerOption(origin, dest, candidates, 1L, "Abrar Rahman", baseline, 1);

        assertNotNull(quadOption);
        assertEquals(8, quadOption.getStops().size());

        // Stop 1 MUST be Rohan's pickup at Chankharpul (earliest stationing)
        assertEquals("PICKUP", quadOption.getStops().get(0).getType());
        assertEquals("Rohan Farooq", quadOption.getStops().get(0).getPassengerName());

        // Stop 8 MUST be Rohan's dropoff at Kuril (latest stationing)
        assertEquals("DROPOFF", quadOption.getStops().get(7).getType());
        assertEquals("Rohan Farooq", quadOption.getStops().get(7).getPassengerName());

        // Intermediate stops are forward: TSC (User & Nusrat), Shahbagh (Tanvir), Mohakhali (Tanvir), Banani (User & Nusrat)
        assertEquals("Tanvir Hasan", quadOption.getStops().get(3).getPassengerName()); // Shahbagh pickup
        assertEquals("Tanvir Hasan", quadOption.getStops().get(4).getPassengerName()); // Mohakhali dropoff
    }

    @Test
    @DisplayName("Should resolve corridor peer dropoff dynamically to curbside stop on route without car detour")
    void testMinWalkCurbsideOptimizationForCorridorPeer() {
        LocationDto origin = new LocationDto(23.7328, 90.3957, "TSC, DU");
        LocationDto dest = new LocationDto(23.7937, 90.4066, "Banani 11");

        // Baseline route from TSC to Banani 11 ending at Kamal Ataturk Ave (lat 23.794268, lng 90.402782)
        List<double[]> baselineRoutePoints = List.of(
                new double[]{23.7328, 90.3957},
                new double[]{23.7485, 90.3945},
                new double[]{23.7806, 90.3986},
                new double[]{23.794268, 90.402782}
        );

        CandidatePassengerDto mahir = new CandidatePassengerDto();
        mahir.setPassengerName("Mahir Faisal");
        mahir.setPickupLat(23.7258);
        mahir.setPickupLng(90.3895);
        mahir.setPickupAddress("Palashi Intersection");
        mahir.setDropoffLat(23.7995);
        mahir.setDropoffLng(90.4018);
        mahir.setDropoffAddress("Kakoli Bus Stand, New Airport Road");

        com.ekride.matching.service.SmartPickupResolver.DropoffResolution dropoffRes =
                com.ekride.matching.service.SmartPickupResolver.resolveDropoff(origin, dest, mahir, baselineRoutePoints);

        assertNotNull(dropoffRes);
        // Pure dynamic pooling: Peer dropoff dynamically projected to closest curbside stop on route (0 min car detour)
        assertEquals(23.7939, dropoffRes.getResolvedDropoffLat(), 0.005);
        assertEquals(90.4027, dropoffRes.getResolvedDropoffLng(), 0.005);
        assertEquals(com.ekride.matching.service.SmartPickupResolver.DropoffMode.MEET_AT_HUB, dropoffRes.getMode());
    }
}
