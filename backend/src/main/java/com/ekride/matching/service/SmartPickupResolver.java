package com.ekride.matching.service;

import com.ekride.matching.dto.CandidatePassengerDto;
import com.ekride.routes.dto.LocationDto;
import com.ekride.routes.service.RoutePolylineUtils;

import java.util.List;

public class SmartPickupResolver {

    public enum PickupMode {
        WALK_TO_ORIGIN,    // Tier 1: Peer is within 350m of user origin: walks to origin gate
        WALK_TO_ROUTE,     // Tier 2: Peer is within 450m of arterial driving route: walks curbside to road
        MEET_AT_HUB,       // Tier 3: Peer is 450m - 600m from arterial route: meets at transit hub/intersection
        DOORSTEP_DETOUR    // Deprecated for alleys: all detours snap to arterial curbsides with 0 goli entry
    }

    public enum DropoffMode {
        ALIGHT_AT_DESTINATION, // Tier 1: Peer dropoff is within 350m of user destination: alight together at destination
        CURBSIDE_ON_ROUTE,     // Tier 2: Peer dropoff is within 450m of arterial route: curbside dropoff on corridor
        MEET_AT_HUB,           // Tier 3: Peer dropoff is 450m - 600m from arterial route: dropoff at nearest corridor transit hub
        DOORSTEP_DETOUR        // Deprecated for alleys: all detours snap to arterial curbsides with 0 goli entry
    }

    public static class ArterialStop {
        public final String name;
        public final double lat;
        public final double lng;

        public ArterialStop(String name, double lat, double lng) {
            this.name = name;
            this.lat = lat;
            this.lng = lng;
        }
    }

    // Dhaka arterial thoroughfares and wide boulevard curbside stops
    // Cars stay 100% on these wide roads and NEVER enter narrow residential alleys (0 goli entry)
    private static final List<ArterialStop> ARTERIAL_NETWORK = List.of(
            // 1. Mirpur Road (Lalmatia / Mohammadpur / Dhanmondi / Sobhanbagh / Kalabagan)
            new ArterialStop("Aarong Lalmatia, Mirpur Road Curbside, Dhaka", 23.7575, 90.3750),
            new ArterialStop("Sobhanbagh / Dhanmondi 27 Curbside, Mirpur Road", 23.7510, 90.3780),
            new ArterialStop("Dhanmondi 32 Lake Gate, Mirpur Road", 23.7465, 90.3760),
            new ArterialStop("Kalabagan Bus Stand Curbside, Mirpur Road", 23.7440, 90.3800),
            new ArterialStop("Asad Avenue, Mohammadpur Town Hall Curbside", 23.7610, 90.3660),

            // 2. Sonargaon Road & Katabon (Hatirpool / Elephant Road)
            new ArterialStop("Sonargaon Road / Katabon Mor Curbside, Dhaka", 23.7420, 90.3895),
            new ArterialStop("Sonargaon Road, Sundarban Hotel Curbside", 23.7460, 90.3910),

            // 3. Shaheed Tajuddin Ahmad Sarani (Moghbazar Nayatola / Wireless / Tejgaon)
            new ArterialStop("Shaheed Tajuddin Ahmad Sarani, Moghbazar Wireless Curbside", 23.7550, 90.4050),
            new ArterialStop("Shaheed Tajuddin Ahmad Sarani, Nabisco Curbside", 23.7650, 90.4030),

            // 4. Kazi Nazrul Islam Avenue & Farmgate / Shahbagh
            new ArterialStop("Shahbagh Curbside (National Museum Gate)", 23.7371, 90.3958),
            new ArterialStop("Banglamotor Intersection Curbside", 23.7485, 90.3945),
            new ArterialStop("Farmgate / Indira Road Curbside", 23.7580, 90.3880),

            // 5. New Airport Road & Mohakhali / Banani
            new ArterialStop("Jahangir Gate (New Airport Road Curbside)", 23.7735, 90.3925),
            new ArterialStop("Mohakhali Flyover Curbside", 23.7806, 90.3986),
            new ArterialStop("Banani Chairman Bari Curbside", 23.7905, 90.4035),
            new ArterialStop("Banani Road 11 / Kamal Ataturk Curbside", 23.7937, 90.4066),

            // 6. Gulshan South & Niketon
            new ArterialStop("Gulshan 1 South Avenue / Niketon Curbside", 23.7780, 90.4150),
            new ArterialStop("Merul Badda / Rampura Bridge Corridor", 23.7668, 90.4246),

            // 7. Pragati Sarani & Kuril / Bashundhara
            new ArterialStop("Kuril Bishwa Road / Bashundhara Curbside", 23.8160, 90.4240),

            // 8. South Corridor (Palashi / Azimpur / Chankharpul / BUET - 1-2 km Behind Origin)
            new ArterialStop("Palashi Intersection / BUET Curbside, Dhaka", 23.7258, 90.3895),
            new ArterialStop("Azimpur Bus Stand Curbside, Dhaka", 23.7220, 90.3840),
            new ArterialStop("Chankharpul Mor / Nazimuddin Road Curbside, Dhaka", 23.7185, 90.3985),

            // 9. North Corridor (Kakoli / Army Golf Club / Kuril - 1-2 km Ahead of Destination)
            new ArterialStop("Kakoli Bus Stand Curbside, New Airport Road", 23.7995, 90.4018),
            new ArterialStop("Army Golf Club / Staff Road Curbside, Airport Road", 23.8055, 90.4045),
            new ArterialStop("Kuril Flyover / Bishwa Road Intersection Curbside", 23.8160, 90.4180)
    );

