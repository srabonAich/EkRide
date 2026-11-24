import 'package:flutter_test/flutter_test.dart';
import 'package:ekride_frontend/core/stop_location_resolver.dart';
import 'package:ekride_frontend/core/polyline_utils.dart';
import 'package:ekride_frontend/models/stop.dart';

void main() {
  test('Google Maps Waypoint Pins match Google Maps navigation 100%', () {
    const originLat = 23.7328;
    const originLng = 90.3957;
    const originAddress = 'Raju Memorial Sculpture, University of Dhaka';

    const destLat = 23.7937;
    const destLng = 90.4066;
    const destAddress = 'Banani Road 11';

    final stops = [
      RouteStop(order: 1, type: 'ORIGIN', lat: 23.7328, lng: 90.3957, address: 'Raju Memorial Sculpture, University of Dhaka'),
      RouteStop(order: 2, type: 'PICKUP', passengerName: 'Nusrat Jahan', lat: 23.7328, lng: 90.3957, address: 'Raju Memorial Sculpture, University of Dhaka (Board Together)'),
      RouteStop(order: 3, type: 'PICKUP', passengerName: 'Tanvir Hasan', lat: 23.73712, lng: 90.39563, address: 'Shahbagh Curbside (National Museum Gate)'),
      RouteStop(order: 4, type: 'PICKUP', passengerName: 'Mehjabin Chowdhury', lat: 23.75862, lng: 90.3899, address: 'Farmgate / Indira Road Curbside'),
      RouteStop(order: 5, type: 'DROPOFF', passengerName: 'Nusrat Jahan', lat: 23.78064, lng: 90.39860, address: 'Corridor Transit Hub (Mohakhali Transit Hub)'),
      RouteStop(order: 6, type: 'DROPOFF', passengerName: 'Tanvir Hasan', lat: 23.7937, lng: 90.4066, address: 'Banani Road 11 (Alight Together)'),
      RouteStop(order: 7, type: 'DROPOFF', passengerName: 'Mehjabin Chowdhury', lat: 23.7937, lng: 90.4066, address: 'Banani Road 11 (Alight Together)'),
      RouteStop(order: 8, type: 'DESTINATION', lat: 23.7937, lng: 90.4066, address: 'Banani Road 11'),
    ];

    final pins = StopLocationResolver.resolveGoogleMapsPins(
      originLat: originLat,
      originLng: originLng,
      originAddress: originAddress,
      destLat: destLat,
      destLng: destLng,
      destAddress: destAddress,
      stops: stops,
      isBn: false,
    );

    // 1. Must have exactly 5 pins: Start, A, B, C, D (ZERO phantom pins E, F, G!)
    expect(pins.length, 5);
    expect(pins[0].letter, 'Start');
    expect(pins[1].letter, 'A');
    expect(pins[2].letter, 'B');
    expect(pins[3].letter, 'C');
    expect(pins[4].letter, 'D');

    // 2. Exact Google Maps landmark strings
    expect(pins[0].exactLandmark, contains('Raju Memorial Sculpture'));
    expect(pins[1].exactLandmark, contains('mdripon, P9PW+R75'));
    expect(pins[2].exactLandmark, contains('ফার্মগেট মোড় Farmgate'));
    expect(pins[3].exactLandmark, contains('47 Mohakhali Flyover'));
    expect(pins[4].exactLandmark, contains('company Gold Bell Corporation'));

    // 3. Google Maps directions URL has exactly 3 intermediate waypoints
    final uri = PolylineUtils.buildGoogleMapsDirectionsUri(
      originLat: originLat,
      originLng: originLng,
      destLat: destLat,
      destLng: destLng,
      stops: stops,
    );

    final waypointsParam = uri.queryParameters['waypoints']!;
    final waypoints = waypointsParam.split('|');
    expect(waypoints.length, 3); // Shahbagh (A), Farmgate (B), Mohakhali (C)
  });

  test('Quad Pool with peer behind origin and peer ahead of destination sequences forward correctly', () {
    const originLat = 23.7328;
    const originLng = 90.3957;
    const originAddress = 'TSC, University of Dhaka';

    const destLat = 23.7937;
    const destLng = 90.4066;
    const destAddress = 'Banani Road 11';

    // 8 Stops returned in forward driving order by backend RouteInsertionEngine
    final stops = [
      RouteStop(order: 1, type: 'PICKUP', passengerName: 'Rohan Farooq', lat: 23.7220, lng: 90.4000, address: 'Chankharpul'),
      RouteStop(order: 2, type: 'ORIGIN', passengerName: 'Abrar Rahman', lat: 23.7328, lng: 90.3957, address: 'TSC, University of Dhaka'),
      RouteStop(order: 3, type: 'PICKUP', passengerName: 'Nusrat Jahan', lat: 23.7328, lng: 90.3957, address: 'TSC, University of Dhaka'),
      RouteStop(order: 4, type: 'PICKUP', passengerName: 'Tanvir Hasan', lat: 23.7371, lng: 90.3956, address: 'Shahbagh Curbside'),
      RouteStop(order: 5, type: 'DROPOFF', passengerName: 'Tanvir Hasan', lat: 23.7806, lng: 90.3986, address: 'Mohakhali Flyover'),
      RouteStop(order: 6, type: 'DESTINATION', passengerName: 'Abrar Rahman', lat: 23.7937, lng: 90.4066, address: 'Banani Road 11'),
      RouteStop(order: 7, type: 'DROPOFF', passengerName: 'Nusrat Jahan', lat: 23.7937, lng: 90.4066, address: 'Banani Road 11'),
      RouteStop(order: 8, type: 'DROPOFF', passengerName: 'Rohan Farooq', lat: 23.8200, lng: 90.4200, address: 'Kuril Flyover'),
    ];

    final pins = StopLocationResolver.resolveGoogleMapsPins(
      originLat: originLat,
      originLng: originLng,
      originAddress: originAddress,
      destLat: destLat,
      destLng: destLng,
      destAddress: destAddress,
      stops: stops,
      isBn: true,
    );

    // 6 Clustered pins: Start (Rohan at Chankharpul), A (User & Nusrat at TSC), B (Tanvir Shahbagh), C (Tanvir Mohakhali), D (User & Nusrat Banani), E (Rohan Kuril)
    expect(pins.length, 6);

    expect(pins[0].letter, 'Start');
    expect(pins[0].isStart, true);
    expect(pins[0].roleText, contains('Rohan'));

    expect(pins[1].letter, 'A');
    expect(pins[1].roleText, contains('আপনার পিকআপ'));
    expect(pins[1].roleText, contains('Nusrat'));

    expect(pins[2].letter, 'B');
    expect(pins[2].roleText, contains('Tanvir'));

    expect(pins[3].letter, 'C');
    expect(pins[3].roleText, contains('Tanvir'));

    expect(pins[4].letter, 'D');
    expect(pins[4].roleText, contains('আপনার শেষ গন্তব্য'));
    expect(pins[4].roleText, contains('Nusrat'));

    expect(pins[5].letter, 'E');
    expect(pins[5].isFinalDest, true);
    expect(pins[5].roleText, contains('Rohan'));

    // Google Maps directions URI
    final uri = PolylineUtils.buildGoogleMapsDirectionsUri(
      originLat: originLat,
      originLng: originLng,
      destLat: destLat,
      destLng: destLng,
      stops: stops,
    );

    expect(uri.queryParameters['origin'], '23.722,90.4'); // Starts at Chankharpul
    expect(uri.queryParameters['destination'], '23.82,90.42'); // Ends at Kuril
    final waypoints = uri.queryParameters['waypoints']!.split('|');
    expect(waypoints.length, 4); // TSC (A), Shahbagh (B), Mohakhali (C), Banani 11 (D)
  });
}
