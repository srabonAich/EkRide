package com.ekride.fare.service;

import com.ekride.config.FareProperties;
import com.ekride.fare.dto.FareBreakdownDto;
import com.ekride.fare.dto.PassengerShareDto;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.ArrayList;
import java.util.List;

@Service
public class FareCalculationService {
    private final FareProperties fareProperties;

    public FareCalculationService(FareProperties fareProperties) {
        this.fareProperties = fareProperties;
    }

    /**
     * Calculate direct solo fare based exclusively on distance and base tariff.
     * User rule: Time is purely informational and not charged with monetary fees.
     */
    public BigDecimal calculateDirectSoloFare(long distanceMeters, long durationSeconds) {
        BigDecimal km = BigDecimal.valueOf(distanceMeters).divide(BigDecimal.valueOf(1000), 2, RoundingMode.HALF_UP);
        BigDecimal distanceCost = km.multiply(fareProperties.getPerKmRate());
        BigDecimal rawFare = fareProperties.getBaseFare().add(distanceCost);

        return rawFare.max(fareProperties.getMinimumFare()).setScale(2, RoundingMode.HALF_UP);
    }

    public FareBreakdownDto calculateSharedFare(
            long totalDistanceMeters,
            long totalDurationSeconds,
            List<PassengerInput> passengers) {
        return calculateSharedFare(totalDistanceMeters, totalDurationSeconds, passengers, 0L, 0L);
    }

