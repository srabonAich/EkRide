class CandidatePassenger {
  final int rideId;
  final int passengerId;
  final String passengerName;
  final String university;
  final double rating;
  final double pickupLat;
  final double pickupLng;
  final String pickupAddress;
  final double dropoffLat;
  final double dropoffLng;
  final String dropoffAddress;
  final double pickupDistanceMeters;
  final double dropoffDistanceMeters;
  final int availableSeats;

  CandidatePassenger({
    required this.rideId,
    required this.passengerId,
    required this.passengerName,
    required this.university,
    required this.rating,
    required this.pickupLat,
    required this.pickupLng,
    required this.pickupAddress,
    required this.dropoffLat,
    required this.dropoffLng,
    required this.dropoffAddress,
    required this.pickupDistanceMeters,
    required this.dropoffDistanceMeters,
    required this.availableSeats,
  });

  factory CandidatePassenger.fromJson(Map<String, dynamic> json) {
    return CandidatePassenger(
      rideId: json['rideId'] ?? 0,
      passengerId: json['passengerId'] ?? 0,
      passengerName: json['passengerName'] ?? 'Student Peer',
      university: json['university'] ?? 'Campus',
      rating: (json['rating'] is num) ? (json['rating'] as num).toDouble() : 5.0,
      pickupLat: (json['pickupLat'] as num).toDouble(),
      pickupLng: (json['pickupLng'] as num).toDouble(),
      pickupAddress: json['pickupAddress'] ?? '',
      dropoffLat: (json['dropoffLat'] as num).toDouble(),
      dropoffLng: (json['dropoffLng'] as num).toDouble(),
      dropoffAddress: json['dropoffAddress'] ?? '',
      pickupDistanceMeters: (json['pickupDistanceMeters'] as num?)?.toDouble() ?? 0.0,
      dropoffDistanceMeters: (json['dropoffDistanceMeters'] as num?)?.toDouble() ?? 0.0,
      availableSeats: json['availableSeats'] ?? 1,
    );
  }
}