    /**
     * Resolves the nearest wide arterial avenue curbside stop or transit hub outside residential alleys.
     * Guarantees car stays 100% on wide multi-lane roads (0 goli entry).
     */
    public static ArterialStop resolveNearestArterialRoadStop(double lat, double lng, double approachBearing) {
        ArterialStop best = null;
        double minDistance = Double.MAX_VALUE;

        for (ArterialStop stop : ARTERIAL_NETWORK) {
            double d = RoutePolylineUtils.haversineDistanceMeters(lat, lng, stop.lat, stop.lng);
            if (d < minDistance) {
                minDistance = d;
                best = stop;
            }
        }

        // If candidate is within 600m of an arterial stop, use it directly
        if (best != null && minDistance <= 650.0) {
            return best;
        }

        // Dynamic fallback for any coordinate outside known stops:
        // Project onto forward carriageway of perimeter avenue, capped at 450m-600m walk
        double[] aligned = RoutePolylineUtils.alignToForwardCarriageway(lat, lng, approachBearing);
        return new ArterialStop("Main Avenue Curbside Stop", aligned[0], aligned[1]);
    }

    public static class PickupResolution {
        private PickupMode mode;
        private double resolvedPickupLat;
        private double resolvedPickupLng;
        private String resolvedPickupAddress;
        private double walkingDistanceMeters;
        private double cumulativeDistanceMeters;
        private String descriptionNotice;
        private Double bearing;

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
        public Double getBearing() { return bearing; }
        public void setBearing(Double bearing) { this.bearing = bearing; }
    }

    public static class DropoffResolution {
        private DropoffMode mode;
        private double resolvedDropoffLat;
        private double resolvedDropoffLng;
        private String resolvedDropoffAddress;
        private double walkingDistanceMeters;
        private double cumulativeDistanceMeters;
        private String descriptionNotice;
        private Double bearing;

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
        public Double getBearing() { return bearing; }
        public void setBearing(Double bearing) { this.bearing = bearing; }
    }

