import 'package:ekride_frontend/models/stop.dart';

class PassengerShare {
  final int passengerId;
  final String passengerName;
  final double individualFare;
  final double directSoloFare;
  final double savings;
  final double savingsPercent;

  PassengerShare({
    required this.passengerId,
    required this.passengerName,
    required this.individualFare,
    required this.directSoloFare,
    required this.savings,
    required this.savingsPercent,
  });

  factory PassengerShare.fromJson(Map<String, dynamic> json) {
    return PassengerShare(
      passengerId: json['passengerId'] ?? 0,
      passengerName: json['passengerName'] ?? '',
      individualFare: (json['individualFare'] as num).toDouble(),
      directSoloFare: (json['directSoloFare'] as num).toDouble(),
      savings: (json['savings'] as num).toDouble(),
      savingsPercent: (json['savingsPercent'] as num).toDouble(),
    );
  }
}

class FareBreakdown {
  final double totalVehicleFare;
  final double baseFareComponent;
  final double distanceFareComponent;
  final double timeFareComponent;
  final double platformFee;
  final double driverEarnings;
  final double detourCostComponent;
  final double userDetourShare;
  final double peerDetourShare;
  final List<PassengerShare> passengerShares;

  FareBreakdown({
    required this.totalVehicleFare,
    required this.baseFareComponent,
    required this.distanceFareComponent,
    required this.timeFareComponent,
    required this.platformFee,
    required this.driverEarnings,
    this.detourCostComponent = 0.0,
    this.userDetourShare = 0.0,
    this.peerDetourShare = 0.0,
    required this.passengerShares,
  });

  factory FareBreakdown.fromJson(Map<String, dynamic> json) {
    var list = (json['passengerShares'] as List?) ?? [];
    return FareBreakdown(
      totalVehicleFare: (json['totalVehicleFare'] as num).toDouble(),
      baseFareComponent: (json['baseFareComponent'] as num).toDouble(),
      distanceFareComponent: (json['distanceFareComponent'] as num).toDouble(),
      timeFareComponent: (json['timeFareComponent'] as num).toDouble(),
      platformFee: (json['platformFee'] as num).toDouble(),
      driverEarnings: (json['driverEarnings'] as num).toDouble(),
      detourCostComponent: ((json['detourCostComponent'] ?? 0.0) as num).toDouble(),
      userDetourShare: ((json['userDetourShare'] ?? 0.0) as num).toDouble(),
      peerDetourShare: ((json['peerDetourShare'] ?? 0.0) as num).toDouble(),
      passengerShares: list.map((e) => PassengerShare.fromJson(e)).toList(),
    );
  }
}

class RouteOption {
  final String optionId;
  final String title;
  final String description;
  final int totalDistanceMeters;
  final int totalDurationSeconds;
  final int extraDistanceMeters;
  final int extraDurationSeconds;
  final double estimatedTotalFare;
  final double userIndividualFare;
  final double directSoloFare;
  final double estimatedSavings;
  final double savingsPercent;
  final int availableSeats;
  final String? encodedPolyline;
  final List<List<double>> pathCoordinates;
  final List<RouteStop> stops;
  final FareBreakdown? fareBreakdown;
  final List<String> warnings;

  int get rideId => int.tryParse(optionId.replaceAll(RegExp(r'[^0-9]'), '')) ?? 1;
  double get savings => estimatedSavings;
  String get durationFormatted => '${(totalDurationSeconds / 60).round()} mins';
  String get distanceFormatted => '${(totalDistanceMeters / 1000).toStringAsFixed(1)} km';
  String get extraDistanceFormatted => '+${(extraDistanceMeters / 1000).toStringAsFixed(1)} km';
  String get extraDurationFormatted => '+${(extraDurationSeconds / 60).round()} mins';
  int get riderCount {
    if (optionId == 'option_direct_solo') return 1;
    final pickups = stops.where((s) => s.type == 'PICKUP').length;
    if (pickups > 0) return pickups + 1;
    if (fareBreakdown != null && fareBreakdown!.passengerShares.isNotEmpty) {
      return fareBreakdown!.passengerShares.length;
    }
    return 2;
  }

  RouteOption({
    required this.optionId,
    required this.title,
    required this.description,
    required this.totalDistanceMeters,
    required this.totalDurationSeconds,
    required this.extraDistanceMeters,
    required this.extraDurationSeconds,
    required this.estimatedTotalFare,
    required this.userIndividualFare,
    required this.directSoloFare,
    required this.estimatedSavings,
    required this.savingsPercent,
    required this.availableSeats,
    this.encodedPolyline,
    this.pathCoordinates = const [],
    required this.stops,
    this.fareBreakdown,
    required this.warnings,
  });

  factory RouteOption.fromJson(Map<String, dynamic> json) {
    var rawStops = (json['stops'] as List?) ?? [];
    var rawWarnings = (json['warnings'] as List?) ?? [];
    var rawCoords = (json['pathCoordinates'] as List?) ?? [];
    List<List<double>> parsedCoords = [];
    for (var item in rawCoords) {
      if (item is List && item.length >= 2) {
        parsedCoords.add([(item[0] as num).toDouble(), (item[1] as num).toDouble()]);
      }
    }

    return RouteOption(
      optionId: json['optionId'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      totalDistanceMeters: json['totalDistanceMeters'] ?? 0,
      totalDurationSeconds: json['totalDurationSeconds'] ?? 0,
      extraDistanceMeters: json['extraDistanceMeters'] ?? 0,
      extraDurationSeconds: json['extraDurationSeconds'] ?? 0,
      estimatedTotalFare: (json['estimatedTotalFare'] as num).toDouble(),
      userIndividualFare: (json['userIndividualFare'] as num).toDouble(),
      directSoloFare: (json['directSoloFare'] as num).toDouble(),
      estimatedSavings: (json['estimatedSavings'] as num).toDouble(),
      savingsPercent: (json['savingsPercent'] as num).toDouble(),
      availableSeats: json['availableSeats'] ?? 1,
      encodedPolyline: json['encodedPolyline'],
      pathCoordinates: parsedCoords,
      stops: rawStops.map((s) => RouteStop.fromJson(s)).toList(),
      fareBreakdown: json['fareBreakdown'] != null ? FareBreakdown.fromJson(json['fareBreakdown']) : null,
      warnings: rawWarnings.map((w) => w.toString()).toList(),
    );
  }
}
