package com.ekride.matching.service;

import com.ekride.config.MatchingProperties;
import com.ekride.fare.dto.FareBreakdownDto;
import com.ekride.fare.service.FareCalculationService;
import com.ekride.matching.dto.CandidatePassengerDto;
import com.ekride.matching.dto.RouteOptionDto;
import com.ekride.matching.dto.StopDto;
import com.ekride.routes.dto.LocationDto;
import com.ekride.routes.dto.RouteCalculationResult;
import com.ekride.routes.service.RoutePolylineUtils;
import com.ekride.routes.service.RouteService;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;

@Service
public class RouteInsertionEngine {
    private final RouteService routeService;
    private final FareCalculationService fareCalculationService;
    private final MatchingProperties matchingProperties;

    public RouteInsertionEngine(
            RouteService routeService,
            FareCalculationService fareCalculationService,
            MatchingProperties matchingProperties) {
        this.routeService = routeService;
        this.fareCalculationService = fareCalculationService;
        this.matchingProperties = matchingProperties;
    }

    public RouteOptionDto buildDirectOption(LocationDto origin, LocationDto destination, Long userId, String userName) {
        RouteCalculationResult route = routeService.calculateDirectRoute(origin, destination);
        BigDecimal directSoloFare = fareCalculationService.calculateDirectSoloFare(route.getDistanceMeters(), route.getDurationSeconds());

        RouteOptionDto option = new RouteOptionDto();
        option.setOptionId("option_direct_solo");
        option.setTitle("Direct Solo Ride");
        option.setDescription("Travel directly with zero detour. Fastest individual trip.");
        option.setTotalDistanceMeters(route.getDistanceMeters());
        option.setTotalDurationSeconds(route.getDurationSeconds());
        option.setExtraDistanceMeters(0L);
        option.setExtraDurationSeconds(0L);
        option.setEstimatedTotalFare(directSoloFare);
        option.setUserIndividualFare(directSoloFare);
        option.setDirectSoloFare(directSoloFare);
        option.setEstimatedSavings(BigDecimal.ZERO);
        option.setSavingsPercent(BigDecimal.ZERO);
        option.setAvailableSeats(3);
        option.setEncodedPolyline(route.getEncodedPolyline());
        option.setMatchingScore(1.0);

        List<StopDto> stops = new ArrayList<>();
        stops.add(new StopDto(1, "ORIGIN", origin.getLat(), origin.getLng(), origin.getAddress(), userName));
        stops.add(new StopDto(2, "DESTINATION", destination.getLat(), destination.getLng(), destination.getAddress(), userName));
        option.setStops(stops);

        List<FareCalculationService.PassengerInput> pList = List.of(
                new FareCalculationService.PassengerInput(userId, userName, route.getDistanceMeters(), route.getDurationSeconds())
        );
        FareBreakdownDto fareBreakdown = fareCalculationService.calculateSharedFare(route.getDistanceMeters(), route.getDurationSeconds(), pList, 0L, 0L);
        option.setFareBreakdown(fareBreakdown);

        return option;
    }

    private static class TripSequence {
        final LocationDto start;
        final LocationDto finalDestination;
        final List<LocationDto> waypoints;
        final List<StopDto> stops;

        TripSequence(LocationDto start, LocationDto finalDestination, List<LocationDto> waypoints, List<StopDto> stops) {
            this.start = start;
            this.finalDestination = finalDestination;
            this.waypoints = waypoints;
            this.stops = stops;
        }

        double estimateHaversineDistance() {
            double total = 0;
            LocationDto prev = start;
            for (LocationDto wp : waypoints) {
                total += RoutePolylineUtils.haversineDistanceMeters(prev.getLat(), prev.getLng(), wp.getLat(), wp.getLng());
                prev = wp;
            }
            total += RoutePolylineUtils.haversineDistanceMeters(prev.getLat(), prev.getLng(), finalDestination.getLat(), finalDestination.getLng());
            return total;
        }
    }

        public static double computeCorridorStationing(LocationDto origin, LocationDto destination, double lat, double lng) {
        double dLat = destination.getLat() - origin.getLat();
        double dLng = destination.getLng() - origin.getLng();
        double midLatRad = Math.toRadians(origin.getLat());
        double vx = dLng * Math.cos(midLatRad) * 111320.0;
        double vy = dLat * 111320.0;
        double vLen = Math.sqrt(vx * vx + vy * vy);
        if (vLen < 1.0) {
            return 0.0;
        }
        double ux = (lng - origin.getLng()) * Math.cos(midLatRad) * 111320.0;
        double uy = (lat - origin.getLat()) * 111320.0;
        return (ux * vx + uy * vy) / vLen;
    }

