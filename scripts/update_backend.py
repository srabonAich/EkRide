import os

smart_pickup_content = """package com.ekride.matching.service;

import com.ekride.matching.dto.CandidatePassengerDto;
import com.ekride.routes.dto.LocationDto;
import com.ekride.routes.service.RoutePolylineUtils;

import java.util.List;

public class SmartPickupResolver {

    public enum PickupMode {
        WALK_TO_ORIGIN,    // Peer is within 350m of user origin: walks to origin gate
        WALK_TO_ROUTE,     // Peer is within 450m of best driving route: walks curbside to road
        MEET_AT_HUB,       // Peer is 450m - 800m from route: meets at nearby transit hub
        DOORSTEP_DETOUR    // Peer is > 800m from route: car makes driving detour to passenger location
    }

    public enum DropoffMode {
        ALIGHT_AT_DESTINATION, // Peer dropoff is within 350m of user destination: alight together at destination
        CURBSIDE_ON_ROUTE,     // Peer dropoff is within 450m of driving route: curbside dropoff on corridor
        MEET_AT_HUB,           // Peer dropoff is 450m - 800m from route: dropoff at nearest corridor transit hub
        DOORSTEP_DETOUR        // Peer dropoff is > 800m from route: car makes real driving detour to doorstep
    }

    public static class PickupResolution {
        private PickupMode mode;
        private double resolvedPickupLat;
        private double resolvedPickupLng;
        private String resolvedPickupAddress;
        private double walkingDistanceMeters;
        private double cumulativeDistanceMeters;
        private String descriptionNotice;

        public PickupMode getMode() { return mode; }
        public void setMode(PickupMode mode) { this.mode = mode; }
        public double getResolvedPickupLat() { return resolvedPickupLat; }
        public void setResolvedPickupLat(double resolvedPickupLat) { this.resolvedPickupLat = resolvedPickupLat; }
        public double getResolvedPickupLng() { return resolvedPickupLng; }
        public void setResolvedPickupLng(double resolvedPickupLng) { this.resolvedPickupLng = resolvedPickupLng; }
        public String getResolvedPickupAddress() { return resolvedPickupAddress; }
        public void setResolvedPickupAddress(String resolvedPickupAddress) { this.resolvedPickupAddress = resolvedPickupAddress; }
        public double getWalkingDistanceMeters() { return walkingDistanceMeters; }
        public void setWalkingDistanceMeters(double walkingDistanceMeters) { this.walkingDistanceMeters = walkingDistanceMeters; }
        public double getCumulativeDistanceMeters() { return cumulativeDistanceMeters; }
        public void setCumulativeDistanceMeters(double cumulativeDistanceMeters) { this.cumulativeDistanceMeters = cumulativeDistanceMeters; }
        public String getDescriptionNotice() { return descriptionNotice; }
        public void setDescriptionNotice(String descriptionNotice) { this.descriptionNotice = descriptionNotice; }
    }

    public static class DropoffResolution {
        private DropoffMode mode;
        private double resolvedDropoffLat;
        private double resolvedDropoffLng;
        private String resolvedDropoffAddress;
        private double walkingDistanceMeters;
        private double cumulativeDistanceMeters;
        private String descriptionNotice;

        public DropoffMode getMode() { return mode; }
        public void setMode(DropoffMode mode) { this.mode = mode; }
        public double getResolvedDropoffLat() { return resolvedDropoffLat; }
        public void setResolvedDropoffLat(double resolvedDropoffLat) { this.resolvedDropoffLat = resolvedDropoffLat; }
        public double getResolvedDropoffLng() { return resolvedDropoffLng; }
        public void setResolvedDropoffLng(double resolvedDropoffLng) { this.resolvedDropoffLng = resolvedDropoffLng; }
        public String getResolvedDropoffAddress() { return resolvedDropoffAddress; }
        public void setResolvedDropoffAddress(String resolvedDropoffAddress) { this.resolvedDropoffAddress = resolvedDropoffAddress; }
        public double getWalkingDistanceMeters() { return walkingDistanceMeters; }
        public void setWalkingDistanceMeters(double walkingDistanceMeters) { this.walkingDistanceMeters = walkingDistanceMeters; }
        public double getCumulativeDistanceMeters() { return cumulativeDistanceMeters; }
        public void setCumulativeDistanceMeters(double cumulativeDistanceMeters) { this.cumulativeDistanceMeters = cumulativeDistanceMeters; }
        public String getDescriptionNotice() { return descriptionNotice; }
        public void setDescriptionNotice(String descriptionNotice) { this.descriptionNotice = descriptionNotice; }
    }

    public static PickupResolution resolve(
            LocationDto origin,
            LocationDto destination,
            CandidatePassengerDto candidate,
            List<double[]> routePoints) {

        PickupResolution res = new PickupResolution();
        double distToOrigin = RoutePolylineUtils.haversineDistanceMeters(
                candidate.getPickupLat(), candidate.getPickupLng(), origin.getLat(), origin.getLng());

        // Condition 1: Peer is within walking distance of origin (<= 350m)
        if (distToOrigin <= 350.0) {
            res.setMode(PickupMode.WALK_TO_ORIGIN);
            res.setResolvedPickupLat(origin.getLat());
            res.setResolvedPickupLng(origin.getLng());
            res.setResolvedPickupAddress(origin.getAddress() + " (Board Together)");
            res.setWalkingDistanceMeters(distToOrigin);
            res.setCumulativeDistanceMeters(0.0);
            int walkMins = Math.max(1, (int) Math.round(distToOrigin / 75.0));
            res.setDescriptionNotice(String.format("%s walks %d mins to meet you at boarding gate (0 min car detour)",
                    candidate.getPassengerName(), walkMins));
            return res;
        }

        // Continuous orthogonal projection onto directed route segments with 35m intersection setback
        RoutePolylineUtils.RouteProjection proj = RoutePolylineUtils.projectPointOntoRoute(
                candidate.getPickupLat(), candidate.getPickupLng(), routePoints, 35.0);

        double minDistToRoute = proj != null ? proj.getDistanceToRouteMeters() : Double.MAX_VALUE;
        double cumDist = proj != null ? proj.getCumulativeDistanceMeters() : distToOrigin;

        // Condition 2: Peer is close to the driving route (<= 450m)
        // Snaps to continuous curbside lane on car's direction of travel (zero U-turns)
        if (proj != null && minDistToRoute <= 450.0) {
            res.setMode(PickupMode.WALK_TO_ROUTE);
            res.setResolvedPickupLat(proj.getLat());
            res.setResolvedPickupLng(proj.getLng());
            res.setResolvedPickupAddress(candidate.getPickupAddress() + " (Curbside Stop on Route)");
            res.setWalkingDistanceMeters(minDistToRoute);
            res.setCumulativeDistanceMeters(cumDist);
            int walkMins = Math.max(1, (int) Math.round(minDistToRoute / 75.0));
            res.setDescriptionNotice(String.format("%s walks %d mins to curbside stop on route (0 min car detour)",
                    candidate.getPassengerName(), walkMins));
            return res;
        }

        // Condition 3: Peer is moderate distance from route (450m - 800m)
        if (proj != null && minDistToRoute <= 800.0) {
            res.setMode(PickupMode.MEET_AT_HUB);
            res.setResolvedPickupLat(proj.getLat());
            res.setResolvedPickupLng(proj.getLng());
            res.setResolvedPickupAddress("Transit Hub Meet (" + candidate.getPickupAddress() + ")");
            res.setWalkingDistanceMeters(minDistToRoute);
            res.setCumulativeDistanceMeters(cumDist);
            int walkMins = Math.max(1, (int) Math.round(minDistToRoute / 75.0));
            res.setDescriptionNotice(String.format("Meet %s at transit hub on route (walks %d mins)",
                    candidate.getPassengerName(), walkMins));
            return res;
        }

        // Condition 4: Peer is further away (> 800m) - Doorstep Detour
        res.setMode(PickupMode.DOORSTEP_DETOUR);
        res.setResolvedPickupLat(candidate.getPickupLat());
        res.setResolvedPickupLng(candidate.getPickupLng());
        res.setResolvedPickupAddress(candidate.getPickupAddress());
        res.setWalkingDistanceMeters(0.0);
        res.setCumulativeDistanceMeters(cumDist);
        res.setDescriptionNotice("Doorstep pickup with car detour");
        return res;
    }

    public static DropoffResolution resolveDropoff(
            LocationDto origin,
            LocationDto destination,
            CandidatePassengerDto candidate,
            List<double[]> routePoints) {

        DropoffResolution res = new DropoffResolution();
        double distToDest = RoutePolylineUtils.haversineDistanceMeters(
                candidate.getDropoffLat(), candidate.getDropoffLng(), destination.getLat(), destination.getLng());

        // Condition 1: Dropoff is within walking distance of destination (<= 350m)
        if (distToDest <= 350.0) {
            res.setMode(DropoffMode.ALIGHT_AT_DESTINATION);
            res.setResolvedDropoffLat(destination.getLat());
            res.setResolvedDropoffLng(destination.getLng());
            res.setResolvedDropoffAddress(destination.getAddress() + " (Alight Together)");
            res.setWalkingDistanceMeters(distToDest);
            double totalRouteDist = 0.0;
            if (routePoints != null && routePoints.size() > 1) {
                for (int i = 0; i < routePoints.size() - 1; i++) {
                    totalRouteDist += RoutePolylineUtils.haversineDistanceMeters(
                            routePoints.get(i)[0], routePoints.get(i)[1],
                            routePoints.get(i + 1)[0], routePoints.get(i + 1)[1]);
                }
            }
            res.setCumulativeDistanceMeters(totalRouteDist);
            int walkMins = Math.max(1, (int) Math.round(distToDest / 75.0));
            res.setDescriptionNotice(String.format("%s alights together with you at destination (walks %d mins, 0 min car detour)",
                    candidate.getPassengerName(), walkMins));
            return res;
        }

        // Continuous orthogonal projection onto directed route segments with 35m intersection setback
        RoutePolylineUtils.RouteProjection proj = RoutePolylineUtils.projectPointOntoRoute(
                candidate.getDropoffLat(), candidate.getDropoffLng(), routePoints, 35.0);

        double minDistToRoute = proj != null ? proj.getDistanceToRouteMeters() : Double.MAX_VALUE;
        double cumDist = proj != null ? proj.getCumulativeDistanceMeters() : 0.0;

        // Condition 2: Dropoff is close to the driving route (<= 450m)
        if (proj != null && minDistToRoute <= 450.0) {
            res.setMode(DropoffMode.CURBSIDE_ON_ROUTE);
            res.setResolvedDropoffLat(proj.getLat());
            res.setResolvedDropoffLng(proj.getLng());
            res.setResolvedDropoffAddress(candidate.getDropoffAddress() + " (Curbside Dropoff on Route)");
            res.setWalkingDistanceMeters(minDistToRoute);
            res.setCumulativeDistanceMeters(cumDist);
            int walkMins = Math.max(1, (int) Math.round(minDistToRoute / 75.0));
            res.setDescriptionNotice(String.format("Curbside dropoff for %s on corridor (walks %d mins, 0 min car detour)",
                    candidate.getPassengerName(), walkMins));
            return res;
        }

        // Condition 3: Dropoff is moderate distance from route (450m - 800m)
        if (proj != null && minDistToRoute <= 800.0) {
            res.setMode(DropoffMode.MEET_AT_HUB);
            res.setResolvedDropoffLat(proj.getLat());
            res.setResolvedDropoffLng(proj.getLng());
            res.setResolvedDropoffAddress("Corridor Transit Hub (" + candidate.getDropoffAddress() + ")");
            res.setWalkingDistanceMeters(minDistToRoute);
            res.setCumulativeDistanceMeters(cumDist);
            int walkMins = Math.max(1, (int) Math.round(minDistToRoute / 75.0));
            res.setDescriptionNotice(String.format("Drop %s at transit hub on route (walks %d mins)",
                    candidate.getPassengerName(), walkMins));
            return res;
        }

        // Condition 4: Dropoff is further away (> 800m) - Doorstep Detour
        res.setMode(DropoffMode.DOORSTEP_DETOUR);
        res.setResolvedDropoffLat(candidate.getDropoffLat());
        res.setResolvedDropoffLng(candidate.getDropoffLng());
        res.setResolvedDropoffAddress(candidate.getDropoffAddress());
        res.setWalkingDistanceMeters(0.0);
        res.setCumulativeDistanceMeters(cumDist);
        res.setDescriptionNotice("Doorstep dropoff with car detour");
        return res;
    }
}
"""

with open('backend/src/main/java/com/ekride/matching/service/SmartPickupResolver.java', 'w') as f:
    f.write(smart_pickup_content)

print("SmartPickupResolver updated.")
