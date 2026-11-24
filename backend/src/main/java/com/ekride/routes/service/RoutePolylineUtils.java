package com.ekride.routes.service;

import java.util.ArrayList;
import java.util.List;

public class RoutePolylineUtils {

    public static class RouteProjection {
        private final double lat;
        private final double lng;
        private final double distanceToRouteMeters;
        private final double cumulativeDistanceMeters;
        private final double segmentBearingDegrees;
        private final int segmentIndex;

        public RouteProjection(double lat, double lng, double distanceToRouteMeters,
                               double cumulativeDistanceMeters, double segmentBearingDegrees, int segmentIndex) {
            this.lat = lat;
            this.lng = lng;
            this.distanceToRouteMeters = distanceToRouteMeters;
            this.cumulativeDistanceMeters = cumulativeDistanceMeters;
            this.segmentBearingDegrees = segmentBearingDegrees;
            this.segmentIndex = segmentIndex;
        }

        public double getLat() { return lat; }
        public double getLng() { return lng; }
        public double getDistanceToRouteMeters() { return distanceToRouteMeters; }
        public double getCumulativeDistanceMeters() { return cumulativeDistanceMeters; }
        public double getSegmentBearingDegrees() { return segmentBearingDegrees; }
        public int getSegmentIndex() { return segmentIndex; }
    }

    public static String encode(List<double[]> points) {
        StringBuilder result = new StringBuilder();
        long lastLat = 0;
        long lastLng = 0;

        for (double[] point : points) {
            long lat = Math.round(point[0] * 1e5);
            long lng = Math.round(point[1] * 1e5);

            long dLat = lat - lastLat;
            long dLng = lng - lastLng;

            encodeValue(dLat, result);
            encodeValue(dLng, result);

            lastLat = lat;
            lastLng = lng;
        }

        return result.toString();
    }

    private static void encodeValue(long value, StringBuilder result) {
        long sValue = value < 0 ? ~(value << 1) : (value << 1);
        while (sValue >= 0x20) {
            result.append((char) ((int) ((0x20 | (sValue & 0x1f)) + 63)));
            sValue >>= 5;
        }
        result.append((char) ((int) (sValue + 63)));
    }

    public static List<double[]> decode(String encoded) {
        List<double[]> poly = new ArrayList<>();
        int index = 0, len = encoded.length();
        int lat = 0, lng = 0;

        while (index < len) {
            int b, shift = 0, result = 0;
            do {
                b = encoded.charAt(index++) - 63;
                result |= (b & 0x1f) << shift;
                shift += 5;
            } while (b >= 0x20);
            int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
            lat += dlat;

            shift = 0;
            result = 0;
            do {
                b = encoded.charAt(index++) - 63;
                result |= (b & 0x1f) << shift;
                shift += 5;
            } while (b >= 0x20);
            int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
            lng += dlng;

            poly.add(new double[]{((double) lat / 1E5), ((double) lng / 1E5)});
        }

        return poly;
    }

    public static double haversineDistanceMeters(double lat1, double lon1, double lat2, double lon2) {
        final int R = 6371000; // Radius of the earth in meters
        double latDistance = Math.toRadians(lat2 - lat1);
        double lonDistance = Math.toRadians(lon2 - lon1);
        double a = Math.sin(latDistance / 2) * Math.sin(latDistance / 2)
                + Math.cos(Math.toRadians(lat1)) * Math.cos(Math.toRadians(lat2))
                * Math.sin(lonDistance / 2) * Math.sin(lonDistance / 2);
        double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
        return R * c;
    }

    public static double calculateBearing(double lat1, double lng1, double lat2, double lng2) {
        double dLng = Math.toRadians(lng2 - lng1);
        double phi1 = Math.toRadians(lat1);
        double phi2 = Math.toRadians(lat2);
        double y = Math.sin(dLng) * Math.cos(phi2);
        double x = Math.cos(phi1) * Math.sin(phi2) - Math.sin(phi1) * Math.cos(phi2) * Math.cos(dLng);
        double bearing = Math.toDegrees(Math.atan2(y, x));
        return (bearing + 360.0) % 360.0;
    }

    public static double angleDifference(double b1, double b2) {
        double diff = Math.abs(b1 - b2) % 360.0;
        return diff > 180.0 ? 360.0 - diff : diff;
    }

    /**
     * For divided multi-lane avenues with physical medians (e.g. Mirpur Road, Airport Road, Kazi Nazrul Islam Ave),
     * aligns coordinate to the curbside of the carriageway traveling in the vehicle forward approach direction,
     * preventing crossing central concrete dividers or incurring U-turn loops.
     */
    public static double[] alignToForwardCarriageway(double lat, double lng, double approachBearingDegrees) {
        double b = (approachBearingDegrees + 360.0) % 360.0;
        double offset = 0.00012; // ~13 meters lane offset from center median
        
        if (b >= 315.0 || b < 45.0) {
            // Heading North: shift to West carriageway
            return new double[]{lat, lng - offset};
        } else if (b >= 135.0 && b < 225.0) {
            // Heading South: shift to East carriageway
            return new double[]{lat, lng + offset};
        } else if (b >= 45.0 && b < 135.0) {
            // Heading East: shift to North carriageway
            return new double[]{lat + offset, lng};
        } else {
            // Heading West: shift to South carriageway
            return new double[]{lat - offset, lng};
        }
    }