    public static double computeStopStationing(
            LocationDto origin,
            LocationDto destination,
            LocationDto stopLocation,
            List<double[]> baselineRoutePoints) {

        if (stopLocation == null) {
            return 0.0;
        }

        double dToOrig = RoutePolylineUtils.haversineDistanceMeters(stopLocation.getLat(), stopLocation.getLng(), origin.getLat(), origin.getLng());
        if (dToOrig <= 50.0) {
            return 0.0;
        }

        double totalRouteDist = 0.0;
        if (baselineRoutePoints != null && baselineRoutePoints.size() > 1) {
            for (int i = 0; i < baselineRoutePoints.size() - 1; i++) {
                totalRouteDist += RoutePolylineUtils.haversineDistanceMeters(
                        baselineRoutePoints.get(i)[0], baselineRoutePoints.get(i)[1],
                        baselineRoutePoints.get(i + 1)[0], baselineRoutePoints.get(i + 1)[1]);
            }
        }

        double dToDest = RoutePolylineUtils.haversineDistanceMeters(stopLocation.getLat(), stopLocation.getLng(), destination.getLat(), destination.getLng());
        if (dToDest <= 50.0) {
            return totalRouteDist > 0.0 ? totalRouteDist : computeCorridorStationing(origin, destination, destination.getLat(), destination.getLng());
        }

        double sCorridorPoint = computeCorridorStationing(origin, destination, stopLocation.getLat(), stopLocation.getLng());
        double sCorridorDest = computeCorridorStationing(origin, destination, destination.getLat(), destination.getLng());

        // Check 1: If point is physically behind origin along the corridor (e.g. Chankharpul), preserve negative stationing
        if (sCorridorPoint < -50.0) {
            return sCorridorPoint;
        }

        // Check 2: If baseline route points exist, project onto the actual driving polyline
        if (baselineRoutePoints != null && baselineRoutePoints.size() > 1) {
            RoutePolylineUtils.RouteProjection proj = RoutePolylineUtils.projectPointOntoRoute(
                    stopLocation.getLat(), stopLocation.getLng(), baselineRoutePoints, 0.0);
            if (proj != null && proj.getDistanceToRouteMeters() <= 800.0) {
                return proj.getCumulativeDistanceMeters();
            }
        }

        // Check 3: For far-off points ahead of destination (e.g. Kuril), calculate distance beyond destination
        if (sCorridorPoint > sCorridorDest) {
            double extra = sCorridorPoint - sCorridorDest;
            return (totalRouteDist > 0.0 ? totalRouteDist : sCorridorDest) + extra;
        } else {
            if (totalRouteDist > 0.0 && sCorridorDest > 0.0) {
                return (sCorridorPoint / sCorridorDest) * totalRouteDist;
            }
            return sCorridorPoint;
        }
    }

