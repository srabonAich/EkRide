import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ekride_frontend/core/stop_location_resolver.dart';
import 'package:ekride_frontend/models/stop.dart';

class PolylineCoord {
  final double lat;
  final double lng;

  const PolylineCoord(this.lat, this.lng);

  @override
  String toString() => '($lat, $lng)';
}

class PolylineUtils {
  /// Decodes Google-encoded polyline string into coordinates
  static List<PolylineCoord> decodePolyline(String? encoded) {
    if (encoded == null || encoded.isEmpty) return const [];

    final pts = <PolylineCoord>[];
    int index = 0;
    final len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? -(result >> 1) - 1 : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? -(result >> 1) - 1 : (result >> 1));
      lng += dlng;

      final double pLat = lat / 1E5;
      final double pLng = lng / 1E5;
      if (pLat >= -90 && pLat <= 90 && pLng >= -180 && pLng <= 180) {
        pts.add(PolylineCoord(pLat, pLng));
      }
    }
    return pts;
  }

  /// Calculates bearing in degrees between two coordinates
  static double calculateBearing(double lat1, double lng1, double lat2, double lng2) {
    double dLng = (lng2 - lng1) * (pi / 180.0);
    double phi1 = lat1 * (pi / 180.0);
    double phi2 = lat2 * (pi / 180.0);
    double y = sin(dLng) * cos(phi2);
    double x = cos(phi1) * sin(phi2) - sin(phi1) * cos(phi2) * cos(dLng);
    double bearing = atan2(y, x) * (180.0 / pi);
    return (bearing + 360.0) % 360.0;
  }

  /// Calculates Haversine distance in meters
  static double distanceMeters(double lat1, double lng1, double lat2, double lng2) {
    const R = 6371000.0;
    double dLat = (lat2 - lat1) * (pi / 180.0);
    double dLng = (lng2 - lng1) * (pi / 180.0);
    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * (pi / 180.0)) * cos(lat2 * (pi / 180.0)) *
        sin(dLng / 2) * sin(dLng / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  /// Smooths and sub-samples a polyline path with maxStepMeters spacing
  /// so that tracking animation moves along roads smoothly without jerky teleports
  static List<PolylineCoord> interpolatePath(List<PolylineCoord> points, {double maxStepMeters = 30.0}) {
    if (points.length < 2) return points;

    final result = <PolylineCoord>[points.first];

    for (int i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];
      final dist = distanceMeters(p1.lat, p1.lng, p2.lat, p2.lng);

      if (dist > maxStepMeters) {
        int steps = (dist / maxStepMeters).ceil();
        for (int s = 1; s < steps; s++) {
          double fraction = s / steps.toDouble();
          double iLat = p1.lat + fraction * (p2.lat - p1.lat);
          double iLng = p1.lng + fraction * (p2.lng - p1.lng);
          result.add(PolylineCoord(iLat, iLng));
        }
      }
      result.add(p2);
    }

    return result;
  }

  /// Generates a cross-platform Google Maps Universal Directions URL
  /// with origin, all intermediate waypoints (Start -> A -> B -> C -> D),
  /// perfectly matching EkRide's unified pin resolver 100%.
  static Uri buildGoogleMapsDirectionsUri({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
    List<RouteStop>? stops,
  }) {
    if (stops != null && stops.isNotEmpty) {
      final pins = StopLocationResolver.resolveGoogleMapsPins(
        originLat: originLat,
        originLng: originLng,
        originAddress: '',
        destLat: destLat,
        destLng: destLng,
        destAddress: '',
        stops: stops,
        isBn: false,
      );

      final startCoord = pins.first.coordinate;
      final endCoord = pins.last.coordinate;
      final intermediatePins = pins.where((p) => !p.isStart && !p.isFinalDest).toList();
      final waypoints = intermediatePins.map((p) => '${p.coordinate.latitude},${p.coordinate.longitude}').join('|');

      final queryParams = <String, String>{
        'api': '1',
        'origin': '${startCoord.latitude},${startCoord.longitude}',
        'destination': '${endCoord.latitude},${endCoord.longitude}',
        'travelmode': 'driving',
      };

      if (waypoints.isNotEmpty) {
        queryParams['waypoints'] = waypoints;
      }

      return Uri.https('www.google.com', '/maps/dir/', queryParams);
    }

    final queryParams = <String, String>{
      'api': '1',
      'origin': '$originLat,$originLng',
      'destination': '$destLat,$destLng',
      'travelmode': 'driving',
    };

    return Uri.https('www.google.com', '/maps/dir/', queryParams);
  }

  /// Launches Google Maps website or native app with multi-stop directions
  static Future<bool> launchGoogleMapsDirections({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
    List<RouteStop>? stops,
  }) async {
    final uri = buildGoogleMapsDirectionsUri(
      originLat: originLat,
      originLng: originLng,
      destLat: destLat,
      destLng: destLng,
      stops: stops,
    );

    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication, webOnlyWindowName: '_blank');
      if (launched) return true;
      return await launchUrl(uri, webOnlyWindowName: '_blank');
    } catch (e) {
      debugPrint('Google Maps launch failed: $e');
      try {
        return await launchUrl(uri, webOnlyWindowName: '_blank');
      } catch (_) {
        return false;
      }
    }
  }
}
