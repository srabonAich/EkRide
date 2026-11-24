class Booking {
  final int id;
  final int rideId;
  final int passengerId;
  final String passengerName;
  final int seatsBooked;
  final double pickupLat;
  final double pickupLng;
  final String pickupAddress;
  final double dropoffLat;
  final double dropoffLng;
  final String dropoffAddress;
  final String status;
  final double individualFare;
  final double savings;
  final String createdAt;

  Booking({
    required this.id,
    required this.rideId,
    required this.passengerId,
    required this.passengerName,
    required this.seatsBooked,
    required this.pickupLat,
    required this.pickupLng,
    required this.pickupAddress,
    required this.dropoffLat,
    required this.dropoffLng,
    required this.dropoffAddress,
    required this.status,
    required this.individualFare,
    required this.savings,
    required this.createdAt,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'] ?? 0,
      rideId: json['rideId'] ?? 0,
      passengerId: json['passengerId'] ?? 0,
      passengerName: json['passengerName'] ?? 'Passenger',
      seatsBooked: json['seatsBooked'] ?? 1,
      pickupLat: (json['pickupLat'] as num).toDouble(),
      pickupLng: (json['pickupLng'] as num).toDouble(),
      pickupAddress: json['pickupAddress'] ?? '',
      dropoffLat: (json['dropoffLat'] as num).toDouble(),
      dropoffLng: (json['dropoffLng'] as num).toDouble(),
      dropoffAddress: json['dropoffAddress'] ?? '',
      status: json['status'] ?? 'PENDING',
      individualFare: (json['individualFare'] as num).toDouble(),
      savings: (json['savings'] as num).toDouble(),
      createdAt: json['createdAt'] ?? '',
    );
  }
}