    /**
     * Dynamically projects any coordinate orthogonally onto the active continuous driving segments.
     * Enforces a physical setback away from junction vertices to prevent landing in intersection turns or median barriers.
     */
    public static RouteProjection projectPointOntoRoute(double pLat, double pLng, List<double[]> routePoints, double minSetbackMeters) {
        if (routePoints == null || routePoints.isEmpty()) {
            return null;
        }
        if (routePoints.size() == 1) {
            double[] p = routePoints.get(0);
            double dist = haversineDistanceMeters(pLat, pLng, p[0], p[1]);
            return new RouteProjection(p[0], p[1], dist, 0.0, 0.0, 0);
        }

        int n = routePoints.size();
        double[] segCumDist = new double[n];
        segCumDist[0] = 0.0;
        double[] segBearings = new double[n - 1];
        double[] segLengths = new double[n - 1];

        for (int i = 0; i < n - 1; i++) {
            double[] A = routePoints.get(i);
            double[] B = routePoints.get(i + 1);
            double len = haversineDistanceMeters(A[0], A[1], B[0], B[1]);
            segLengths[i] = len;
            segCumDist[i + 1] = segCumDist[i] + len;
            segBearings[i] = calculateBearing(A[0], A[1], B[0], B[1]);
        }

        // Identify vertex turn angles to establish intersection buffers
        boolean[] isTurnVertex = new boolean[n];
        for (int i = 1; i < n - 1; i++) {
            double turnAngle = angleDifference(segBearings[i - 1], segBearings[i]);
            if (turnAngle >= 25.0) {
                isTurnVertex[i] = true;
            }
        }

        RouteProjection bestProjection = null;
        double minEffectiveScore = Double.MAX_VALUE;

        for (int i = 0; i < n - 1; i++) {
            double[] A = routePoints.get(i);
            double[] B = routePoints.get(i + 1);
            double segLen = segLengths[i];
            if (segLen < 1.0) {
                continue;
            }

            // Enforce intersection safety setbacks: minimum 40m away from any corner/turn apex
            double startSetback = isTurnVertex[i] ? Math.max(minSetbackMeters, 40.0) : minSetbackMeters;
            double endSetback = isTurnVertex[i + 1] ? Math.max(minSetbackMeters, 40.0) : minSetbackMeters;

            // If a segment is an acute junction transition (< 30m connecting to a turn), skip it
            if (segLen < 30.0 && (isTurnVertex[i] || isTurnVertex[i + 1])) {
                continue;
            }

            double midLatRad = Math.toRadians(A[0]);
            double vx = (B[1] - A[1]) * Math.cos(midLatRad) * 111320.0;
            double vy = (B[0] - A[0]) * 111320.0;
            double ux = (pLng - A[1]) * Math.cos(midLatRad) * 111320.0;
            double uy = (pLat - A[0]) * 111320.0;

            double vSq = vx * vx + vy * vy;
            if (vSq <= 0.0) {
                continue;
            }

            double t = (ux * vx + uy * vy) / vSq;

            double tMin = segLen > 0 ? Math.min(0.40, startSetback / segLen) : 0.0;
            double tMax = segLen > 0 ? Math.max(0.60, 1.0 - (endSetback / segLen)) : 1.0;
            if (tMin > tMax) {
                tMin = 0.50;
                tMax = 0.50;
            }
            double tClamped = Math.max(tMin, Math.min(t, tMax));

            double projLat = A[0] + tClamped * (B[0] - A[0]);
            double projLng = A[1] + tClamped * (B[1] - A[1]);
            double dist = haversineDistanceMeters(pLat, pLng, projLat, projLng);

            // Add out-of-bounds penalty to prefer segments that run laterally alongside the passenger
            double penalty = 0.0;
            if (t < 0.0) {
                penalty = (-t) * segLen * 0.4;
            } else if (t > 1.0) {
                penalty = (t - 1.0) * segLen * 0.4;
            }

            double effectiveScore = dist + penalty;
            if (effectiveScore < minEffectiveScore) {
                minEffectiveScore = effectiveScore;
                double bearing = segBearings[i];
                double cumDist = segCumDist[i] + (tClamped * segLen);
                bestProjection = new RouteProjection(projLat, projLng, dist, cumDist, bearing, i);
            }
        }

        // Fallback if all segments were skipped due to strict setbacks
        if (bestProjection == null) {
            for (int i = 0; i < n - 1; i++) {
                double[] A = routePoints.get(i);
                double[] B = routePoints.get(i + 1);
                double segLen = segLengths[i];
                if (segLen < 1.0) continue;
                double midLat = (A[0] + B[0]) / 2.0;
                double midLng = (A[1] + B[1]) / 2.0;
                double dist = haversineDistanceMeters(pLat, pLng, midLat, midLng);
                if (dist < minEffectiveScore) {
                    minEffectiveScore = dist;
                    bestProjection = new RouteProjection(midLat, midLng, dist, segCumDist[i] + (0.5 * segLen), segBearings[i], i);
                }
            }
        }

        return bestProjection;
    }

    /**
     * Finds the cumulative distance along the polyline to the projection of a given point.
     */
    public static double findCumulativeDistanceAlongRoute(double lat, double lng, List<double[]> routePoints) {
        RouteProjection proj = projectPointOntoRoute(lat, lng, routePoints, 10.0);
        return proj != null ? proj.getCumulativeDistanceMeters() : 0.0;
    }
}