    /**
     * Shared Fare Allocation Engine:
     * 1. Distance-only meter tariff (No time surcharge).
     * 2. Shared corridor fare is split proportionally by individual travel distance.
     * 3. Detour cost is split: 60% by the detour passenger, 40% by the primary user.
     */
    public FareBreakdownDto calculateSharedFare(
            long totalDistanceMeters,
            long totalDurationSeconds,
            List<PassengerInput> passengers,
            long extraDetourMeters,
            long extraDetourSeconds) {

        BigDecimal km = BigDecimal.valueOf(totalDistanceMeters).divide(BigDecimal.valueOf(1000), 2, RoundingMode.HALF_UP);
        BigDecimal distComponent = km.multiply(fareProperties.getPerKmRate());
        
        // Time charge is 0.00 as requested (purely informational metric)
        BigDecimal timeComponent = BigDecimal.ZERO.setScale(2, RoundingMode.HALF_UP);

        BigDecimal totalVehicleFare = fareProperties.getBaseFare().add(distComponent)
                .max(fareProperties.getMinimumFare()).setScale(2, RoundingMode.HALF_UP);

        BigDecimal platformFee = totalVehicleFare.multiply(fareProperties.getPlatformFeePercent())
                .divide(BigDecimal.valueOf(100), 2, RoundingMode.HALF_UP);
        BigDecimal driverEarnings = totalVehicleFare.subtract(platformFee);

        FareBreakdownDto breakdown = new FareBreakdownDto();
        breakdown.setTotalVehicleFare(totalVehicleFare);
        breakdown.setBaseFareComponent(fareProperties.getBaseFare());
        breakdown.setDistanceFareComponent(distComponent);
        breakdown.setTimeFareComponent(timeComponent);
        breakdown.setPlatformFee(platformFee);
        breakdown.setDriverEarnings(driverEarnings);

        int passengerCount = (passengers == null || passengers.isEmpty()) ? 1 : passengers.size();

        // 1. Calculate baseline solo distance-based fares for each passenger
        List<BigDecimal> soloFares = new ArrayList<>();
        BigDecimal sumSoloFares = BigDecimal.ZERO;

        for (int i = 0; i < passengerCount; i++) {
            PassengerInput p = (passengers != null && i < passengers.size()) ? passengers.get(i) : null;
            long pDist = (p != null && p.distanceMeters > 0) ? p.distanceMeters : totalDistanceMeters;
            long pDur = (p != null && p.durationSeconds > 0) ? p.durationSeconds : totalDurationSeconds;

            BigDecimal solo = calculateDirectSoloFare(pDist, pDur);
            soloFares.add(solo);
            sumSoloFares = sumSoloFares.add(solo);
        }

        // 2. Compute detour cost (distance only)
        BigDecimal detourCost = BigDecimal.ZERO;
        BigDecimal userDetourShare = BigDecimal.ZERO;
        BigDecimal peerDetourShare = BigDecimal.ZERO;

        if (extraDetourMeters > 200 && passengerCount > 1) {
            BigDecimal detourKm = BigDecimal.valueOf(extraDetourMeters).divide(BigDecimal.valueOf(1000), 2, RoundingMode.HALF_UP);
            detourCost = detourKm.multiply(fareProperties.getPerKmRate()).setScale(2, RoundingMode.HALF_UP);
            
            // User rule: Detour cost split: 60% by detour passenger, 40% by primary user
            peerDetourShare = detourCost.multiply(new BigDecimal("0.60")).setScale(2, RoundingMode.HALF_UP);
            userDetourShare = detourCost.subtract(peerDetourShare); // Exactly 40%
        }

        breakdown.setDetourCostComponent(detourCost);
        breakdown.setUserDetourShare(userDetourShare);
        breakdown.setPeerDetourShare(peerDetourShare);

        // 3. Shared corridor fare (total vehicle fare minus detour cost)
        BigDecimal sharedCorridorFare = totalVehicleFare.subtract(detourCost).max(BigDecimal.ZERO);

        List<PassengerShareDto> shares = new ArrayList<>();

        if (passengerCount == 1) {
            BigDecimal solo = soloFares.get(0);
            shares.add(new PassengerShareDto(passengers.get(0).passengerId, passengers.get(0).passengerName, totalVehicleFare, solo, BigDecimal.ZERO, BigDecimal.ZERO));
        } else {
            // Generalized for ANY number of passengers (2, 3, 4, etc.)
            BigDecimal minPassengerFare = new BigDecimal("40.00");

            BigDecimal sumPeersSoloFares = BigDecimal.ZERO;
            for (int i = 1; i < passengerCount; i++) {
                sumPeersSoloFares = sumPeersSoloFares.add(soloFares.get(i));
            }

            BigDecimal[] rawShares = new BigDecimal[passengerCount];

            // Primary User (index 0):
            BigDecimal ratio0 = sumSoloFares.compareTo(BigDecimal.ZERO) > 0
                    ? soloFares.get(0).divide(sumSoloFares, 6, RoundingMode.HALF_UP)
                    : BigDecimal.ONE.divide(BigDecimal.valueOf(passengerCount), 6, RoundingMode.HALF_UP);
            BigDecimal baseShare0 = sharedCorridorFare.multiply(ratio0).setScale(2, RoundingMode.HALF_UP);
            rawShares[0] = baseShare0.add(userDetourShare).setScale(2, RoundingMode.HALF_UP);

            // Peers (indices 1..passengerCount-1):
            BigDecimal runningPeerDetour = BigDecimal.ZERO;
            for (int i = 1; i < passengerCount; i++) {
                BigDecimal ratioI = sumSoloFares.compareTo(BigDecimal.ZERO) > 0
                        ? soloFares.get(i).divide(sumSoloFares, 6, RoundingMode.HALF_UP)
                        : BigDecimal.ONE.divide(BigDecimal.valueOf(passengerCount), 6, RoundingMode.HALF_UP);
                BigDecimal baseShareI = sharedCorridorFare.multiply(ratioI).setScale(2, RoundingMode.HALF_UP);

                BigDecimal detourI;
                if (i == passengerCount - 1) {
                    detourI = peerDetourShare.subtract(runningPeerDetour);
                } else {
                    BigDecimal peerRatio = sumPeersSoloFares.compareTo(BigDecimal.ZERO) > 0
                            ? soloFares.get(i).divide(sumPeersSoloFares, 6, RoundingMode.HALF_UP)
                            : BigDecimal.ONE.divide(BigDecimal.valueOf(passengerCount - 1), 6, RoundingMode.HALF_UP);
                    detourI = peerDetourShare.multiply(peerRatio).setScale(2, RoundingMode.HALF_UP);
                    runningPeerDetour = runningPeerDetour.add(detourI);
                }

                rawShares[i] = baseShareI.add(detourI).setScale(2, RoundingMode.HALF_UP);
            }

            // Floor & Cap: Each share must be >= minPassengerFare (unless solo is lower) and <= soloFare
            for (int i = 0; i < passengerCount; i++) {
                BigDecimal solo = soloFares.get(i);
                BigDecimal minAllowed = solo.compareTo(minPassengerFare) < 0 ? solo : minPassengerFare;
                if (rawShares[i].compareTo(minAllowed) < 0) {
                    rawShares[i] = minAllowed;
                }
                if (rawShares[i].compareTo(solo) > 0) {
                    rawShares[i] = solo;
                }
            }

            // Reconcile exact sum to totalVehicleFare (prevent any fractional rounding leaks)
            BigDecimal sumRawShares = BigDecimal.ZERO;
            for (int i = 0; i < passengerCount; i++) {
                sumRawShares = sumRawShares.add(rawShares[i]);
            }

            BigDecimal diff = totalVehicleFare.subtract(sumRawShares);
            if (diff.compareTo(BigDecimal.ZERO) != 0) {
                rawShares[0] = rawShares[0].add(diff).setScale(2, RoundingMode.HALF_UP);
            }

            // Build final PassengerShareDto for ALL passengers
            for (int i = 0; i < passengerCount; i++) {
                PassengerInput p = passengers.get(i);
                BigDecimal solo = soloFares.get(i);
                BigDecimal finalShare = rawShares[i];

                BigDecimal savings = solo.subtract(finalShare).max(BigDecimal.ZERO).setScale(2, RoundingMode.HALF_UP);
                BigDecimal pct = solo.compareTo(BigDecimal.ZERO) > 0
                        ? savings.divide(solo, 4, RoundingMode.HALF_UP).multiply(BigDecimal.valueOf(100)).setScale(1, RoundingMode.HALF_UP)
                        : BigDecimal.ZERO;

                shares.add(new PassengerShareDto(p.passengerId, p.passengerName, finalShare, solo, savings, pct));
            }
        }

        breakdown.setPassengerShares(shares);
        return breakdown;
    }

    public static class PassengerInput {
        public Long passengerId;
        public String passengerName;
        public long distanceMeters;
        public long durationSeconds;

        public PassengerInput(Long passengerId, String passengerName, long distanceMeters, long durationSeconds) {
            this.passengerId = passengerId;
            this.passengerName = passengerName;
            this.distanceMeters = distanceMeters;
            this.durationSeconds = durationSeconds;
        }
    }
}
