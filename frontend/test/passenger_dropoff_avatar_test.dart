import 'package:flutter_test/flutter_test.dart';
import 'package:ekride_frontend/models/candidate.dart';
import 'package:ekride_frontend/core/stop_location_resolver.dart';

void main() {
  test('Candidate passenger dropoff coordinates and details verify correctly', () {
    final candidate = CandidatePassenger(
      rideId: 101,
      passengerId: 1,
      passengerName: 'Nusrat Jahan',
      university: 'University of Dhaka',
      rating: 4.9,
      pickupLat: 23.73315,
      pickupLng: 90.39605,
      pickupAddress: 'Campus Departure Gate (Central Library)',
      dropoffLat: 23.78,
      dropoffLng: 90.403,
      dropoffAddress: 'Mohakhali Transit Hub',
      pickupDistanceMeters: 50,
      dropoffDistanceMeters: 100,
      availableSeats: 1,
    );

    // Verify distinct pickup vs dropoff locations
    expect(candidate.pickupLat != candidate.dropoffLat, true);
    expect(candidate.pickupLng != candidate.dropoffLng, true);
    expect(candidate.pickupAddress, contains('Campus'));
    expect(candidate.dropoffAddress, contains('Mohakhali'));

    // Verify distance from pickup to dropoff is realistic Dhaka corridor travel (> 4 km)
    final distance = StopLocationResolver.haversineMeters(
      candidate.pickupLat,
      candidate.pickupLng,
      candidate.dropoffLat,
      candidate.dropoffLng,
    );
    expect(distance > 4000, true);
  });
}
