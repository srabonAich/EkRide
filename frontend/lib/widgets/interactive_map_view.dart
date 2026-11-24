import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:ekride_frontend/core/app_strings.dart';
import 'package:ekride_frontend/services/app_settings_provider.dart';
import 'package:ekride_frontend/models/candidate.dart';
import 'package:ekride_frontend/models/route_option.dart';
import 'package:ekride_frontend/models/stop.dart';
import 'package:ekride_frontend/core/polyline_utils.dart';
import 'package:ekride_frontend/widgets/google_maps_guide_dialog.dart';
import 'package:ekride_frontend/core/stop_location_resolver.dart';
import 'package:ekride_frontend/services/ride_provider.dart';

class InteractiveMapView extends StatefulWidget {
  final double originLat;
  final double originLng;
  final String originAddress;
  final double destLat;
  final double destLng;
  final String destAddress;
  final RouteOption? selectedOption;
  final List<CandidatePassenger> candidates;
  final double? driverLat;
  final double? driverLng;
  final double? driverBearing;
  final double? driverSpeedKmh;
  final double? remainingDistanceKm;
  final int? remainingDurationSeconds;
  final double tripProgress;
  final String? trackingStatus;
  final bool isSimulating;
  final bool isSimulationPaused;
  final double simulationSpeed;
  final VoidCallback? onToggleSimulationPause;
  final Function(double speed)? onSimulationSpeedChange;
  final VoidCallback? onRestartSimulation;
  final VoidCallback? onStopSimulation;
  final VoidCallback? onStartSimulation;
  final String mapPinMode;
  final Function(double lat, double lng)? onMapTap;

  const InteractiveMapView({
    super.key,
    required this.originLat,
    required this.originLng,
    required this.originAddress,
    required this.destLat,
    required this.destLng,
    required this.destAddress,
    this.selectedOption,
    required this.candidates,
    this.driverLat,
    this.driverLng,
    this.driverBearing,
    this.driverSpeedKmh,
    this.remainingDistanceKm,
    this.remainingDurationSeconds,
    this.tripProgress = 0.0,
    this.trackingStatus,
    this.isSimulating = false,
    this.isSimulationPaused = false,
    this.simulationSpeed = 1.0,
    this.onToggleSimulationPause,
    this.onSimulationSpeedChange,
    this.onRestartSimulation,
    this.onStopSimulation,
    this.onStartSimulation,
    this.mapPinMode = 'none',
    this.onMapTap,
  });

  @override
  State<InteractiveMapView> createState() => _InteractiveMapViewState();
}


class _MapResolvedPin {
  final int index;
  final RouteStop stop;
  final String letter;
  final Color color;
  final IconData icon;
  final String roleText;
  final String microSummary;
  final StopLocationDetails details;
  final LatLng exactLatLng;
  LatLng displayLatLng;
  bool isDisplaced;
  bool placePillOnTop;

  _MapResolvedPin({
    required this.index,
    required this.stop,
    required this.letter,
    required this.color,
    required this.icon,
    required this.roleText,
    required this.microSummary,
    required this.details,
    required this.exactLatLng,
    required this.displayLatLng,
    this.isDisplaced = false,
    this.placePillOnTop = true,
  });
}

class _InteractiveMapViewState extends State<InteractiveMapView> {

  List<RouteStop> _getOrderedStops() {
    if (widget.selectedOption != null && widget.selectedOption!.stops.isNotEmpty) {
      final list = List<RouteStop>.from(widget.selectedOption!.stops);
      list.sort((a, b) => a.order.compareTo(b.order));
      return list;
    }
    return [
      RouteStop(
        order: 1,
        type: 'ORIGIN',
        lat: widget.originLat,
        lng: widget.originLng,
        address: widget.originAddress.isNotEmpty ? widget.originAddress : 'Pickup Location',
      ),
      RouteStop(
        order: 2,
        type: 'DESTINATION',
        lat: widget.destLat,
        lng: widget.destLng,
        address: widget.destAddress.isNotEmpty ? widget.destAddress : 'Destination Location',
      ),
    ];
  }

