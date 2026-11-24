package com.ekride.fare;

import com.ekride.config.FareProperties;
import com.ekride.fare.dto.FareBreakdownDto;
import com.ekride.fare.service.FareCalculationService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

class FareCalculationServiceTest {

    private FareCalculationService fareService;
    private FareProperties properties;

    @BeforeEach
    void setUp() {
        properties = new FareProperties();
        properties.setBaseFare(new BigDecimal("50.00"));
        properties.setPerKmRate(new BigDecimal("25.00"));
        properties.setPerMinuteRate(new BigDecimal("2.00"));
        properties.setMinimumFare(new BigDecimal("60.00"));
        properties.setPlatformFeePercent(new BigDecimal("10.00"));
        fareService = new FareCalculationService(properties);
    }

    @Test
    @DisplayName("Should enforce minimum fare on zero or trivial distance")
    void testMinimumFareEdgeCase() {
        BigDecimal fare = fareService.calculateDirectSoloFare(0L, 0L);
        assertEquals(new BigDecimal("60.00"), fare, "Minimum fare must apply to zero distance");
    }

    @Test
    @DisplayName("Should correctly calculate direct solo fare for standard trip")
    void testDirectSoloFare() {
        // 10 km (10,000m) and 20 mins (1,200s):
        // Base: 50 + Dist: 10*25 (250) + Time: 20*2 (40) = 340.00
        BigDecimal fare = fareService.calculateDirectSoloFare(10000L, 1200L);
        assertEquals(new BigDecimal("300.00"), fare);
    }

    @Test
    @DisplayName("Should reconcile exact sum of passenger shares to total vehicle fare")
    void testFareAllocationExactReconciliation() {
        List<FareCalculationService.PassengerInput> passengers = List.of(
                new FareCalculationService.PassengerInput(1L, "Passenger A", 8000L, 900L),
                new FareCalculationService.PassengerInput(2L, "Passenger B", 9500L, 1100L),
                new FareCalculationService.PassengerInput(3L, "Passenger C", 6000L, 700L)
        );

        long combinedDist = 12000L;
        long combinedDur = 1400L;

        FareBreakdownDto breakdown = fareService.calculateSharedFare(combinedDist, combinedDur, passengers);

        assertNotNull(breakdown);
        assertEquals(3, breakdown.getPassengerShares().size());

        // Sum of passenger individual fares must equal totalVehicleFare EXACTLY (no floating point leak)
        BigDecimal sumShares = breakdown.getPassengerShares().stream()
                .map(s -> s.getIndividualFare())
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        assertEquals(breakdown.getTotalVehicleFare(), sumShares, "Sum of individual shares must match total vehicle fare exactly");

        // Every passenger must have savings compared to traveling solo
        for (var share : breakdown.getPassengerShares()) {
            assertTrue(share.getSavings().compareTo(BigDecimal.ZERO) > 0, "Passenger must save money by sharing");
            assertTrue(share.getIndividualFare().compareTo(share.getDirectSoloFare()) < 0);
        }
    }

    @Test
    @DisplayName("Should correctly allocate shared fare for 4 passengers with exact 100% reconciliation")
    void testQuadPoolFourPassengersFareAllocation() {
        List<FareCalculationService.PassengerInput> passengers = List.of(
                new FareCalculationService.PassengerInput(1L, "Rafiul Hasan", 12000L, 1400L),
                new FareCalculationService.PassengerInput(2L, "Nusrat Jahan", 8000L, 900L),
                new FareCalculationService.PassengerInput(3L, "Tanvir Hasan", 7000L, 800L),
                new FareCalculationService.PassengerInput(4L, "Sadia Rahman", 7500L, 850L)
        );

        long combinedDist = 13500L;
        long combinedDur = 1600L;
        long extraDist = 1500L;
        long extraDur = 200L;

        FareBreakdownDto breakdown = fareService.calculateSharedFare(combinedDist, combinedDur, passengers, extraDist, extraDur);

        assertNotNull(breakdown);
        assertEquals(4, breakdown.getPassengerShares().size(), "Must have exactly 4 passenger shares");

        BigDecimal sumShares = breakdown.getPassengerShares().stream()
                .map(s -> s.getIndividualFare())
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        assertEquals(breakdown.getTotalVehicleFare(), sumShares, "Sum of all 4 shares must reconcile 100% to total vehicle fare");

        for (var share : breakdown.getPassengerShares()) {
            assertTrue(share.getSavings().compareTo(BigDecimal.ZERO) > 0, "Every passenger must save money in a 4-pool: " + share.getPassengerName());
            assertTrue(share.getIndividualFare().compareTo(share.getDirectSoloFare()) < 0, "Individual fare must be less than direct solo fare");
        }
    }
}