    public RouteOptionDto evaluateCandidateInsertion(
            LocationDto origin,
            LocationDto destination,
            CandidatePassengerDto candidate,
            Long userId,
            String userName,
            RouteCalculationResult baselineDirectRoute,
            int optionIndex) {

        List<double[]> baselineRoutePoints = null;
        if (baselineDirectRoute.getEncodedPolyline() != null && !baselineDirectRoute.getEncodedPolyline().isBlank()) {
            try {
                baselineRoutePoints = RoutePolylineUtils.decode(baselineDirectRoute.getEncodedPolyline());
            } catch (Exception ignored) {}
        }

        // 1. Directional Compatibility Filter (Pruning opposite or diverging trips)
        double uDlat = destination.getLat() - origin.getLat();
        double uDlng = destination.getLng() - origin.getLng();
        double uMag = Math.sqrt(uDlat * uDlat + uDlng * uDlng);

        double cDlat = candidate.getDropoffLat() - candidate.getPickupLat();
        double cDlng = candidate.getDropoffLng() - candidate.getPickupLng();
        double cMag = Math.sqrt(cDlat * cDlat + cDlng * cDlng);

        if (uMag > 1e-6 && cMag > 1e-6) {
            double dot = (uDlat * cDlat + uDlng * cDlng) / (uMag * cMag);
            if (dot < 0.20) { System.out.println("DEBUG: " + candidate.getPassengerName() + " rejected by dot: " + dot);
                // Trip direction diverges by > 78 degrees or is completely opposite (e.g. heading south to Sadarghat)
                return null;
            }
        }

        // 2. Spatial Corridor Proximity Filter (Pickup must not be far-off outside the driving corridor)
        if (baselineRoutePoints != null && !baselineRoutePoints.isEmpty()) {
            double minRouteDist = Double.MAX_VALUE;
            for (double[] pt : baselineRoutePoints) {
                double d = RoutePolylineUtils.haversineDistanceMeters(candidate.getPickupLat(), candidate.getPickupLng(), pt[0], pt[1]);
                if (d < minRouteDist) {
                    minRouteDist = d;
                }
            }
            if (minRouteDist > 3500.0) { System.out.println("DEBUG: " + candidate.getPassengerName() + " rejected by minRouteDist: " + minRouteDist);
                // Far outside the driving corridor (e.g. Sayedabad / Jatrabari / Mirpur 12)
                return null;
            }
        }

        // Apply Intelligent Multi-Condition Pickup & Dropoff Resolvers
        SmartPickupResolver.PickupResolution pickupRes = SmartPickupResolver.resolve(
                origin, destination, candidate, baselineRoutePoints);

        SmartPickupResolver.DropoffResolution dropoffRes = SmartPickupResolver.resolveDropoff(
                origin, destination, candidate, baselineRoutePoints);

        LocationDto cPickup = new LocationDto(
                pickupRes.getResolvedPickupLat(),
                pickupRes.getResolvedPickupLng(),
                pickupRes.getResolvedPickupAddress(),
                pickupRes.getBearing());

        LocationDto cDropoff = new LocationDto(
                dropoffRes.getResolvedDropoffLat(),
                dropoffRes.getResolvedDropoffLng(),
                dropoffRes.getResolvedDropoffAddress(),
                dropoffRes.getBearing());

        boolean isPickupAtOrigin = (pickupRes.getMode() == SmartPickupResolver.PickupMode.WALK_TO_ORIGIN
                || RoutePolylineUtils.haversineDistanceMeters(cPickup.getLat(), cPickup.getLng(), origin.getLat(), origin.getLng()) <= 50.0);
        boolean isDropoffAtDest = (dropoffRes.getMode() == SmartPickupResolver.DropoffMode.ALIGHT_AT_DESTINATION
                || RoutePolylineUtils.haversineDistanceMeters(cDropoff.getLat(), cDropoff.getLng(), destination.getLat(), destination.getLng()) <= 50.0);

        double sOrigin = 0.0;
        double sDest = computeStopStationing(origin, destination, destination, baselineRoutePoints);
        double sPickup = isPickupAtOrigin ? 0.0 : computeStopStationing(origin, destination, cPickup, baselineRoutePoints);
        double sDropoff = isDropoffAtDest ? sDest : computeStopStationing(origin, destination, cDropoff, baselineRoutePoints);



        RouteCalculationResult combinedRoute;
        List<StopDto> stops;

        if (isPickupAtOrigin && isDropoffAtDest) {
            // Case 1: Board together at Origin Gate & Alight together at Destination!
            combinedRoute = baselineDirectRoute;
            stops = List.of(
                    new StopDto(1, "ORIGIN", origin.getLat(), origin.getLng(), origin.getAddress(), userName),
                    new StopDto(2, "PICKUP", origin.getLat(), origin.getLng(), pickupRes.getResolvedPickupAddress(), candidate.getPassengerName()),
                    new StopDto(3, "DROPOFF", destination.getLat(), destination.getLng(), dropoffRes.getResolvedDropoffAddress(), candidate.getPassengerName()),
                    new StopDto(4, "DESTINATION", destination.getLat(), destination.getLng(), destination.getAddress(), userName)
            );
        } else if (isPickupAtOrigin && !isDropoffAtDest) {
            // Case 2: Board together at Origin. Check if dropoff is before or beyond user destination.
            if (sDropoff <= sDest) {
                try {
                    combinedRoute = routeService.calculateWaypointRoute(origin, destination, List.of(cDropoff));
                } catch (Exception e) {
                    combinedRoute = baselineDirectRoute;
                }
                stops = List.of(
                        new StopDto(1, "ORIGIN", origin.getLat(), origin.getLng(), origin.getAddress(), userName),
                        new StopDto(2, "PICKUP", origin.getLat(), origin.getLng(), pickupRes.getResolvedPickupAddress(), candidate.getPassengerName()),
                        new StopDto(3, "DROPOFF", cDropoff.getLat(), cDropoff.getLng(), cDropoff.getAddress(), candidate.getPassengerName()),
                        new StopDto(4, "DESTINATION", destination.getLat(), destination.getLng(), destination.getAddress(), userName)
                );
            } else {
                // Dropoff is beyond user destination (e.g. Kuril). Alight user first, continue to candidate dropoff!
                try {
                    combinedRoute = routeService.calculateWaypointRoute(origin, cDropoff, List.of(destination));
                } catch (Exception e) {
                    combinedRoute = baselineDirectRoute;
                }
                stops = List.of(
                        new StopDto(1, "ORIGIN", origin.getLat(), origin.getLng(), origin.getAddress(), userName),
                        new StopDto(2, "PICKUP", origin.getLat(), origin.getLng(), pickupRes.getResolvedPickupAddress(), candidate.getPassengerName()),
                        new StopDto(3, "DESTINATION", destination.getLat(), destination.getLng(), destination.getAddress(), userName),
                        new StopDto(4, "DROPOFF", cDropoff.getLat(), cDropoff.getLng(), cDropoff.getAddress(), candidate.getPassengerName())
                );
            }
        } else if (!isPickupAtOrigin && isDropoffAtDest) {
            // Case 3: Alight together at Destination. Check if pickup is ahead of or behind user origin.
            if (sPickup >= sOrigin) {
                try {
                    combinedRoute = routeService.calculateWaypointRoute(origin, destination, List.of(cPickup));
                } catch (Exception e) {
                    combinedRoute = baselineDirectRoute;
                }
                stops = List.of(
                        new StopDto(1, "ORIGIN", origin.getLat(), origin.getLng(), origin.getAddress(), userName),
                        new StopDto(2, "PICKUP", cPickup.getLat(), cPickup.getLng(), cPickup.getAddress(), candidate.getPassengerName()),
                        new StopDto(3, "DROPOFF", destination.getLat(), destination.getLng(), dropoffRes.getResolvedDropoffAddress(), candidate.getPassengerName()),
                        new StopDto(4, "DESTINATION", destination.getLat(), destination.getLng(), destination.getAddress(), userName)
                );
            } else {
                // Pickup is behind user origin (e.g. Chankharpul). Start at candidate pickup, pick up user on the way!
                try {
                    combinedRoute = routeService.calculateWaypointRoute(cPickup, destination, List.of(origin));
                } catch (Exception e) {
                    combinedRoute = baselineDirectRoute;
                }
                stops = List.of(
                        new StopDto(1, "PICKUP", cPickup.getLat(), cPickup.getLng(), cPickup.getAddress(), candidate.getPassengerName()),
                        new StopDto(2, "ORIGIN", origin.getLat(), origin.getLng(), origin.getAddress(), userName),
                        new StopDto(3, "DROPOFF", destination.getLat(), destination.getLng(), dropoffRes.getResolvedDropoffAddress(), candidate.getPassengerName()),
                        new StopDto(4, "DESTINATION", destination.getLat(), destination.getLng(), destination.getAddress(), userName)
                );
            }
        } else {
            // Case 4: Neither at origin nor at destination. Check forward sequencing.
            List<TripSequence> sequences = new ArrayList<>();

            if (sPickup >= sOrigin && sDropoff <= sDest) {
                // Seq 1: Origin -> Pickup -> Dropoff -> Destination
                sequences.add(new TripSequence(
                        origin, destination, List.of(cPickup, cDropoff),
                        List.of(
                                new StopDto(1, "ORIGIN", origin.getLat(), origin.getLng(), origin.getAddress(), userName),
                                new StopDto(2, "PICKUP", cPickup.getLat(), cPickup.getLng(), cPickup.getAddress(), candidate.getPassengerName()),
                                new StopDto(3, "DROPOFF", cDropoff.getLat(), cDropoff.getLng(), cDropoff.getAddress(), candidate.getPassengerName()),
                                new StopDto(4, "DESTINATION", destination.getLat(), destination.getLng(), destination.getAddress(), userName)
                        )
                ));
            } else if (sPickup >= sOrigin && sDropoff > sDest) {
                // Seq 2: Origin -> Pickup -> Destination -> Dropoff
                sequences.add(new TripSequence(
                        origin, cDropoff, List.of(cPickup, destination),
                        List.of(
                                new StopDto(1, "ORIGIN", origin.getLat(), origin.getLng(), origin.getAddress(), userName),
                                new StopDto(2, "PICKUP", cPickup.getLat(), cPickup.getLng(), cPickup.getAddress(), candidate.getPassengerName()),
                                new StopDto(3, "DESTINATION", destination.getLat(), destination.getLng(), destination.getAddress(), userName),
                                new StopDto(4, "DROPOFF", cDropoff.getLat(), cDropoff.getLng(), cDropoff.getAddress(), candidate.getPassengerName())
                        )
                ));
            } else if (sPickup < sOrigin && sDropoff <= sDest) {
                // Seq 3: Pickup -> Origin -> Dropoff -> Destination
                sequences.add(new TripSequence(
                        cPickup, destination, List.of(origin, cDropoff),
                        List.of(
                                new StopDto(1, "PICKUP", cPickup.getLat(), cPickup.getLng(), cPickup.getAddress(), candidate.getPassengerName()),
                                new StopDto(2, "ORIGIN", origin.getLat(), origin.getLng(), origin.getAddress(), userName),
                                new StopDto(3, "DROPOFF", cDropoff.getLat(), cDropoff.getLng(), cDropoff.getAddress(), candidate.getPassengerName()),
                                new StopDto(4, "DESTINATION", destination.getLat(), destination.getLng(), destination.getAddress(), userName)
                        )
                ));
            } else {
                // Seq 4: Pickup -> Origin -> Destination -> Dropoff (e.g. Rohan: Chankharpul to Kuril)
                sequences.add(new TripSequence(
                        cPickup, cDropoff, List.of(origin, destination),
                        List.of(
                                new StopDto(1, "PICKUP", cPickup.getLat(), cPickup.getLng(), cPickup.getAddress(), candidate.getPassengerName()),
                                new StopDto(2, "ORIGIN", origin.getLat(), origin.getLng(), origin.getAddress(), userName),
                                new StopDto(3, "DESTINATION", destination.getLat(), destination.getLng(), destination.getAddress(), userName),
                                new StopDto(4, "DROPOFF", cDropoff.getLat(), cDropoff.getLng(), cDropoff.getAddress(), candidate.getPassengerName())
                        )
                ));
            }

            TripSequence bestSequence = sequences.get(0);
            RouteCalculationResult bestRoute = null;

            for (TripSequence seq : sequences) {
                try {
                    RouteCalculationResult r = routeService.calculateWaypointRoute(seq.start, seq.finalDestination, seq.waypoints);
                    if (bestRoute == null 
                            || r.getDistanceMeters() < bestRoute.getDistanceMeters()
                            || (r.getDistanceMeters() == bestRoute.getDistanceMeters() && r.getDurationSeconds() < bestRoute.getDurationSeconds())) {
                        bestRoute = r;
                        bestSequence = seq;
                    }
                } catch (Exception ignored) {}
            }

            if (bestRoute == null) {
                bestRoute = baselineDirectRoute;
            }

            combinedRoute = bestRoute;
            stops = bestSequence.stops;
        }

        // ─────────────────────────────────────────────────────────────
        // Accurate Distance-Proportional Fare Allocation
        // Compute candidate personal trip leg (from cPickup to cDropoff)
        // ─────────────────────────────────────────────────────────────
        long candidateTripDist;
        long candidateTripDur;

        if (isPickupAtOrigin && isDropoffAtDest) {
            candidateTripDist = baselineDirectRoute.getDistanceMeters();
            candidateTripDur = baselineDirectRoute.getDurationSeconds();
        } else {
            try {
                RouteCalculationResult candLeg = routeService.calculateDirectRoute(cPickup, cDropoff);
                candidateTripDist = candLeg.getDistanceMeters();
                candidateTripDur = candLeg.getDurationSeconds();
            } catch (Exception e) {
                double totalH = RoutePolylineUtils.haversineDistanceMeters(origin.getLat(), origin.getLng(), destination.getLat(), destination.getLng());
                double candH = RoutePolylineUtils.haversineDistanceMeters(cPickup.getLat(), cPickup.getLng(), cDropoff.getLat(), cDropoff.getLng());
                double ratio = totalH > 0 ? Math.min(1.0, candH / totalH) : 1.0;
                candidateTripDist = Math.max(1000L, Math.round(baselineDirectRoute.getDistanceMeters() * ratio));
                candidateTripDur = Math.max(120L, Math.round(baselineDirectRoute.getDurationSeconds() * ratio));
            }
        }

        long maxSoloTripDist = Math.max(baselineDirectRoute.getDistanceMeters(), candidateTripDist);
        long maxSoloTripDur = Math.max(baselineDirectRoute.getDurationSeconds(), candidateTripDur);

        long extraDist;
        long extraDur;

        boolean isZeroDetour = (isPickupAtOrigin || pickupRes.getMode() == SmartPickupResolver.PickupMode.WALK_TO_ROUTE || pickupRes.getMode() == SmartPickupResolver.PickupMode.MEET_AT_HUB)
                && (isDropoffAtDest || dropoffRes.getMode() == SmartPickupResolver.DropoffMode.CURBSIDE_ON_ROUTE || dropoffRes.getMode() == SmartPickupResolver.DropoffMode.MEET_AT_HUB);

        if (isZeroDetour) {
            long dDiff = combinedRoute.getDistanceMeters() - maxSoloTripDist;
            long tDiff = combinedRoute.getDurationSeconds() - maxSoloTripDur;
            extraDist = (dDiff < 400) ? 0L : Math.max(0, dDiff);
            extraDur = (tDiff < 90) ? 0L : Math.max(0, tDiff);
        } else {
            extraDist = Math.max(0, combinedRoute.getDistanceMeters() - maxSoloTripDist);
            extraDur = Math.max(0, combinedRoute.getDurationSeconds() - maxSoloTripDur);
        }

        boolean detourAcceptable = extraDist <= (matchingProperties.getMaxDetourMeters() * 1.5)
                && (extraDur / 60.0) <= (matchingProperties.getMaxDetourMinutes() * 1.5);

        if (!detourAcceptable) {
            return null;
        }

        List<FareCalculationService.PassengerInput> passengers = List.of(
                new FareCalculationService.PassengerInput(userId, userName, baselineDirectRoute.getDistanceMeters(), baselineDirectRoute.getDurationSeconds()),
                new FareCalculationService.PassengerInput(candidate.getPassengerId(), candidate.getPassengerName(), candidateTripDist, candidateTripDur)
        );

        FareBreakdownDto fareBreakdown = fareCalculationService.calculateSharedFare(
                combinedRoute.getDistanceMeters(),
                combinedRoute.getDurationSeconds(),
                passengers,
                extraDist,
                extraDur);

        BigDecimal userShare = fareBreakdown.getPassengerShares().get(0).getIndividualFare();
        BigDecimal directSoloFare = fareBreakdown.getPassengerShares().get(0).getDirectSoloFare();
        BigDecimal userSavings = fareBreakdown.getPassengerShares().get(0).getSavings();
        BigDecimal savingsPercent = fareBreakdown.getPassengerShares().get(0).getSavingsPercent();

        BigDecimal peerShare = fareBreakdown.getPassengerShares().get(1).getIndividualFare();

        String pickupPart;
        switch (pickupRes.getMode()) {
            case WALK_TO_ORIGIN:
                pickupPart = String.format("Board together at origin • %s walks %d mins",
                        candidate.getPassengerName(), Math.max(1, (int) Math.round(pickupRes.getWalkingDistanceMeters() / 75.0)));
                break;
            case WALK_TO_ROUTE:
                pickupPart = String.format("Main road pickup • %s walks %d mins",
                        candidate.getPassengerName(), Math.max(1, (int) Math.round(pickupRes.getWalkingDistanceMeters() / 75.0)));
                break;
            case MEET_AT_HUB:
                pickupPart = String.format("Major junction meet • %s walks %d mins",
                        candidate.getPassengerName(), Math.max(1, (int) Math.round(pickupRes.getWalkingDistanceMeters() / 75.0)));
                break;
            case DOORSTEP_DETOUR:
            default:
                pickupPart = "Main road curbside pickup";
                break;
        }

        String dropoffPart;
        switch (dropoffRes.getMode()) {
            case ALIGHT_AT_DESTINATION:
                dropoffPart = "alight together at destination";
                break;
            case CURBSIDE_ON_ROUTE:
                dropoffPart = "main road dropoff";
                break;
            case MEET_AT_HUB:
                dropoffPart = "major junction dropoff";
                break;
            case DOORSTEP_DETOUR:
            default:
                long extraMins = Math.round(extraDur / 60.0);
                double extraKm = extraDist / 1000.0;
                dropoffPart = String.format("main road detour (+%d mins, +%.1f km)", extraMins, extraKm);
                break;
        }

        String detourNotice = pickupPart + " • " + dropoffPart;

        String detourContributionText = "";
        if (fareBreakdown.getDetourCostComponent() != null && fareBreakdown.getDetourCostComponent().compareTo(BigDecimal.ZERO) > 0) {
            detourContributionText = String.format(" (Detour fare ৳%s: 60%% %s, 40%% You)",
                    fareBreakdown.getDetourCostComponent().setScale(0, RoundingMode.HALF_UP),
                    candidate.getPassengerName());
        }

        RouteOptionDto option = new RouteOptionDto();
        option.setOptionId("option_shared_" + candidate.getRideId() + "_" + optionIndex);
        option.setTitle("Shared with " + candidate.getPassengerName() + " (" + candidate.getUniversity() + ")");
        option.setDescription(String.format("You pay ৳%s (Save ৳%s, %.0f%%) • %s pays ৳%s%s • %s.",
                userShare.setScale(0, RoundingMode.HALF_UP),
                userSavings.setScale(0, RoundingMode.HALF_UP),
                savingsPercent.doubleValue(),
                candidate.getPassengerName(),
                peerShare.setScale(0, RoundingMode.HALF_UP),
                detourContributionText,
                detourNotice));
        option.setTotalDistanceMeters(combinedRoute.getDistanceMeters());
        option.setTotalDurationSeconds(combinedRoute.getDurationSeconds());
        option.setExtraDistanceMeters(extraDist);
        option.setExtraDurationSeconds(extraDur);
        option.setEstimatedTotalFare(fareBreakdown.getTotalVehicleFare());
        option.setUserIndividualFare(userShare);
        option.setDirectSoloFare(directSoloFare);
        option.setEstimatedSavings(userSavings);
        option.setSavingsPercent(savingsPercent);
        option.setAvailableSeats(Math.max(1, candidate.getAvailableSeats() - 1));
        option.setEncodedPolyline(combinedRoute.getEncodedPolyline());
        option.setStops(stops);
        option.setFareBreakdown(fareBreakdown);

        double bonus = (isPickupAtOrigin ? 25.0 : 0.0) + (isDropoffAtDest ? 25.0 : 0.0);
        double score = (userSavings.doubleValue() * 1.5) - ((extraDur / 60.0) * 10.0) - ((extraDist / 1000.0) * 12.0) + (candidate.getRating() * 5.0) + bonus;
        option.setMatchingScore(score);

        // Detour is verified acceptable (within maxDetourMeters and maxDetourMinutes)

        return option;
    }