  List<_MapResolvedPin> _resolvePinLayout(
    List<RouteStop> stops,
    List<CandidatePassenger> candidates,
    bool isBn,
  ) {
    final waypoints = StopLocationResolver.resolveGoogleMapsPins(
      originLat: widget.originLat,
      originLng: widget.originLng,
      originAddress: widget.originAddress,
      destLat: widget.destLat,
      destLng: widget.destLng,
      destAddress: widget.destAddress,
      stops: stops,
      candidates: candidates,
      isBn: isBn,
    );

    final list = <_MapResolvedPin>[];
    for (int i = 0; i < waypoints.length; i++) {
      final pin = waypoints[i];
      final coord = pin.coordinate;

      String microSummary;
      final hasUserOrigin = pin.matchedStops.any((s) => s.type == "ORIGIN");
      final hasUserDest = pin.matchedStops.any((s) => s.type == "DESTINATION");
      final peerPickups = pin.matchedStops
          .where((s) => s.type == "PICKUP" && s.passengerName != null && s.passengerName!.isNotEmpty)
          .map((s) => s.passengerName!.trim().split(" ").first)
          .toList();
      final peerDropoffs = pin.matchedStops
          .where((s) => s.type == "DROPOFF" && s.passengerName != null && s.passengerName!.isNotEmpty)
          .map((s) => s.passengerName!.trim().split(" ").first)
          .toList();

      if (hasUserOrigin) {
        microSummary = peerPickups.isNotEmpty
            ? (isBn ? "আপনি ও ${peerPickups.join(' & ')}" : "You & ${peerPickups.join(' & ')}")
            : (isBn ? "আপনার পিকআপ" : "Your Pickup");
      } else if (hasUserDest) {
        microSummary = peerDropoffs.isNotEmpty
            ? (isBn ? "আপনি ও ${peerDropoffs.join(' & ')} (নামবে)" : "You & ${peerDropoffs.join(' & ')} (Drop)")
            : (isBn ? "আপনার গন্তব্য" : "Your Dest");
      } else if (peerPickups.isNotEmpty) {
        final name = peerPickups.join(" & ");
        microSummary = isBn ? "$name উঠবে" : "$name (Pick)";
      } else if (peerDropoffs.isNotEmpty) {
        final name = peerDropoffs.join(" & ");
        microSummary = isBn ? "$name নামবে" : "$name (Drop)";
      } else {
        microSummary = isBn ? "স্টপ" : "Stop";
      }

      final details = StopLocationDetails(
        exactLandmark: pin.exactLandmark,
        passengerHomeArea: pin.mainArea,
        walkingGuide: pin.walkingGuide,
        hasWalkConnection: pin.walkingGuide.contains("🚶"),
      );

      final dummyStop = pin.matchedStops.isNotEmpty
          ? pin.matchedStops.first
          : RouteStop(
              order: i + 1,
              type: pin.isStart ? "ORIGIN" : (pin.isFinalDest ? "DESTINATION" : "PICKUP"),
              lat: coord.latitude,
              lng: coord.longitude,
              address: pin.exactLandmark,
            );

      list.add(_MapResolvedPin(
        index: i,
        stop: dummyStop,
        letter: pin.letter,
        color: pin.pinColor,
        icon: pin.pinIcon,
        roleText: pin.roleText,
        microSummary: microSummary,
        details: details,
        exactLatLng: coord,
        displayLatLng: coord,
        isDisplaced: false,
        placePillOnTop: true,
      ));
    }

    // 1. Cluster-based Radial Fan-Out Collision Avoidance (< 130 meters)
    final visited = <int>{};
    for (int i = 0; i < list.length; i++) {
      if (visited.contains(i)) continue;
      final cluster = [list[i]];
      visited.add(i);

      for (int j = i + 1; j < list.length; j++) {
        final dist = StopLocationResolver.haversineMeters(
          list[i].exactLatLng.latitude,
          list[i].exactLatLng.longitude,
          list[j].exactLatLng.latitude,
          list[j].exactLatLng.longitude,
        );
        if (dist < 130.0) {
          cluster.add(list[j]);
          visited.add(j);
        }
      }

      if (cluster.length > 1) {
        final n = cluster.length;
        for (int k = 0; k < n; k++) {
          final pin = cluster[k];
          pin.isDisplaced = true;
          final angle = (2 * math.pi * k) / n - (math.pi / 4);
          const offsetDist = 0.00042;
          pin.displayLatLng = LatLng(
            pin.exactLatLng.latitude + offsetDist * math.sin(angle),
            pin.exactLatLng.longitude + offsetDist * math.cos(angle),
          );
          pin.placePillOnTop = math.sin(angle) >= 0;
        }
      }
    }

    // 2. Proximity check between Stop Pins and Candidate Passengers to eliminate overlap!
    for (final pin in list) {
      for (final c in candidates) {
        final dist = StopLocationResolver.haversineMeters(
          pin.displayLatLng.latitude,
          pin.displayLatLng.longitude,
          c.pickupLat,
          c.pickupLng,
        );

        if (dist < 180.0) {
          final dLat = c.pickupLat - pin.displayLatLng.latitude;
          if (dLat > -0.0001) {
            pin.placePillOnTop = false;
          } else {
            pin.placePillOnTop = true;
          }
        }
      }
    }

    return list;
  }

  LatLng _resolveLocationDisplayCoord(
    double baseLat,
    double baseLng,
    List<_MapResolvedPin> resolvedPins, {
    List<LatLng>? otherCoords,
  }) {
    double lat = baseLat;
    double lng = baseLng;

    for (final pin in resolvedPins) {
      final dist = StopLocationResolver.haversineMeters(
        lat,
        lng,
        pin.displayLatLng.latitude,
        pin.displayLatLng.longitude,
      );

      if (dist < 130.0) {
        final dLat = lat - pin.displayLatLng.latitude;
        final dLng = lng - pin.displayLatLng.longitude;

        if (dLat >= 0) {
          lat = pin.displayLatLng.latitude + 0.00065;
        } else {
          lat = pin.displayLatLng.latitude - 0.00065;
        }
        if (dLng >= 0) {
          lng = pin.displayLatLng.longitude + 0.00055;
        } else {
          lng = pin.displayLatLng.longitude - 0.00055;
        }
        break;
      }
    }

    if (otherCoords != null) {
      for (final other in otherCoords) {
        final dist = StopLocationResolver.haversineMeters(lat, lng, other.latitude, other.longitude);
        if (dist < 70.0) {
          lat += 0.00055;
          lng += 0.00050;
        }
      }
    }

    return LatLng(lat, lng);
  }



