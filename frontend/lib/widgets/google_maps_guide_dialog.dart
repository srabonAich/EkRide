import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:ekride_frontend/core/app_strings.dart';
import 'package:ekride_frontend/core/polyline_utils.dart';
import 'package:ekride_frontend/core/stop_location_resolver.dart';
import 'package:ekride_frontend/core/theme.dart';
import 'package:ekride_frontend/models/candidate.dart';
import 'package:ekride_frontend/models/route_option.dart';
import 'package:ekride_frontend/models/stop.dart';
import 'package:ekride_frontend/services/app_settings_provider.dart';

class GoogleMapsGuideDialog extends StatelessWidget {
  final RouteOption? option;
  final double originLat;
  final double originLng;
  final String originAddress;
  final double destLat;
  final double destLng;
  final String destAddress;
  final List<CandidatePassenger>? candidates;

  const GoogleMapsGuideDialog({
    super.key,
    this.option,
    required this.originLat,
    required this.originLng,
    required this.originAddress,
    required this.destLat,
    required this.destLng,
    required this.destAddress,
    this.candidates,
  });

  static Future<void> show(
    BuildContext context, {
    RouteOption? option,
    required double originLat,
    required double originLng,
    required String originAddress,
    required double destLat,
    required double destLng,
    required String destAddress,
    List<CandidatePassenger>? candidates,
  }) {
    return showDialog(
      context: context,
      builder: (context) => GoogleMapsGuideDialog(
        option: option,
        originLat: originLat,
        originLng: originLng,
        originAddress: originAddress,
        destLat: destLat,
        destLng: destLng,
        destAddress: destAddress,
        candidates: candidates,
      ),
    );
  }

  List<RouteStop> _getOrderedStops() {
    if (option != null && option!.stops.isNotEmpty) {
      final list = List<RouteStop>.from(option!.stops);
      list.sort((a, b) => a.order.compareTo(b.order));
      return list;
    }
    return [
      RouteStop(
        order: 1,
        type: "ORIGIN",
        lat: originLat,
        lng: originLng,
        address: originAddress.isNotEmpty ? originAddress : "Pickup Location",
      ),
      RouteStop(
        order: 2,
        type: "DESTINATION",
        lat: destLat,
        lng: destLng,
        address: destAddress.isNotEmpty ? destAddress : "Destination Location",
      ),
    ];
  }

  String _buildCopySummary(List<GoogleMapsWaypointPin> waypoints, bool isBn) {
    final buffer = StringBuffer();
    buffer.writeln(isBn
        ? "📍 EkRide - গুগল ম্যাপসের পয়েন্ট গাইড (Start, A, B, C, D):"
        : "📍 EkRide - Google Maps Stop Pins Guide (Start, A, B, C, D):");
    for (int i = 0; i < waypoints.length; i++) {
      final pin = waypoints[i];
      final prefix = pin.isStart
          ? (isBn ? "• শুরুর পয়েন্ট (Start)" : "• Starting Point (Start)")
          : (isBn ? "• গুগল ম্যাপস স্টপ (${pin.letter})" : "• Google Maps Stop (${pin.letter})");
      buffer.writeln("$prefix: ${pin.roleText}");
      buffer.writeln(isBn ? "  • সরাসরি স্পট: ${pin.exactLandmark}" : "  • Exact Spot: ${pin.exactLandmark}");
      if (pin.mainArea.isNotEmpty) {
        buffer.writeln(isBn ? "  • মূল এলাকা: ${pin.mainArea}" : "  • Main Area: ${pin.mainArea}");
      }
      if (pin.walkingGuide.isNotEmpty) {
        buffer.writeln("  • ${pin.walkingGuide}");
      }
      buffer.writeln();
    }
    return buffer.toString().trim();
  }

