package com.ekride.matching;

import com.ekride.routes.service.RoutePolylineUtils;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

class RoutePolylineUtilsTest {

    @Test
    @DisplayName("Haversine formula calculates reasonable distance between Dhaka coordinates")
    void testHaversineDistance() {
        // Dhaka TSC to Curzon Hall (~1.2 km)
        double dist = RoutePolylineUtils.haversineDistanceMeters(23.7328, 90.3957, 23.7262, 90.4013);
        assertTrue(dist > 900 && dist < 1500, "Distance should be approx 1.1-1.3km: " + dist);
    }

    @Test
    @DisplayName("Polyline encoding and decoding round-trip preserves points")
    void testPolylineEncodeDecode() {
        List<double[]> original = List.of(
                new double[]{23.7328, 90.3957},
                new double[]{23.7465, 90.3760},
                new double[]{23.7937, 90.4066}
        );

        String encoded = RoutePolylineUtils.encode(original);
        assertNotNull(encoded);
        assertFalse(encoded.isEmpty());

        List<double[]> decoded = RoutePolylineUtils.decode(encoded);
        assertEquals(original.size(), decoded.size());

        for (int i = 0; i < original.size(); i++) {
            assertEquals(original.get(i)[0], decoded.get(i)[0], 0.0001);
            assertEquals(original.get(i)[1], decoded.get(i)[1], 0.0001);
        }
    }

    @Test
    @DisplayName("Orthogonal projection snaps off-road passenger cleanly to corridor with setback")
    void testProjectPointOntoRoute() {
        // Straight Northbound corridor along 90.3950 from 23.7300 to 23.7400 (~1.1 km)
        List<double[]> route = List.of(
                new double[]{23.7300, 90.3950},
                new double[]{23.7400, 90.3950}
        );

        // Passenger is 100m East of the road at 23.7350, 90.3960
        RoutePolylineUtils.RouteProjection proj = RoutePolylineUtils.projectPointOntoRoute(
                23.7350, 90.3960, route, 35.0);

        assertNotNull(proj);
        // Snapped point should be directly on the road longitude 90.3950
        assertEquals(90.3950, proj.getLng(), 0.0001);
        assertEquals(23.7350, proj.getLat(), 0.0005);
        assertTrue(proj.getDistanceToRouteMeters() > 90 && proj.getDistanceToRouteMeters() < 120);
        // Heading North should be close to 0 / 360 degrees
        assertEquals(0.0, proj.getSegmentBearingDegrees(), 1.0);
    }

    @Test
    @DisplayName("Bearing calculation matches standard cardinal headings")
    void testBearingCalculation() {
        // True North
        double bNorth = RoutePolylineUtils.calculateBearing(23.7000, 90.3000, 23.7100, 90.3000);
        assertEquals(0.0, bNorth, 0.5);

        // True East
        double bEast = RoutePolylineUtils.calculateBearing(23.7000, 90.3000, 23.7000, 90.3100);
        assertEquals(90.0, bEast, 0.5);

        // True South
        double bSouth = RoutePolylineUtils.calculateBearing(23.7100, 90.3000, 23.7000, 90.3000);
        assertEquals(180.0, bSouth, 0.5);
    }

    @Test
    @DisplayName("Angle difference accurately computes minimal angular turn across 0/360 wrap")
    void testAngleDifference() {
        assertEquals(30.0, RoutePolylineUtils.angleDifference(10.0, 40.0), 0.01);
        assertEquals(20.0, RoutePolylineUtils.angleDifference(350.0, 10.0), 0.01);
        assertEquals(90.0, RoutePolylineUtils.angleDifference(0.0, 90.0), 0.01);
        assertEquals(180.0, RoutePolylineUtils.angleDifference(0.0, 180.0), 0.01);
    }

    @Test
    @DisplayName("Forward carriageway alignment correctly shifts to travel lane on divided road")
    void testAlignToForwardCarriageway() {
        // Vehicle traveling Northbound (0 deg) should be shifted West (smaller longitude)
        double[] northAligned = RoutePolylineUtils.alignToForwardCarriageway(23.7450, 90.3820, 0.0);
        assertTrue(northAligned[1] < 90.3820, "Northbound lane must be West of center median");

        // Vehicle traveling Southbound (180 deg) should be shifted East (larger longitude)
        double[] southAligned = RoutePolylineUtils.alignToForwardCarriageway(23.7450, 90.3820, 180.0);
        assertTrue(southAligned[1] > 90.3820, "Southbound lane must be East of center median");
    }
}
