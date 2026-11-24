class PlacePrediction {
  final String placeId;
  final String primaryText;
  final String secondaryText;
  final String fullText;
  final double? lat;
  final double? lng;

  PlacePrediction({
    required this.placeId,
    required this.primaryText,
    required this.secondaryText,
    required this.fullText,
    this.lat,
    this.lng,
  });

  factory PlacePrediction.fromJson(Map<String, dynamic> json) {
    return PlacePrediction(
      placeId: json['placeId'] ?? '',
      primaryText: json['primaryText'] ?? '',
      secondaryText: json['secondaryText'] ?? '',
      fullText: json['fullText'] ?? '',
      lat: (json['lat'] is num) ? (json['lat'] as num).toDouble() : null,
      lng: (json['lng'] is num) ? (json['lng'] as num).toDouble() : null,
    );
  }
}