  @override
  Widget build(BuildContext context) {
    final appSettings = context.watch<AppSettingsProvider>();
    final isDark = appSettings.isDarkMode;
    final isBn = appSettings.isBangla;

    final orderedStops = _getOrderedStops();
    final waypoints = StopLocationResolver.resolveGoogleMapsPins(
      originLat: originLat,
      originLng: originLng,
      originAddress: originAddress,
      destLat: destLat,
      destLng: destLng,
      destAddress: destAddress,
      stops: orderedStops,
      candidates: candidates,
      isBn: isBn,
    );

    final surfaceBg = AppTheme.getSurface(isDark);
    final cardBg = AppTheme.getCardColor(isDark);
    final borderColor = AppTheme.getBorder(isDark);
    final textPrimary = AppTheme.getTextPrimary(isDark);
    final textSecondary = AppTheme.getTextSecondary(isDark);
    final textMuted = AppTheme.getTextMuted(isDark);

    return Dialog(
      backgroundColor: surfaceBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: borderColor, width: 1.5),
      ),
      child: Container(
        padding: const EdgeInsets.all(22),
        constraints: const BoxConstraints(maxWidth: 540),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1D4ED8), Color(0xFF2563EB)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2563EB).withValues(alpha: 0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.map_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isBn
                              ? "গুগল ম্যাপস স্টপ গাইড (A, B, C, D)"
                              : "Google Maps Stops Guide (A, B, C, D)",
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 16.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          isBn
                              ? "গুগল ম্যাপসের পিন অনুযায়ী সরাসরি স্পট ও যাত্রীর অবস্থান:"
                              : "Match Google Maps pins with exact boarding spots & home areas:",
                          style: TextStyle(
                            color: textMuted,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                    color: textMuted,
                    tooltip: isBn ? "বন্ধ করুন" : "Close",
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Route Title Summary Card
              if (option != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.directions_car_rounded, color: Color(0xFF3B82F6), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          AppStrings.translateTitle(option!.title, isBn),
                          style: TextStyle(
                            color: textPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          option!.durationFormatted,
                          style: const TextStyle(
                            color: Color(0xFF10B981),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // Notice Banner explaining Google Maps A, B, C letters
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withValues(alpha: isDark ? 0.12 : 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF60A5FA), size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isBn
                            ? "গুগল ম্যাপসে দেখানো Start, A, B, C, D পিন ও সরাসরি স্পটের বিবরণ নিচে দেখুন:"
                            : "Match Start, A, B, C, D pins in Google Maps with direct boarding spots below:",
                        style: TextStyle(
                          color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1E40AF),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Stops Timeline matching Google Maps navigation 100%
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: waypoints.length,
                separatorBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.only(left: 17),
                  child: Container(
                    width: 2,
                    height: 14,
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                  ),
                ),
                itemBuilder: (context, index) {
                  final pin = waypoints[index];
                  final isStart = pin.isStart;
                  final isFinalDest = pin.isFinalDest;
                  final letter = pin.letter;
                  final stopColor = pin.pinColor;
                  final stopIcon = pin.pinIcon;
                  final roleText = pin.roleText;
                  final exactLandmark = pin.exactLandmark;
                  final mainArea = pin.mainArea;
                  final walkingGuide = pin.walkingGuide;

                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: stopColor.withValues(alpha: 0.40),
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Google Maps Circular Pin Badge matching the app
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [stopColor, stopColor.withValues(alpha: 0.85)],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: stopColor.withValues(alpha: 0.40),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: isStart
                              ? const Icon(Icons.trip_origin_rounded, color: Colors.white, size: 20)
                              : Text(
                                  letter,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                        ),
                        const SizedBox(width: 12),

                        // Stop Action Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Top Title Row
                              Row(
                                children: [
                                  Icon(stopIcon, color: stopColor, size: 16),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      roleText,
                                      style: TextStyle(
                                        color: stopColor,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 13.5,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                    decoration: BoxDecoration(
                                      color: stopColor.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: stopColor.withValues(alpha: 0.3)),
                                    ),
                                    child: Text(
                                      pin.pinBadge,
                                      style: TextStyle(
                                        color: stopColor,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 7),

                              // Exact Google Maps Direct Spot Card
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                decoration: BoxDecoration(
                                  color: stopColor.withValues(alpha: isDark ? 0.14 : 0.08),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: stopColor.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.pin_drop_rounded, color: stopColor, size: 16),
                                    const SizedBox(width: 7),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            isStart
                                                ? (isBn ? "সরাসরি পিকআপ স্পট (Google Maps Start):" : "Exact Pickup Spot (Google Maps Start):")
                                                : (isFinalDest
                                                    ? (isBn ? "শেষ গন্তব্য স্পট (Google Maps Pin $letter):" : "Final Destination Spot (Google Maps Pin $letter):")
                                                    : (pin.matchedStops.any((s) => s.type == "PICKUP")
                                                        ? (isBn ? "সরাসরি উঠার নির্দিষ্ট স্পট (Google Maps Pin $letter):" : "Exact Boarding Spot (Google Maps Pin $letter):")
                                                        : (isBn ? "সরাসরি ড্রপঅফ স্পট (Google Maps Pin $letter):" : "Exact Dropoff Spot (Google Maps Pin $letter):"))),
                                            style: TextStyle(
                                              color: stopColor,
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            exactLandmark,
                                            style: TextStyle(
                                              color: textPrimary,
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Original Area / Home Area Row
                              if (mainArea.isNotEmpty) ...[
                                const SizedBox(height: 5),
                                Row(
                                  children: [
                                    Icon(
                                      isFinalDest ? Icons.flag_outlined : Icons.home_work_outlined,
                                      color: textMuted,
                                      size: 13,
                                    ),
                                    const SizedBox(width: 5),
                                    Expanded(
                                      child: Text(
                                        "${isFinalDest ? (isBn ? "মূল গন্তব্য: " : "Main Destination: ") : (isBn ? "মূল এলাকা: " : "Main Area: ")}$mainArea",
                                        style: TextStyle(
                                          color: textSecondary,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],

                              // Walking / Detour Guide Row
                              if (walkingGuide.isNotEmpty) ...[
                                const SizedBox(height: 5),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.getSurfaceLight(isDark),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        walkingGuide.contains("🚶") ? Icons.directions_walk_rounded : Icons.check_circle_rounded,
                                        color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
                                        size: 13,
                                      ),
                                      const SizedBox(width: 5),
                                      Expanded(
                                        child: Text(
                                          walkingGuide,
                                          style: TextStyle(
                                            color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1E40AF),
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 18),

              // Action Buttons Row: Copy Guide + Open in Google Maps
              Row(
                children: [
                  // Copy Guide Button
                  Expanded(
                    flex: 4,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        final summary = _buildCopySummary(waypoints, isBn);
                        Clipboard.setData(ClipboardData(text: summary));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  isBn ? "গুগল ম্যাপস স্টপ গাইড কপি করা হয়েছে!" : "Google Maps stops guide copied!",
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            backgroundColor: const Color(0xFF059669),
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy_rounded, size: 16),
                      label: Text(
                        isBn ? "গাইড কপি করুন" : "Copy Guide",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: textPrimary,
                        side: BorderSide(color: borderColor, width: 1.2),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Open in Google Maps Button
                  Expanded(
                    flex: 6,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1D4ED8), Color(0xFF2563EB)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2563EB).withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: () {
                          PolylineUtils.launchGoogleMapsDirections(
                            originLat: originLat,
                            originLng: originLng,
                            destLat: destLat,
                            destLng: destLng,
                            stops: option?.stops,
                          );
                        },
                        icon: const Icon(Icons.open_in_new_rounded, size: 18, color: Colors.white),
                        label: Text(
                          isBn ? "গুগল ম্যাপসে খুলুন" : "Open in Google Maps",
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