  Widget _buildPassengerAvatar(
    CandidatePassenger c,
    bool isSelectedPeer,
    bool isBn, {
    bool isDropoff = false,
  }) {
    final firstName = c.passengerName.trim().split(' ').first;
    final initial = firstName.isNotEmpty ? firstName[0].toUpperCase() : 'P';

    final gradientColors = isDropoff
        ? (isSelectedPeer
            ? const [Color(0xFFEA580C), Color(0xFFC2410C)]
            : const [Color(0xFF9A3412), Color(0xFF7C2D12)])
        : (isSelectedPeer
            ? const [Color(0xFF2563EB), Color(0xFF1D4ED8)]
            : const [Color(0xFF0F766E), Color(0xFF0D9488)]);

    final borderColor = isDropoff
        ? (isSelectedPeer ? const Color(0xFFFDBA74) : Colors.white70)
        : (isSelectedPeer ? const Color(0xFF60A5FA) : Colors.white);

    final shadowColor = isDropoff
        ? const Color(0xFFEA580C).withValues(alpha: isSelectedPeer ? 0.60 : 0.40)
        : (isSelectedPeer
            ? const Color(0xFF2563EB).withValues(alpha: 0.55)
            : const Color(0xFF0D9488).withValues(alpha: 0.40));

    return SizedBox(
      width: 48,
      height: 48,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Container(
            width: isSelectedPeer ? 38 : 34,
            height: isSelectedPeer ? 38 : 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradientColors,
              ),
              border: Border.all(
                color: borderColor,
                width: isSelectedPeer ? 2.5 : 2.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: shadowColor,
                  blurRadius: isSelectedPeer ? 9 : 6,
                  offset: const Offset(0, 3),
                ),
                const BoxShadow(color: Colors.black45, blurRadius: 4),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: TextStyle(
                color: Colors.white,
                fontSize: isSelectedPeer ? 16 : 14.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          if (isSelectedPeer || isDropoff)
            Positioned(
              left: -2,
              top: -2,
              child: Container(
                padding: const EdgeInsets.all(2.5),
                decoration: BoxDecoration(
                  color: isDropoff ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.2),
                  boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 4)],
                ),
                child: Icon(
                  isDropoff ? Icons.flag_rounded : Icons.check_rounded,
                  color: Colors.white,
                  size: isDropoff ? 10 : 9.5,
                ),
              ),
            ),
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.2),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isDropoff ? const Color(0xFFF97316) : const Color(0xFFF59E0B),
                  width: 1.1,
                ),
                boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 3)],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isDropoff ? Icons.location_on_rounded : Icons.star_rounded,
                    color: isDropoff ? const Color(0xFFF97316) : const Color(0xFFF59E0B),
                    size: 9.5,
                  ),
                  const SizedBox(width: 1.5),
                  Text(
                    isDropoff
                        ? (isBn ? 'নামবে' : 'Drop')
                        : c.rating.toStringAsFixed(1),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPassengerModal(CandidatePassenger c, bool isSelectedPeer, bool isBn, {bool isDropoff = false}) {
    final firstName = c.passengerName.trim().split(' ').first;
    final initial = firstName.isNotEmpty ? firstName[0].toUpperCase() : '👤';
    final badgeColor = isDropoff
        ? const Color(0xFFEA580C)
        : (isSelectedPeer ? const Color(0xFF2563EB) : const Color(0xFF0D9488));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: badgeColor.withValues(alpha: 0.6), width: 1.5),
        ),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20),
        actionsPadding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: badgeColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: badgeColor.withValues(alpha: 0.4), blurRadius: 8),
                ],
              ),
              child: Center(
                child: Text(
                  initial,
                  style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.verified_user_rounded, color: Color(0xFF34D399), size: 16),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          isDropoff
                              ? (isBn ? '${c.passengerName} (ড্রপঅফ)' : '${c.passengerName} (Dropoff)')
                              : c.passengerName,
                          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${c.university} • ★${c.rating.toStringAsFixed(1)}',
                    style: TextStyle(color: badgeColor, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            // Pickup Spot
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: badgeColor.withValues(alpha: 0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.pin_drop_rounded, color: badgeColor, size: 15),
                      const SizedBox(width: 6),
                      Text(
                        isBn ? 'পিকআপ অবস্থান:' : 'Pickup Location:',
                        style: TextStyle(color: badgeColor, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    c.pickupAddress,
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            ),
            if (c.dropoffAddress.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.flag_rounded, color: Color(0xFFEF4444), size: 15),
                        const SizedBox(width: 6),
                        Text(
                          isBn ? 'গন্তব্য:' : 'Destination:',
                          style: const TextStyle(color: Color(0xFFEF4444), fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      c.dropoffAddress,
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.savings_rounded, color: Color(0xFF34D399), size: 15),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      isBn
                          ? 'একই রুটে শেয়ার করলে উভয়ের ভাড়া সর্বোচ্চ সাশ্রয় হবে'
                          : 'Sharing this route maximizes mutual fare savings',
                      style: const TextStyle(color: Color(0xFF34D399), fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Consumer<RideProvider>(
            builder: (context, ride, _) {
              final isInPool = isSelectedPeer || ride.isPassengerSelected(c);
              final canAdd = ride.canSelectMorePassengers;

              if (isInPool) {
                return ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    ride.togglePassengerSelection(c);
                  },
                  icon: const Icon(Icons.remove_circle_outline_rounded, size: 15),
                  label: Text(
                    isBn ? '$firstName-কে পুল থেকে বাদ দিন' : 'Remove $firstName from Pool',
                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              }

              if (canAdd) {
                return ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    ride.togglePassengerSelection(c);
                  },
                  icon: const Icon(Icons.add_circle_outline_rounded, size: 15),
                  label: Text(
                    isBn ? '$firstName-কে পুলে যোগ করুন' : 'Add $firstName to Pool',
                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              }

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF334155),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  isBn ? 'গাড়ির সব সিট পূর্ণ' : 'Car Seats Full',
                  style: const TextStyle(color: Colors.white70, fontSize: 11.5, fontWeight: FontWeight.bold),
                ),
              );
            },
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isBn ? 'বন্ধ' : 'Close', style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildRichMapPin(_MapResolvedPin p) {
    final isStart = p.index == 0 || p.letter == 'Start';

    // 1. Sleek circular badge (Exact 1-to-1 match with GoogleMapsGuideDialog)
    final badgeCircle = Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [p.color, p.color.withValues(alpha: 0.88)],
        ),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2.2),
        boxShadow: [
          BoxShadow(
            color: p.color.withValues(alpha: 0.50),
            blurRadius: 7,
            offset: const Offset(0, 2),
          ),
          const BoxShadow(color: Colors.black45, blurRadius: 4),
        ],
      ),
      alignment: Alignment.center,
      child: isStart
          ? const Icon(Icons.trip_origin_rounded, color: Colors.white, size: 19)
          : Text(
              p.letter,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
    );

    // 2. Micro summary pill (Compact, high readability, shows who gets in/out)
    final microPill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xF20F172A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: p.color.withValues(alpha: 0.8), width: 1.2),
        boxShadow: const [
          BoxShadow(color: Colors.black54, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(p.icon, color: p.color, size: 12),
          const SizedBox(width: 4),
          Text(
            p.microSummary,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );

    // 3. Tiny directional tip
    final pointerDown = Icon(Icons.arrow_drop_down_rounded, color: p.color, size: 14);
    final pointerUp = Icon(Icons.arrow_drop_up_rounded, color: p.color, size: 14);

    if (p.placePillOnTop) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          microPill,
          const SizedBox(height: 2),
          badgeCircle,
          pointerDown,
        ],
      );
    } else {
      return Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          pointerUp,
          badgeCircle,
          const SizedBox(height: 2),
          microPill,
        ],
      );
    }
  }

  bool _seeRoadNames = false;
  late final MapController _mapController;
  // 0=Google Maps (Streets), 1=Dark Mode (ESRI Canvas), 2=Satellite (Google Hybrid)
  int _styleIndex = 0;
  // Live Traffic overlay state (Default: ON)
  bool _showTraffic = true;

  void _openInGoogleMaps() async {
    
    // Launch Google Maps in external browser tab / mobile app
    PolylineUtils.launchGoogleMapsDirections(
      originLat: widget.originLat,
      originLng: widget.originLng,
      destLat: widget.destLat,
      destLng: widget.destLng,
      stops: widget.selectedOption?.stops,
    );

    // Show the interactive Stops & Passenger Guide Dialog
    if (mounted) {
      GoogleMapsGuideDialog.show(
        context,
        option: widget.selectedOption,
        originLat: widget.originLat,
        originLng: widget.originLng,
        originAddress: widget.originAddress,
        destLat: widget.destLat,
        destLng: widget.destLng,
        destAddress: widget.destAddress,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void didUpdateWidget(covariant InteractiveMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final originChanged = oldWidget.originLat != widget.originLat ||
        oldWidget.originLng != widget.originLng;
    final destChanged = oldWidget.destLat != widget.destLat ||
        oldWidget.destLng != widget.destLng;
    final optionChanged =
        oldWidget.selectedOption?.optionId != widget.selectedOption?.optionId;
    if (originChanged || destChanged || optionChanged) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _fitBounds());
    }
  }

  void _fitBounds() {
    final points = <LatLng>[
      LatLng(widget.originLat, widget.originLng),
      LatLng(widget.destLat, widget.destLng),
      ...widget.candidates.map((c) => LatLng(c.pickupLat, c.pickupLng)),
    ];
    if (widget.selectedOption != null) {
      for (final s in widget.selectedOption!.stops) {
        if (s.lat >= -90 && s.lat <= 90 && s.lng >= -180 && s.lng <= 180) {
          points.add(LatLng(s.lat, s.lng));
        }
      }
    }
    if (points.isEmpty) return;

    try {
      final bounds = LatLngBounds.fromPoints(points);
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.all(65),
        ),
      );
    } catch (_) {}
  }

  List<LatLng> _getRoutePoints(RouteOption? option) {
    if (option != null && option.pathCoordinates.isNotEmpty) {
      return option.pathCoordinates
          .where((pt) =>
              pt.length >= 2 &&
              pt[0] >= -90 &&
              pt[0] <= 90 &&
              pt[1] >= -180 &&
              pt[1] <= 180)
          .map((pt) => LatLng(pt[0], pt[1]))
          .toList();
    }
    return _decodePolyline(option?.encodedPolyline);
  }

  List<LatLng> _decodePolyline(String? encoded) {
    if (encoded == null || encoded.isEmpty) {
      final pts = <LatLng>[LatLng(widget.originLat, widget.originLng)];
      if (widget.selectedOption != null) {
        for (final s in widget.selectedOption!.stops) {
          if (s.type != 'ORIGIN' && s.type != 'DESTINATION') {
            pts.add(LatLng(s.lat, s.lng));
          }
        }
      }
      pts.add(LatLng(widget.destLat, widget.destLng));
      return pts;
    }

    final pts = <LatLng>[];
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
        pts.add(LatLng(pLat, pLng));
      }
    }
    return pts;
  }

    String get _tileUrl {
    switch (_styleIndex) {
      case 1:
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Dark_Gray_Base/MapServer/tile/{z}/{y}/{x}';
      case 2:
        return _showTraffic
            ? 'https://mt{s}.google.com/vt/lyrs=y,traffic&x={x}&y={y}&z={z}'
            : 'https://mt{s}.google.com/vt/lyrs=y&x={x}&y={y}&z={z}';
      case 0:
      default:
        return _showTraffic
            ? 'https://mt{s}.google.com/vt/lyrs=m,traffic&x={x}&y={y}&z={z}'
            : 'https://mt{s}.google.com/vt/lyrs=m&x={x}&y={y}&z={z}';
    }
  }

  List<String> get _subdomains {
    if (_styleIndex == 1) return const [];
    return const ['0', '1', '2', '3'];
  }

    String _getLayerDisplayLabel(bool isBn) {
    switch (_styleIndex) {
      case 1:
        return isBn ? 'লেয়ার: ডার্ক' : 'Layer: Dark';
      case 2:
        return isBn ? 'লেয়ার: স্যাটেলাইট' : 'Layer: Satellite';
      default:
        return isBn ? 'লেয়ার: সাধারণ' : 'Layer: Streets';
    }
  }

  @override
  Widget build(BuildContext context) {
    final appSettings = context.watch<AppSettingsProvider>();
    final isBn = appSettings.isBangla;

    final route = _getRoutePoints(widget.selectedOption);
    final allCandidates = widget.candidates;

    final selectedPeers = <CandidatePassenger>[];
    if (widget.selectedOption != null) {
      final title = widget.selectedOption!.title.toLowerCase();
      final stopNames = widget.selectedOption!.stops
          .where((s) => s.passengerName != null && s.passengerName!.isNotEmpty)
          .map((s) => s.passengerName!.toLowerCase().split(' ').first)
          .toSet();
      for (final c in allCandidates) {
        final firstName = c.passengerName.toLowerCase().split(' ').first;
        if (title.contains(firstName) || stopNames.contains(firstName)) {
          selectedPeers.add(c);
        }
      }
    }

    final orderedStops = _getOrderedStops();
    final resolvedPins = _resolvePinLayout(orderedStops, allCandidates, isBn);
    final centerLat = (widget.originLat + widget.destLat) / 2;
    final centerLng = (widget.originLng + widget.destLng) / 2;

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Stack(
        children: [
          // ─── Real Map Layer with Real-Time Live Traffic ────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: LatLng(centerLat, centerLng),
              initialZoom: 13.0,
              minZoom: 6.0,
              maxZoom: 19.0,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
              onTap: (tapPosition, point) {
                if (widget.onMapTap != null) {
                  widget.onMapTap!(point.latitude, point.longitude);
                }
              },
            ),
            children: [
              // Single Primary Map Tile Layer (Original crisp typography & real-time traffic)
              TileLayer(
                urlTemplate: _tileUrl,
                subdomains: _subdomains,
                userAgentPackageName: 'com.ekride.smart_student_rides',
                maxZoom: 20,
              ),

              // Road-following Polyline Layer
              if (route.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    // Outer subtle casing (glow border)
                    Polyline(
                      points: route,
                      strokeWidth: _seeRoadNames ? 6.0 : 8.0,
                      color: const Color(0xFF1E3A8A).withValues(alpha: _seeRoadNames ? 0.20 : 0.35),
                      strokeCap: StrokeCap.round,
                      strokeJoin: StrokeJoin.round,
                    ),
                    // Main high-visibility route line (semi-translucent so road names beneath stay readable!)
                    Polyline(
                      points: route,
                      strokeWidth: _seeRoadNames ? 3.5 : 4.8,
                      color: const Color(0xFF2563EB).withValues(alpha: _seeRoadNames ? 0.40 : 0.70),
                      strokeCap: StrokeCap.round,
                      strokeJoin: StrokeJoin.round,
                    ),

                    // 1. Walking Connection Polylines for PICKUP (between passenger home avatar and curbside pickup stop)
                    if (widget.selectedOption != null && selectedPeers.isNotEmpty)
                      ...widget.selectedOption!.stops
                          .where((s) => s.type == 'PICKUP')
                          .map((s) {
                        final stopFirst = (s.passengerName ?? '').toLowerCase().split(' ').first;
                        CandidatePassenger? matchingCand;
                        for (final p in selectedPeers) {
                          if (p.passengerName.toLowerCase().contains(stopFirst)) {
                            matchingCand = p;
                            break;
                          }
                        }
                        matchingCand ??= selectedPeers.first;
                        final candDisplayCoord = _resolveLocationDisplayCoord(
                          matchingCand.pickupLat,
                          matchingCand.pickupLng,
                          resolvedPins,
                        );
                        return Polyline(
                          points: [candDisplayCoord, LatLng(s.lat, s.lng)],
                          strokeWidth: 3.0,
                          color: const Color(0xFFF59E0B),
                          pattern: StrokePattern.dashed(segments: const [6.0, 4.0]),
                        );
                      }),

                    // 2. Walking Connection Polylines for DROPOFF (between curbside dropoff stop and passenger destination avatar)
                    if (widget.selectedOption != null && selectedPeers.isNotEmpty)
                      ...widget.selectedOption!.stops
                          .where((s) => s.type == 'DROPOFF')
                          .map((s) {
                        final stopFirst = (s.passengerName ?? '').toLowerCase().split(' ').first;
                        CandidatePassenger? matchingCand;
                        for (final p in selectedPeers) {
                          if (p.passengerName.toLowerCase().contains(stopFirst)) {
                            matchingCand = p;
                            break;
                          }
                        }
                        if (matchingCand == null) return Polyline(points: const []);
                        final dropDisplayCoord = _resolveLocationDisplayCoord(
                          matchingCand.dropoffLat,
                          matchingCand.dropoffLng,
                          resolvedPins,
                        );
                        return Polyline(
                          points: [LatLng(s.lat, s.lng), dropDisplayCoord],
                          strokeWidth: 3.0,
                          color: const Color(0xFFEA580C),
                          pattern: StrokePattern.dashed(segments: const [6.0, 4.0]),
                        );
                      }),

                    // Anti-Collision Leader Lines for Displaced Pins
                    ...resolvedPins
                        .where((p) => p.isDisplaced)
                        .map((p) => Polyline(
                              points: [p.exactLatLng, p.displayLatLng],
                              strokeWidth: 2.2,
                              color: p.color.withValues(alpha: 0.85),
                              pattern: StrokePattern.dashed(segments: const [4.0, 3.0]),
                            )),
                  ],
                ),

              // Markers Layer
              MarkerLayer(
                markers: [
                  // 1. Precise road-level target dots for displaced pins (Anti-Collision Guide)
                  ...resolvedPins
                      .where((p) => p.isDisplaced)
                      .map((p) => Marker(
                            point: p.exactLatLng,
                            width: 14,
                            height: 14,
                            alignment: Alignment.center,
                            child: Center(
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: p.color,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                  boxShadow: const [
                                    BoxShadow(color: Colors.black45, blurRadius: 4),
                                  ],
                                ),
                              ),
                            ),
                          )),

                  // 2. All Ordered Route Stop Pins (Start, A, B, C...)
                  // Matching Google Maps & Details modal 100%, with micro-summary pills showing who gets on/off
                  ...resolvedPins.map((p) {
                    return Marker(
                      point: p.displayLatLng,
                      width: 140,
                      height: 72,
                      alignment: Alignment.center,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          _showLocationInfoModal(
                            title: p.roleText,
                            subtitle: (p.index == 0 || p.letter == 'Start')
                                ? (isBn ? 'গুগল ম্যাপস শুরুর পয়েন্ট' : 'Google Maps Start Point')
                                : (isBn ? 'গুগল ম্যাপস পিন (${p.letter})' : 'Google Maps Pin (${p.letter})'),
                            exactSpot: p.details.exactLandmark,
                            mainArea: p.details.passengerHomeArea,
                            badgeColor: p.color,
                            letterBadge: p.letter,
                            icon: p.icon,
                            walkingGuide: p.details.walkingGuide,
                            isBn: isBn,
                          );
                        },
                        child: _buildRichMapPin(p),
                      ),
                    );
                  }),

                  // 3. All Nearby Candidate Peer Profile Avatars for PICKUP (with Green Checkmark ✔)
                  ...allCandidates.map((c) {
                    final isSelectedPeer = selectedPeers.any((p) => p.passengerId == c.passengerId);
                    final candCoord = _resolveLocationDisplayCoord(
                      c.pickupLat,
                      c.pickupLng,
                      resolvedPins,
                    );
                    return Marker(
                      point: candCoord,
                      width: 48,
                      height: 48,
                      alignment: Alignment.center,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _showPassengerModal(c, isSelectedPeer, isBn, isDropoff: false),
                        child: _buildPassengerAvatar(c, isSelectedPeer, isBn, isDropoff: false),
                      ),
                    );
                  }),

                  // 4. Selected Peers Destination Profile Avatars for DROPOFF (with Coral Flag 🚩)
                  if (widget.selectedOption != null && selectedPeers.isNotEmpty)
                    ...() {
                      final placedDropCoords = <LatLng>[];
                      return selectedPeers.map((c) {
                        final dropCoord = _resolveLocationDisplayCoord(
                          c.dropoffLat,
                          c.dropoffLng,
                          resolvedPins,
                          otherCoords: placedDropCoords,
                        );
                        placedDropCoords.add(dropCoord);
                        return Marker(
                          point: dropCoord,
                          width: 48,
                          height: 48,
                          alignment: Alignment.center,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => _showPassengerModal(c, true, isBn, isDropoff: true),
                            child: _buildPassengerAvatar(c, true, isBn, isDropoff: true),
                          ),
                        );
                      });
                    }(),

                  // Driver live location with directional navigation arrow and radar pulse
                  if (widget.driverLat != null && widget.driverLng != null)
                    Marker(
                      point: LatLng(widget.driverLat!, widget.driverLng!),
                      width: 58,
                      height: 58,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF10B981).withValues(alpha: 0.25),
                            ),
                          ),
                          Transform.rotate(
                            angle: (widget.driverBearing ?? 0.0) * (pi / 180.0),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F172A),
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: const Color(0xFF10B981), width: 2.5),
                                boxShadow: const [
                                  BoxShadow(
                                      color: Colors.black54,
                                      blurRadius: 8,
                                      offset: Offset(0, 3))
                                ],
                              ),
                              child: const Center(
                                child: Icon(Icons.navigation_rounded,
                                    color: Color(0xFF34D399), size: 24),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),

          // ─── Header overlay (Current Route Info + Live Traffic + Style toggle) ───
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white24),
                      boxShadow: const [
                        BoxShadow(color: Colors.black45, blurRadius: 8)
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.alt_route_rounded,
                            color: Color(0xFF3B82F6), size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: widget.selectedOption != null
                              ? Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        AppStrings.translateTitle(
                                            widget.selectedOption!.title, isBn),
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 7, vertical: 2.5),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1E293B),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                            color: const Color(0xFF3B82F6)
                                                .withValues(alpha: 0.5)),
                                      ),
                                      child: Text(
                                        "${(widget.selectedOption!.totalDistanceMeters / 1000).toStringAsFixed(1)} ${isBn ? 'কিমি' : 'km'} • ${(widget.selectedOption!.totalDurationSeconds / 60).round()} ${isBn ? 'মিনিট' : 'min'}",
                                        style: const TextStyle(
                                          color: Color(0xFF93C5FD),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    if (widget.selectedOption!.estimatedSavings > 0) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF10B981)
                                              .withValues(alpha: 0.25),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(
                                              color: const Color(0xFF10B981)
                                                  .withValues(alpha: 0.5)),
                                        ),
                                        child: Text(
                                          "${isBn ? 'সাশ্রয় ৳' : 'Save ৳'}${widget.selectedOption!.estimatedSavings.toStringAsFixed(0)}",
                                          style: const TextStyle(
                                            color: Color(0xFF34D399),
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                )
                              : Text(
                                  appSettings.tr('route_planner'),
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Track on Map Button (Single location at top)
                if (widget.selectedOption != null &&
                    (widget.onStartSimulation != null || widget.onStopSimulation != null)) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      if (widget.isSimulating) {
                        widget.onStopSimulation?.call();
                      } else {
                        widget.onStartSimulation?.call();
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 9),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: widget.isSimulating
                              ? [const Color(0xFFDC2626), const Color(0xFFEF4444)]
                              : [const Color(0xFF059669), const Color(0xFF10B981)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(color: Colors.black45, blurRadius: 6),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            widget.isSimulating
                                ? Icons.stop_circle_rounded
                                : Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            widget.isSimulating
                                ? (isBn ? 'ট্র্যাকিং বন্ধ' : 'Stop Tracking')
                                : (isBn ? 'ম্যাপে ট্র্যাক' : 'Track on Map'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                // Google Maps Stops & Navigation Button (Single location at top)
                if (widget.selectedOption != null) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      GoogleMapsGuideDialog.show(
                        context,
                        option: widget.selectedOption,
                        originLat: widget.originLat,
                        originLng: widget.originLng,
                        originAddress: widget.originAddress,
                        destLat: widget.destLat,
                        destLng: widget.destLng,
                        destAddress: widget.destAddress,
                        candidates: widget.candidates,
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 9),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1D4ED8), Color(0xFF2563EB)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF93C5FD).withValues(alpha: 0.6),
                          width: 1.2,
                        ),
                        boxShadow: const [
                          BoxShadow(color: Colors.black45, blurRadius: 6),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.alt_route_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            isBn ? 'গুগল ম্যাপস' : 'Google Maps',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(width: 8),

                // Road Names Under Route Toggle Button
                GestureDetector(
                  onTap: () => setState(() => _seeRoadNames = !_seeRoadNames),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 9),
                    decoration: BoxDecoration(
                      color: _seeRoadNames
                          ? const Color(0xFF1D4ED8).withValues(alpha: 0.9)
                          : Colors.black.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: _seeRoadNames
                              ? const Color(0xFF60A5FA)
                              : Colors.white24,
                          width: 1.5),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _seeRoadNames
                              ? Icons.visibility_rounded
                              : Icons.visibility_outlined,
                          color: _seeRoadNames
                              ? Colors.white
                              : Colors.white70,
                          size: 15,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          isBn
                              ? (_seeRoadNames ? 'রাস্তার নাম: স্পষ্ট' : 'রাস্তার নাম')
                              : (_seeRoadNames ? 'Roads: Clear' : 'Road Names'),
                          style: TextStyle(
                              color: _seeRoadNames
                                  ? Colors.white
                                  : Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Live Traffic Toggle Button
                GestureDetector(
                  onTap: () => setState(() => _showTraffic = !_showTraffic),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 9),
                    decoration: BoxDecoration(
                      color: _showTraffic
                          ? const Color(0xFF065F46).withValues(alpha: 0.9)
                          : Colors.black.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: _showTraffic
                              ? const Color(0xFF10B981)
                              : Colors.white24,
                          width: 1.5),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.traffic_rounded,
                            color: _showTraffic
                                ? const Color(0xFF34D399)
                                : Colors.white70,
                            size: 16),
                        const SizedBox(width: 5),
                        Text(
                          _showTraffic ? appSettings.tr('live_traffic_on') : appSettings.tr('traffic_off'),
                          style: TextStyle(
                              color: _showTraffic
                                  ? Colors.white
                                  : Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Google Maps Style Map Layer Selector (Default / Satellite / Dark)
                Theme(
                  data: Theme.of(context).copyWith(
                    cardColor: const Color(0xFF0F172A),
                  ),
                  child: PopupMenuButton<int>(
                    initialValue: _styleIndex,
                    tooltip: isBn ? 'ম্যাপ লেয়ার (ডিফল্ট / স্যাটেলাইট / ডার্ক)' : 'Map Layers (Default / Satellite / Dark)',
                    offset: const Offset(0, 42),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: const BorderSide(color: Color(0xFF3B82F6), width: 1.2),
                    ),
                    color: const Color(0xFF0F172A),
                    onSelected: (int index) {
                      setState(() => _styleIndex = index);
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 0,
                        child: Row(
                          children: [
                            const Icon(Icons.map_rounded, color: Color(0xFF3B82F6), size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                isBn ? 'ডিফল্ট ম্যাপ (রাস্তা ও ট্রাফিক)' : 'Default Map (Streets)',
                                style: TextStyle(
                                  color: _styleIndex == 0 ? const Color(0xFF60A5FA) : Colors.white,
                                  fontWeight: _styleIndex == 0 ? FontWeight.bold : FontWeight.normal,
                                  fontSize: 12.5,
                                ),
                              ),
                            ),
                            if (_styleIndex == 0)
                              const Icon(Icons.check_rounded, color: Color(0xFF60A5FA), size: 16),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 2,
                        child: Row(
                          children: [
                            const Icon(Icons.satellite_alt_rounded, color: Color(0xFF10B981), size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                isBn ? 'স্যাটেলাইট ভিউ (আসল ছবি)' : 'Satellite View (Aerial)',
                                style: TextStyle(
                                  color: _styleIndex == 2 ? const Color(0xFF34D399) : Colors.white,
                                  fontWeight: _styleIndex == 2 ? FontWeight.bold : FontWeight.normal,
                                  fontSize: 12.5,
                                ),
                              ),
                            ),
                            if (_styleIndex == 2)
                              const Icon(Icons.check_rounded, color: Color(0xFF34D399), size: 16),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 1,
                        child: Row(
                          children: [
                            const Icon(Icons.dark_mode_rounded, color: Color(0xFFA855F7), size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                isBn ? 'ডার্ক মোড (রাত্রিকালীন)' : 'Dark Mode (Night)',
                                style: TextStyle(
                                  color: _styleIndex == 1 ? const Color(0xFFC084FC) : Colors.white,
                                  fontWeight: _styleIndex == 1 ? FontWeight.bold : FontWeight.normal,
                                  fontSize: 12.5,
                                ),
                              ),
                            ),
                            if (_styleIndex == 1)
                              const Icon(Icons.check_rounded, color: Color(0xFFC084FC), size: 16),
                          ],
                        ),
                      ),
                    ],
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 11, vertical: 9),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF3B82F6), width: 1.2),
                        boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 6)],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.layers_rounded, color: Color(0xFF3B82F6), size: 16),
                          const SizedBox(width: 6),
                          Text(
                            _getLayerDisplayLabel(isBn),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_drop_down_rounded, color: Color(0xFF60A5FA), size: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ─── Map-pin mode banner ─────────────────────────────────────────
          if (widget.mapPinMode != 'none')
            Positioned(
              top: 58,
              left: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const [
                    BoxShadow(color: Colors.black45, blurRadius: 10)
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.touch_app_rounded,
                        color: Colors.black, size: 18),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        isBn
                            ? 'ম্যাপে ক্লিক করে ${widget.mapPinMode == "origin" ? "পিকআপ" : "গন্তব্য"} নির্ধারণ করুন'
                            : 'Click on the map to set ${widget.mapPinMode == "origin" ? "Pickup" : "Destination"}',
                        style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w900,
                            fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ─── Live Ride Tracking Floating HUD ─────────────────────────────
          if (widget.isSimulating)
            Positioned(
              bottom: 12,
              left: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.96),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF10B981).withValues(alpha: 0.7),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withValues(alpha: 0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                    const BoxShadow(color: Colors.black87, blurRadius: 12),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Row 1: Status & Telemetry
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.20),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF10B981)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF34D399),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                widget.trackingStatus ??
                                    (isBn
                                        ? 'লাইভ রাইড ট্র্যাকিং'
                                        : 'Live Ride Tracking'),
                                style: const TextStyle(
                                  color: Color(0xFF34D399),
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${(widget.driverSpeedKmh ?? 35).toStringAsFixed(0)} km/h',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: widget.onStopSimulation,
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(Icons.close_rounded,
                                color: Colors.white70, size: 16),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Progress Bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (widget.tripProgress).clamp(0.0, 1.0),
                        backgroundColor: Colors.white12,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF10B981)),
                        minHeight: 4,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Driver info and distance/ETA
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Center(
                            child: Icon(Icons.drive_eta_rounded,
                                color: Colors.white, size: 20),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isBn
                                    ? 'মোঃ আলমগীর হোসেন'
                                    : 'Md. Alamgir Hossain',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                isBn
                                    ? 'টয়োটা প্রিয়াস • ঢাকা মেট্রো-গ ৩২-৪৫১৯'
                                    : 'Toyota Prius • Dhaka Metro GA-32-4519',
                                style: const TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${(widget.remainingDistanceKm ?? 0).toStringAsFixed(1)} ${isBn ? 'কিমি বাকি' : 'km left'}',
                              style: const TextStyle(
                                color: Color(0xFF60A5FA),
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'ETA: ${((widget.remainingDurationSeconds ?? 0) / 60).round()} ${isBn ? 'মিনিট' : 'mins'}',
                              style: const TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Controls Row (Pause/Resume, 1x/2x/4x, Restart, Stop)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ElevatedButton.icon(
                            onPressed: widget.onToggleSimulationPause,
                            icon: Icon(
                              widget.isSimulationPaused
                                  ? Icons.play_arrow_rounded
                                  : Icons.pause_rounded,
                              size: 15,
                              color: Colors.black,
                            ),
                            label: Text(
                              widget.isSimulationPaused
                                  ? (isBn ? 'চালু' : 'Resume')
                                  : (isBn ? 'যাত্রাবিরতি' : 'Pause'),
                              style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              minimumSize: const Size(0, 28),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6)),
                            ),
                          ),
                          Row(
                            children: [
                              _speedButton(1.0, '1x'),
                              const SizedBox(width: 4),
                              _speedButton(2.0, '2x'),
                              const SizedBox(width: 4),
                              _speedButton(4.0, '4x'),
                            ],
                          ),
                          IconButton(
                            onPressed: _openInGoogleMaps,
                            icon: const Icon(Icons.open_in_new_rounded,
                                color: Color(0xFF60A5FA), size: 17),
                            tooltip: isBn ? 'গুগল ম্যাপসে দেখুন (Show in Google Maps)' : 'Show in Google Maps',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          IconButton(
                            onPressed: widget.onRestartSimulation,
                            icon: const Icon(Icons.replay_rounded,
                                color: Colors.white70, size: 18),
                            tooltip: isBn ? 'শুরু থেকে চালান' : 'Restart Simulation',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          IconButton(
                            onPressed: widget.onStopSimulation,
                            icon: const Icon(Icons.stop_circle_outlined,
                                color: Color(0xFFEF4444), size: 18),
                            tooltip: isBn ? 'ট্র্যাকিং বন্ধ' : 'Stop Tracking',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ─── Zoom controls (right side) ──────────────────────────────────
          Positioned(
            right: 12,
            bottom: 56,
            child: Column(
              children: [
                _zoomBtn(Icons.add, () {
                  final z = _mapController.camera.zoom;
                  _mapController.move(
                      _mapController.camera.center, z + 1);
                }),
                const SizedBox(height: 6),
                _zoomBtn(Icons.remove, () {
                  final z = _mapController.camera.zoom;
                  _mapController.move(
                      _mapController.camera.center, z - 1);
                }),
                const SizedBox(height: 6),
                _zoomBtn(Icons.center_focus_strong_rounded, _fitBounds),
              ],
            ),
          ),

          // ─── Live Traffic Congestion Bar (Bottom-Center) ─────────────────
          if (_showTraffic && _styleIndex != 1)
            Positioned(
              bottom: 12,
              right: 60,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(appSettings.tr('traffic_label'),
                        style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                            fontWeight: FontWeight.w600)),
                    _trafficPill(const Color(0xFF10B981), appSettings.tr('traffic_fast')),
                    const SizedBox(width: 6),
                    _trafficPill(const Color(0xFFF59E0B), appSettings.tr('traffic_moderate')),
                    const SizedBox(width: 6),
                    _trafficPill(const Color(0xFFEF4444), appSettings.tr('traffic_slow')),
                    const SizedBox(width: 6),
                    _trafficPill(const Color(0xFF7F1D1D), appSettings.tr('traffic_gridlock')),
                  ],
                ),
              ),
            ),

          // ─── Legend (bottom-left) ────────────────────────────────────────
          Positioned(
            left: 12,
            bottom: 12,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.80),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white24),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _dot(const Color(0xFF10B981), appSettings.tr('legend_pickup')),
                  const SizedBox(width: 10),
                  _dot(const Color(0xFFEF4444), appSettings.tr('legend_destination')),
                  const SizedBox(width: 10),
                  _dot(const Color(0xFFF59E0B), appSettings.tr('legend_peers')),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _trafficPill(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 3),
        Text(label,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w500)),
      ],
    );
  }

  void _showLocationInfoModal({
    required String title,
    required String subtitle,
    required String exactSpot,
    required String mainArea,
    required Color badgeColor,
    required String letterBadge,
    IconData? icon,
    String? walkingGuide,
    bool isBn = true,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: badgeColor.withValues(alpha: 0.6), width: 1.5),
        ),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20),
        actionsPadding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: badgeColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: badgeColor.withValues(alpha: 0.4), blurRadius: 8),
                ],
              ),
              child: Center(
                child: letterBadge == 'Start' || letterBadge == '⭕'
                    ? const Icon(Icons.trip_origin_rounded, color: Colors.white, size: 20)
                    : (letterBadge == '🏠' || letterBadge == '👤'
                        ? Icon(icon ?? Icons.person, color: Colors.white, size: 20)
                        : Text(
                            letterBadge,
                            style: const TextStyle(color: Colors.white, fontSize: 16.5, fontWeight: FontWeight.w900),
                          )),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (icon != null) ...[
                        Icon(icon, color: badgeColor, size: 16),
                        const SizedBox(width: 6),
                      ],
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(color: badgeColor, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            // Exact Google Maps Spot Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: badgeColor.withValues(alpha: 0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.pin_drop_rounded, color: badgeColor, size: 15),
                      const SizedBox(width: 6),
                      Text(
                        isBn ? 'সরাসরি স্পট (Google Maps Pin):' : 'Exact Spot (Google Maps Pin):',
                        style: TextStyle(color: badgeColor, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    exactSpot,
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            // Main Area
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(Icons.location_on_outlined, color: Colors.white60, size: 14),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${isBn ? "মূল এলাকা: " : "Main Area: "}$mainArea',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
              ],
            ),
            if (walkingGuide != null && walkingGuide.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.directions_walk_rounded, color: Color(0xFF34D399), size: 15),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        walkingGuide,
                        style: const TextStyle(color: Color(0xFF34D399), fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (widget.selectedOption != null)
            TextButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                GoogleMapsGuideDialog.show(
                  context,
                  option: widget.selectedOption,
                  originLat: widget.originLat,
                  originLng: widget.originLng,
                  originAddress: widget.originAddress,
                  destLat: widget.destLat,
                  destLng: widget.destLng,
                  destAddress: widget.destAddress,
                  candidates: widget.candidates,
                );
              },
              icon: const Icon(Icons.format_list_bulleted_rounded, size: 15, color: Color(0xFF60A5FA)),
              label: Text(
                isBn ? 'সব স্টপ গাইড' : 'All Stops Guide',
                style: const TextStyle(color: Color(0xFF93C5FD), fontSize: 11.5, fontWeight: FontWeight.bold),
              ),
            ),
          ElevatedButton.icon(
            onPressed: () {
              PolylineUtils.launchGoogleMapsDirections(
                originLat: widget.originLat,
                originLng: widget.originLng,
                destLat: widget.destLat,
                destLng: widget.destLng,
                stops: widget.selectedOption?.stops,
              );
            },
            icon: const Icon(Icons.open_in_new_rounded, size: 14),
            label: Text(
              isBn ? 'Google Maps-এ দেখুন' : 'Open in Google Maps',
              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isBn ? 'বন্ধ' : 'Close', style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

    Widget _speedButton(double speed, String label) {
    final isSelected = widget.simulationSpeed == speed;
    return InkWell(
      onTap: () {
        if (widget.onSimulationSpeedChange != null) {
          widget.onSimulationSpeedChange!(speed);
        }
      },
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF2563EB)
              : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
              color: isSelected ? const Color(0xFF60A5FA) : Colors.transparent),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontSize: 10.5,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _zoomBtn(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white24),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }

  Widget _dot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600)),
      ],
    );
  }
}
