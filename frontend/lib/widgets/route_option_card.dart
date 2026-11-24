import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ekride_frontend/core/app_strings.dart';
import 'package:ekride_frontend/core/theme.dart';
import 'package:ekride_frontend/models/route_option.dart';
import 'package:ekride_frontend/core/stop_location_resolver.dart';
import 'package:ekride_frontend/services/app_settings_provider.dart';

class RouteOptionCard extends StatelessWidget {
  final RouteOption option;
  final bool isSelected;
  final bool isBest;
  final VoidCallback onSelect;
  final VoidCallback onShowDetails;

  const RouteOptionCard({
    super.key,
    required this.option,
    required this.isSelected,
    this.isBest = false,
    required this.onSelect,
    required this.onShowDetails,
  });

  @override
  Widget build(BuildContext context) {
    final appSettings = context.watch<AppSettingsProvider>();
    final isDark = appSettings.isDarkMode;
    final isBn = appSettings.isBangla;

    final isShared = option.optionId != 'option_direct_solo';
    final hasDetour = option.extraDistanceMeters > 150;
    final breakdown = option.fareBreakdown;

    // Extract student name if shared
    String peerName = '';
    if (isShared) {
      if (option.title.contains('Shared with ')) {
        peerName = option.title.replaceFirst('Shared with ', '').split('(')[0].trim();
      } else {
        peerName = isBn ? 'সহযাত্রী' : 'Student Peer';
      }
    }

    final cardBg = AppTheme.getCardColor(isDark);
    final borderColor = isSelected
        ? AppTheme.primary
        : (isBest ? AppTheme.primary.withValues(alpha: 0.45) : AppTheme.getBorder(isDark));
    final textColor = AppTheme.getTextPrimary(isDark);
    final textSec = AppTheme.getTextSecondary(isDark);
    final textMuted = AppTheme.getTextMuted(isDark);

    final displayTitle = AppStrings.translateTitle(option.title, isBn);
    final displayDescription = AppStrings.translateDescription(option.description, isBn);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: isSelected ? 2.0 : 1.0),
        boxShadow: [
          if (isSelected)
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: isDark ? 0.20 : 0.15),
              blurRadius: 18,
              offset: const Offset(0, 4),
            )
          else if (isBest)
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: isDark ? 0.10 : 0.08),
              blurRadius: 12,
              offset: const Offset(0, 2),
            )
          else if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onSelect,
          borderRadius: BorderRadius.circular(18),
          hoverColor: AppTheme.getCardHover(isDark),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top "BEST VALUE" Banner
                if (isBest)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: AppTheme.bestRouteGradient,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          appSettings.tr('recommended'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Main Header Row: Avatar + Title + Radio
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: isShared ? AppTheme.violetGradient : AppTheme.cyanGradient,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: (isShared ? AppTheme.violet : AppTheme.secondary).withValues(alpha: 0.25),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Center(
                            child: !isShared
                                ? const Icon(Icons.person_rounded, color: Colors.white, size: 22)
                                : (option.riderCount >= 3
                                    ? Row(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.groups_rounded, color: Colors.white, size: 16),
                                          const SizedBox(width: 1),
                                          Text(
                                            '${option.riderCount}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w900,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      )
                                    : Text(
                                        peerName.isNotEmpty ? peerName[0] : 'P',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 18,
                                        ),
                                      )),
                          ),
                        ),
                        if (isShared)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: AppTheme.primary,
                                shape: BoxShape.circle,
                                border: Border.all(color: cardBg, width: 2),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 12),

                    // Title & Badges
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  displayTitle,
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected ? AppTheme.primary : textMuted,
                                    width: isSelected ? 6 : 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),

                          Row(
                            children: [
                              if (isShared && option.estimatedSavings > 0)
                                Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary.withValues(alpha: isDark ? 0.15 : 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.savings_outlined, color: AppTheme.primary, size: 12),
                                      const SizedBox(width: 4),
                                      Text(
                                        appSettings.tr('save_amount', {
                                          'amount': option.estimatedSavings.toStringAsFixed(0),
                                          'percent': option.savingsPercent.toStringAsFixed(0),
                                        }),
                                        style: const TextStyle(
                                          color: AppTheme.primary,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                                decoration: BoxDecoration(
                                  color: AppTheme.getSurfaceLight(isDark),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  !isShared
                                      ? appSettings.tr('private_solo')
                                      : (option.riderCount == 3
                                          ? (isBn ? '৩ জন যাত্রী' : '3 Riders Pool')
                                          : (option.riderCount == 4
                                              ? (isBn ? '৪ জন যাত্রী (ফুল)' : '4 Riders (Full)')
                                              : appSettings.tr('shared_ride'))),
                                  style: TextStyle(
                                    color: option.riderCount >= 3 ? AppTheme.primary : textSec,
                                    fontSize: 10.5,
                                    fontWeight: option.riderCount >= 3 ? FontWeight.w800 : FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Description Container (Translated language-wise!)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.getSurface(isDark).withValues(alpha: isDark ? 0.7 : 0.5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.getBorder(isDark).withValues(alpha: 0.6)),
                  ),
                  child: Text(
                    displayDescription,
                    style: TextStyle(
                      color: textSec,
                      fontSize: 11.5,
                      height: 1.35,
                    ),
                  ),
                ),

                // Detour Split Chip
                if (isShared && hasDetour && breakdown != null && breakdown.detourCostComponent > 0) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withValues(alpha: isDark ? 0.08 : 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.accent.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.call_split_rounded, size: 14, color: AppTheme.accent),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            appSettings.tr('detour_split_text', {
                              'detour': breakdown.detourCostComponent.toStringAsFixed(0),
                              'peer': peerName.isNotEmpty ? peerName : (isBn ? 'সহযাত্রী' : 'Peer'),
                              'peerShare': breakdown.peerDetourShare.toStringAsFixed(0),
                              'userShare': breakdown.userDetourShare.toStringAsFixed(0),
                            }),
                            style: TextStyle(
                              color: isDark ? AppTheme.accentLight : const Color(0xFFB45309),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Curbside Boarding Spot & Passenger Area Chip (Unified with Google Maps Pins)
                if (isShared && option.stops.isNotEmpty) ...[
                  () {
                    final originStop = option.stops.firstWhere((s) => s.type == 'ORIGIN', orElse: () => option.stops.first);
                    final destStop = option.stops.lastWhere((s) => s.type == 'DESTINATION', orElse: () => option.stops.last);
                    final waypoints = StopLocationResolver.resolveGoogleMapsPins(
                      originLat: originStop.lat,
                      originLng: originStop.lng,
                      originAddress: originStop.address,
                      destLat: destStop.lat,
                      destLng: destStop.lng,
                      destAddress: destStop.address,
                      stops: option.stops,
                      isBn: isBn,
                    );
                    final boardingWaypoints = waypoints.where((w) {
                      if (w.isStart) {
                        return w.matchedStops.any((s) => s.type == 'PICKUP');
                      }
                      return w.matchedStops.any((s) => s.type == 'PICKUP');
                    }).toList();
                    if (boardingWaypoints.isEmpty) return const SizedBox.shrink();

                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.12 : 0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ...boardingWaypoints.asMap().entries.map((entry) {
                              final pIdx = entry.key;
                              final pin = entry.value;
                              final letter = pin.isStart ? 'Start' : pin.letter;
                              final peers = pin.matchedStops
                                  .where((s) => s.type == 'PICKUP' && s.passengerName != null && s.passengerName!.isNotEmpty)
                                  .map((s) => s.passengerName!.trim().split(' ').first)
                                  .toList();
                              final peerLabel = peers.isNotEmpty ? peers.join(' & ') : (isBn ? 'সহযাত্রী' : 'Peer');
                              return Padding(
                                padding: EdgeInsets.only(bottom: pIdx < boardingWaypoints.length - 1 ? 5 : 0),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 4.5, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: pin.isStart ? const Color(0xFF3B82F6) : const Color(0xFF10B981),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        letter,
                                        style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w900),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        '$peerLabel: ${pin.exactLandmark}',
                                        style: TextStyle(
                                          color: pin.isStart ? const Color(0xFF60A5FA) : const Color(0xFF10B981),
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w800,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    );
                  }(),
                ],

                const SizedBox(height: 12),
                Divider(color: AppTheme.getBorder(isDark), height: 1),
                const SizedBox(height: 12),

                // Key Metrics Strip (Time, Distance, Detour, Fare)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _metricItem(
                      icon: Icons.timer_outlined,
                      label: appSettings.tr('travel_time'),
                      value: AppStrings.formatDuration(option.totalDurationSeconds, isBn),
                      textMuted: textMuted,
                      textColor: textColor,
                    ),
                    _metricItem(
                      icon: Icons.straighten_rounded,
                      label: appSettings.tr('distance'),
                      value: AppStrings.formatDistance(option.totalDistanceMeters, isBn),
                      textMuted: textMuted,
                      textColor: textColor,
                    ),
                    if (isShared)
                      _metricItem(
                        icon: Icons.alt_route_rounded,
                        label: appSettings.tr('detour'),
                        value: hasDetour
                            ? AppStrings.formatExtraDuration(option.extraDurationSeconds, isBn)
                            : (isBn ? '০ মিনিট' : '0 mins'),
                        valueColor: hasDetour ? AppTheme.accent : textSec,
                        textMuted: textMuted,
                        textColor: textColor,
                      ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (isShared && option.directSoloFare > option.userIndividualFare)
                          Text(
                            '৳${option.directSoloFare.toStringAsFixed(0)}',
                            style: TextStyle(
                              color: textMuted,
                              fontSize: 11,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              appSettings.tr('you_pay'),
                              style: TextStyle(color: textMuted, fontSize: 11),
                            ),
                            Text(
                              '৳${option.userIndividualFare.toStringAsFixed(0)}',
                              style: const TextStyle(
                                color: AppTheme.primary,
                                fontSize: 19,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Footer: Seats indicator + View Breakdown Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.airline_seat_recline_normal_rounded, size: 14, color: textMuted),
                        const SizedBox(width: 4),
                        Text(
                          appSettings.tr('seats_left', {
                            'count': '${option.availableSeats}',
                            's': option.availableSeats > 1 ? 's' : '',
                          }),
                          style: TextStyle(color: textMuted, fontSize: 11, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    InkWell(
                      onTap: onShowDetails,
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.receipt_long_rounded, size: 13, color: AppTheme.secondary),
                            const SizedBox(width: 4),
                            Text(
                              appSettings.tr('fare_details'),
                              style: const TextStyle(color: AppTheme.secondary, fontSize: 11.5, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _metricItem({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    required Color textMuted,
    required Color textColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: textMuted),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(color: textMuted, fontSize: 10.5)),
          ],
        ),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(color: valueColor ?? textColor, fontSize: 13, fontWeight: FontWeight.w800)),
      ],
    );
  }
}
