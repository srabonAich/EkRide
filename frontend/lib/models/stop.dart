class RouteStop {
  final int order;
  final String type;
  final double lat;
  final double lng;
  final String address;
  final String? passengerName;

  RouteStop({
    required this.order,
    required this.type,
    required this.lat,
    required this.lng,
    required this.address,
    this.passengerName,
  });

  factory RouteStop.fromJson(Map<String, dynamic> json) {
    return RouteStop(
      order: json['order'] ?? 0,
      type: json['type'] ?? 'PICKUP',
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      address: json['address'] ?? '',
      passengerName: json['passengerName'],
    );
  }
}