    public RouteOptionDto buildMultiPassengerOption(
            LocationDto origin,
            LocationDto destination,
            List<CandidatePassengerDto> candidates,
            Long userId,
            String userName,
            RouteCalculationResult baselineDirectRoute,
            int optionIndex) {

        if (candidates == null || candidates.isEmpty()) {
            return null;
        }

        List<double[]> baselineRoutePoints = null;
        if (baselineDirectRoute.getEncodedPolyline() != null && !baselineDirectRoute.getEncodedPolyline().isBlank()) {
            try {
                baselineRoutePoints = RoutePolylineUtils.decode(baselineDirectRoute.getEncodedPolyline());
            } catch (Exception ignored) {}
        }

        class ResolvedCand {
            final CandidatePassengerDto candidate;
            final SmartPickupResolver.PickupResolution pRes;
            final SmartPickupResolver.DropoffResolution dRes;
            final LocationDto pickup;
            final LocationDto dropoff;
            final double pickupRouteDist;
            final double dropoffRouteDist;

            ResolvedCand(CandidatePassengerDto candidate,
                         SmartPickupResolver.PickupResolution pRes,
                         SmartPickupResolver.DropoffResolution dRes,
                         LocationDto origin, LocationDto destination) {
                this.candidate = candidate;
                this.pRes = pRes;
                this.dRes = dRes;
                this.pickup = new LocationDto(pRes.getResolvedPickupLat(), pRes.getResolvedPickupLng(), pRes.getResolvedPickupAddress(), pRes.getBearing());
                this.dropoff = new LocationDto(dRes.getResolvedDropoffLat(), dRes.getResolvedDropoffLng(), dRes.getResolvedDropoffAddress(), dRes.getBearing());
                this.pickupRouteDist = pRes.getCumulativeDistanceMeters();
                this.dropoffRouteDist = dRes.getCumulativeDistanceMeters();
            }
        }

        List<ResolvedCand> resolvedList = new ArrayList<>();
        for (CandidatePassengerDto c : candidates) {
            SmartPickupResolver.PickupResolution pRes = SmartPickupResolver.resolve(origin, destination, c, baselineRoutePoints);
            SmartPickupResolver.DropoffResolution dRes = SmartPickupResolver.resolveDropoff(origin, destination, c, baselineRoutePoints);
            resolvedList.add(new ResolvedCand(c, pRes, dRes, origin, destination));
        }

class PoolStopItem {
            final String type; // ORIGIN, PICKUP, DROPOFF, DESTINATION
            final LocationDto location;
            final String passengerName;
            final double stationing;
            final boolean isPickup;

            PoolStopItem(String type, LocationDto location, String passengerName, double stationing, boolean isPickup) {
                this.type = type;
                this.location = location;
                this.passengerName = passengerName;
                this.stationing = stationing;
                this.isPickup = isPickup;
            }
        }

        double sDest = computeStopStationing(origin, destination, destination, baselineRoutePoints);
        List<PoolStopItem> allPoolStops = new ArrayList<>();
        allPoolStops.add(new PoolStopItem("ORIGIN", origin, userName, 0.0, true));
        allPoolStops.add(new PoolStopItem("DESTINATION", destination, userName, sDest, false));

        for (ResolvedCand rc : resolvedList) {
            boolean isPAtOrig = (rc.pRes.getMode() == SmartPickupResolver.PickupMode.WALK_TO_ORIGIN
                    || RoutePolylineUtils.haversineDistanceMeters(rc.pickup.getLat(), rc.pickup.getLng(), origin.getLat(), origin.getLng()) <= 50.0);
            boolean isDAtDest = (rc.dRes.getMode() == SmartPickupResolver.DropoffMode.ALIGHT_AT_DESTINATION
                    || RoutePolylineUtils.haversineDistanceMeters(rc.dropoff.getLat(), rc.dropoff.getLng(), destination.getLat(), destination.getLng()) <= 50.0);

            double sPick = isPAtOrig ? 0.0 : computeStopStationing(origin, destination, rc.pickup, baselineRoutePoints);
            double sDrop = isDAtDest ? sDest : computeStopStationing(origin, destination, rc.dropoff, baselineRoutePoints);

            allPoolStops.add(new PoolStopItem("PICKUP", rc.pickup, rc.candidate.getPassengerName(), sPick, true));
            allPoolStops.add(new PoolStopItem("DROPOFF", rc.dropoff, rc.candidate.getPassengerName(), sDrop, false));
        }

        // Sort all stops strictly along the forward driving corridor
        allPoolStops.sort((a, b) -> {
            int cmp = Double.compare(a.stationing, b.stationing);
            if (cmp != 0) return cmp;
            if (a.isPickup != b.isPickup) {
                return a.isPickup ? -1 : 1; // Pickups before dropoffs at same location
            }
            if ("DESTINATION".equals(a.type)) return 1;
            if ("DESTINATION".equals(b.type)) return -1;
            if ("ORIGIN".equals(a.type)) return -1;
            if ("ORIGIN".equals(b.type)) return 1;
            return 0;
        });

        LocationDto tripStart = allPoolStops.get(0).location;
        LocationDto tripEnd = allPoolStops.get(allPoolStops.size() - 1).location;

        List<LocationDto> waypoints = new ArrayList<>();
        for (int i = 1; i < allPoolStops.size() - 1; i++) {
            PoolStopItem psi = allPoolStops.get(i);
            double distToStart = RoutePolylineUtils.haversineDistanceMeters(tripStart.getLat(), tripStart.getLng(), psi.location.getLat(), psi.location.getLng());
            double distToEnd = RoutePolylineUtils.haversineDistanceMeters(tripEnd.getLat(), tripEnd.getLng(), psi.location.getLat(), psi.location.getLng());
            if (distToStart > 120.0 && distToEnd > 120.0) {
                boolean shouldAdd = true;
                if (!waypoints.isEmpty()) {
                    LocationDto lastWp = waypoints.get(waypoints.size() - 1);
                    double distToLast = RoutePolylineUtils.haversineDistanceMeters(lastWp.getLat(), lastWp.getLng(), psi.location.getLat(), psi.location.getLng());
                    if (distToLast <= 120.0) {
                        shouldAdd = false; // Consolidate into same curbside stop zone
                    }
                }
                if (shouldAdd) {
                    waypoints.add(psi.location);
                }
            }
        }

        List<StopDto> stops = new ArrayList<>();
        int order = 1;
        for (PoolStopItem psi : allPoolStops) {
            stops.add(new StopDto(order++, psi.type, psi.location.getLat(), psi.location.getLng(), psi.location.getAddress(), psi.passengerName));
        }

        RouteCalculationResult combinedRoute;
        try {
            combinedRoute = routeService.calculateWaypointRoute(tripStart, tripEnd, waypoints);
        } catch (Exception e) {
            combinedRoute = baselineDirectRoute;
        }

        List<FareCalculationService.PassengerInput> passengerInputs = new ArrayList<>();
        passengerInputs.add(new FareCalculationService.PassengerInput(userId, userName, baselineDirectRoute.getDistanceMeters(), baselineDirectRoute.getDurationSeconds()));

        long maxSoloDist = baselineDirectRoute.getDistanceMeters();
        long maxSoloDur = baselineDirectRoute.getDurationSeconds();

        for (ResolvedCand rc : resolvedList) {
            long candDist;
            long candDur;
            try {
                RouteCalculationResult leg = routeService.calculateDirectRoute(rc.pickup, rc.dropoff);
                candDist = leg.getDistanceMeters();
                candDur = leg.getDurationSeconds();
            } catch (Exception ex) {
                double totalH = RoutePolylineUtils.haversineDistanceMeters(origin.getLat(), origin.getLng(), destination.getLat(), destination.getLng());
                double candH = RoutePolylineUtils.haversineDistanceMeters(rc.pickup.getLat(), rc.pickup.getLng(), rc.dropoff.getLat(), rc.dropoff.getLng());
                double ratio = totalH > 0 ? Math.min(1.0, candH / totalH) : 0.8;
                candDist = Math.max(1000L, Math.round(baselineDirectRoute.getDistanceMeters() * ratio));
                candDur = Math.max(120L, Math.round(baselineDirectRoute.getDurationSeconds() * ratio));
            }
            if (candDist > maxSoloDist) {
                maxSoloDist = candDist;
            }
            if (candDur > maxSoloDur) {
                maxSoloDur = candDur;
            }
            passengerInputs.add(new FareCalculationService.PassengerInput(rc.candidate.getPassengerId(), rc.candidate.getPassengerName(), candDist, candDur));
        }

        long extraDist = Math.max(0, combinedRoute.getDistanceMeters() - maxSoloDist);
        long extraDur = Math.max(0, combinedRoute.getDurationSeconds() - maxSoloDur);

        FareBreakdownDto fareBreakdown = fareCalculationService.calculateSharedFare(
                combinedRoute.getDistanceMeters(),
                combinedRoute.getDurationSeconds(),
                passengerInputs,
                extraDist,
                extraDur);


        BigDecimal userShare = fareBreakdown.getPassengerShares().get(0).getIndividualFare();
        BigDecimal directSoloFare = fareBreakdown.getPassengerShares().get(0).getDirectSoloFare();
        BigDecimal userSavings = fareBreakdown.getPassengerShares().get(0).getSavings();
        BigDecimal savingsPercent = fareBreakdown.getPassengerShares().get(0).getSavingsPercent();

        int totalRiders = candidates.size() + 1;
        List<String> firstNames = candidates.stream().map(c -> c.getPassengerName().split(" ")[0]).toList();
        String namesJoined = String.join(" & ", firstNames);

        String poolType = (totalRiders == 3) ? "Triple Pool" : (totalRiders == 4) ? "Quad Pool" : (totalRiders + " Riders Pool");

        RouteOptionDto option = new RouteOptionDto();
        option.setOptionId("option_pool_" + totalRiders + "_" + optionIndex);
        option.setTitle(poolType + ": " + namesJoined + " (" + totalRiders + " Passengers)");
        option.setDescription(String.format("You pay ৳%s (Save ৳%s, %.0f%%) • %d riders sharing ride • Detour +%d mins.",
                userShare.setScale(0, RoundingMode.HALF_UP),
                userSavings.setScale(0, RoundingMode.HALF_UP),
                savingsPercent.doubleValue(),
                totalRiders,
                Math.round(extraDur / 60.0)));
        option.setTotalDistanceMeters(combinedRoute.getDistanceMeters());
        option.setTotalDurationSeconds(combinedRoute.getDurationSeconds());
        option.setExtraDistanceMeters(extraDist);
        option.setExtraDurationSeconds(extraDur);
        option.setEstimatedTotalFare(fareBreakdown.getTotalVehicleFare());
        option.setUserIndividualFare(userShare);
        option.setDirectSoloFare(directSoloFare);
        option.setEstimatedSavings(userSavings);
        option.setSavingsPercent(savingsPercent);
        option.setAvailableSeats(Math.max(0, 4 - totalRiders));
        option.setEncodedPolyline(combinedRoute.getEncodedPolyline());
        option.setStops(stops);
        option.setFareBreakdown(fareBreakdown);

        double score = (userSavings.doubleValue() * 2.0) - ((extraDur / 60.0) * 12.0) - ((extraDist / 1000.0) * 10.0) + (totalRiders * 15.0);
        option.setMatchingScore(score);

        return option;
    }
}