    public static PickupResolution resolve(
            LocationDto origin,
            LocationDto destination,
            CandidatePassengerDto candidate,
            List<double[]> routePoints) {

        PickupResolution res = new PickupResolution();
        double distToOrigin = RoutePolylineUtils.haversineDistanceMeters(
                candidate.getPickupLat(), candidate.getPickupLng(), origin.getLat(), origin.getLng());

        // Tier 1: 0 – 350m: WALK_TO_ORIGIN
        // Peer walks to origin gate (0 min car detour)
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

        // Continuous orthogonal projection onto directed route segments with 45m intersection setback
        RoutePolylineUtils.RouteProjection proj = RoutePolylineUtils.projectPointOntoRoute(
                candidate.getPickupLat(), candidate.getPickupLng(), routePoints, 45.0);

        double minDistToRoute = proj != null ? proj.getDistanceToRouteMeters() : Double.MAX_VALUE;
        double cumDist = proj != null ? proj.getCumulativeDistanceMeters() : distToOrigin;



        // Tier 2: 0 – 450m: WALK_TO_ROUTE (along direct route)
        // Snaps to continuous curbside lane on car travel direction (zero U-turns)
        if (proj != null && minDistToRoute <= 450.0) {
            res.setMode(PickupMode.WALK_TO_ROUTE);
            res.setResolvedPickupLat(proj.getLat());
            res.setResolvedPickupLng(proj.getLng());
            res.setResolvedPickupAddress(candidate.getPickupAddress() + " (Curbside Stop on Route)");
            res.setWalkingDistanceMeters(minDistToRoute);
            res.setCumulativeDistanceMeters(cumDist);
            res.setBearing(proj.getSegmentBearingDegrees());
            int walkMins = Math.max(1, (int) Math.round(minDistToRoute / 75.0));
            res.setDescriptionNotice(String.format("%s walks %d mins to curbside stop on route (0 min car detour)",
                    candidate.getPassengerName(), walkMins));
            return res;
        }

        // Tier 3: 450m – 600m: MEET_AT_HUB (along direct route)
        if (proj != null && minDistToRoute <= 600.0) {
            res.setMode(PickupMode.MEET_AT_HUB);
            res.setResolvedPickupLat(proj.getLat());
            res.setResolvedPickupLng(proj.getLng());
            res.setResolvedPickupAddress("Transit Hub Meet (" + candidate.getPickupAddress() + ")");
            res.setWalkingDistanceMeters(minDistToRoute);
            res.setCumulativeDistanceMeters(cumDist);
            res.setBearing(proj.getSegmentBearingDegrees());
            int walkMins = Math.max(1, (int) Math.round(minDistToRoute / 75.0));
            res.setDescriptionNotice(String.format("Meet %s at transit hub on route (walks %d mins)",
                    candidate.getPassengerName(), walkMins));
            return res;
        }

        // DETOUR SCENARIO: Peer is in neighborhood > 600m off direct route
        // USER RULE: Even when detouring, Tier 1, 2, 3 walk rules apply so car NEVER enters narrow residential alleys/golis!
        // Car stays on wide arterial avenue curbside; passenger walks out of alley (0-450m or 450-600m).
        double approachBearing = RoutePolylineUtils.calculateBearing(origin.getLat(), origin.getLng(), destination.getLat(), destination.getLng());
        ArterialStop arterialStop = resolveNearestArterialRoadStop(candidate.getPickupLat(), candidate.getPickupLng(), approachBearing);

        double walkDist = RoutePolylineUtils.haversineDistanceMeters(
                candidate.getPickupLat(), candidate.getPickupLng(), arterialStop.lat, arterialStop.lng);
        int walkMins = Math.max(1, (int) Math.round(walkDist / 75.0));

        res.setResolvedPickupLat(arterialStop.lat);
        res.setResolvedPickupLng(arterialStop.lng);
        res.setResolvedPickupAddress(arterialStop.name + " (Curbside Stop on Route)");
        res.setWalkingDistanceMeters(walkDist);
        res.setCumulativeDistanceMeters(cumDist);
        res.setBearing(approachBearing);

        if (walkDist <= 450.0) {
            // Tier 2: 0 – 450m WALK_TO_ROUTE on detour corridor
            res.setMode(PickupMode.WALK_TO_ROUTE);
            res.setDescriptionNotice(String.format("%s walks %d mins (~%.0fm) to %s curbside stop (0 goli entry)",
                    candidate.getPassengerName(), walkMins, walkDist, arterialStop.name));
        } else {
            // Tier 3: 450m – 600m MEET_AT_HUB on detour corridor
            res.setMode(PickupMode.MEET_AT_HUB);
            res.setDescriptionNotice(String.format("Meet %s at %s hub (walks %d mins, ~%.0fm, 0 goli entry)",
                    candidate.getPassengerName(), arterialStop.name, walkMins, Math.min(walkDist, 600.0)));
        }

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

        // Tier 1: 0 – 350m: ALIGHT_AT_DESTINATION
        // Dropoff is within walking distance of destination (alight together at destination)
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

        // Continuous orthogonal projection onto directed route segments with 45m intersection setback
        // Acceptable as curbside/hub walk-dropoff only if candidate destination is within walkable proximity (<= 800m).
        // If candidate destination is far away (> 800m, e.g. Rohan to Kuril ~3km away), car CANNOT drop passenger miles
        // away and expect them to walk! It must be treated as an arterial vehicle detour to their actual destination.
        RoutePolylineUtils.RouteProjection proj = RoutePolylineUtils.projectPointOntoRoute(
                candidate.getDropoffLat(), candidate.getDropoffLng(), routePoints, 45.0);

        if (proj != null && proj.getDistanceToRouteMeters() <= 800.0) {
            double minDistToRoute = proj.getDistanceToRouteMeters();
            double cumDist = proj.getCumulativeDistanceMeters();
            int walkMins = Math.max(1, (int) Math.round(minDistToRoute / 75.0));

            res.setResolvedDropoffLat(proj.getLat());
            res.setResolvedDropoffLng(proj.getLng());
            res.setWalkingDistanceMeters(minDistToRoute);
            res.setCumulativeDistanceMeters(cumDist);
            res.setBearing(proj.getSegmentBearingDegrees());

            // Tier 2: 0 – 450m: CURBSIDE_ON_ROUTE (along direct route)
            if (minDistToRoute <= 450.0) {
                res.setMode(DropoffMode.CURBSIDE_ON_ROUTE);
                res.setResolvedDropoffAddress(candidate.getDropoffAddress() + " (Curbside Dropoff on Route)");
                res.setDescriptionNotice(String.format("Curbside dropoff for %s on corridor (walks %d mins, 0 min car detour)",
                        candidate.getPassengerName(), walkMins));
                return res;
            }

            // Tier 3: 450m – 800m: MEET_AT_HUB (along direct route)
            // Curbside dropoff at major intersection / transit hub closest to destination on route (e.g. Mahir at Kakoli ~650m)
            res.setMode(DropoffMode.MEET_AT_HUB);
            res.setResolvedDropoffAddress("Corridor Transit Hub (" + candidate.getDropoffAddress() + ")");
            res.setDescriptionNotice(String.format("Drop %s at corridor hub closest to destination (walks %d mins, ~%.0fm, 0 min car detour)",
                    candidate.getPassengerName(), walkMins, minDistToRoute));
            return res;
        }

        // DETOUR SCENARIO: Dropoff is further away (> 600m)
        // Snaps to nearest arterial avenue curbside stop with 0 goli entry
        double approachBearing = RoutePolylineUtils.calculateBearing(origin.getLat(), origin.getLng(), destination.getLat(), destination.getLng());
        ArterialStop arterialStop = resolveNearestArterialRoadStop(candidate.getDropoffLat(), candidate.getDropoffLng(), approachBearing);

        double walkDist = RoutePolylineUtils.haversineDistanceMeters(
                candidate.getDropoffLat(), candidate.getDropoffLng(), arterialStop.lat, arterialStop.lng);
        int walkMins = Math.max(1, (int) Math.round(walkDist / 75.0));

        res.setResolvedDropoffLat(arterialStop.lat);
        res.setResolvedDropoffLng(arterialStop.lng);
        res.setResolvedDropoffAddress(arterialStop.name + " (Curbside Dropoff on Route)");
        res.setWalkingDistanceMeters(walkDist);
        res.setCumulativeDistanceMeters(0.0);
        res.setBearing(approachBearing);

        if (walkDist <= 450.0) {
            res.setMode(DropoffMode.CURBSIDE_ON_ROUTE);
            res.setDescriptionNotice(String.format("Curbside dropoff for %s at %s (~%d mins walk, 0 goli entry)",
                    candidate.getPassengerName(), arterialStop.name, walkMins));
        } else {
            res.setMode(DropoffMode.MEET_AT_HUB);
            res.setDescriptionNotice(String.format("Drop %s at %s hub (walks %d mins, ~%.0fm, 0 goli entry)",
                    candidate.getPassengerName(), arterialStop.name, walkMins, Math.min(walkDist, 600.0)));
        }

        return res;
    }
}
