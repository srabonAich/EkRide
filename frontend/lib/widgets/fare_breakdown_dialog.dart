import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ekride_frontend/core/theme.dart';
import 'package:ekride_frontend/models/route_option.dart';
import 'package:ekride_frontend/core/stop_location_resolver.dart';
import 'package:ekride_frontend/services/app_settings_provider.dart';

class FareBreakdownDialog extends StatelessWidget {
  final RouteOption option;

  const FareBreakdownDialog({super.key, required this.option});

  @override
  Widget build(BuildContext context) {
    final appSettings = context.watch<AppSettingsProvider>();
    final isDark = appSettings.isDarkMode;

    final breakdown = option.fareBreakdown;
    final hasDetour = breakdown != null && breakdown.detourCostComponent > 0;

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
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: isDark ? 0.15 : 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.verified_user_rounded, color: AppTheme.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appSettings.tr('transparent_fare'),
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          appSettings.tr('transparent_subtitle'),
                          style: TextStyle(color: textMuted, fontSize: 11.5),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close_rounded, color: textSecondary, size: 20),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              if (breakdown != null) ...[
                // Meter Fare Breakdown Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    children: [
                      _feeRow(
                        appSettings.tr('total_meter_fare'),
                        '৳${breakdown.totalVehicleFare.toStringAsFixed(2)}',
                        isBold: true,
                        valueColor: AppTheme.primary,
                        fontSize: 15,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                      ),
                      const SizedBox(height: 10),
                      Divider(color: borderColor, height: 1),
                      const SizedBox(height: 10),
                      _feeRow(appSettings.tr('base_tariff'), '৳${breakdown.baseFareComponent.toStringAsFixed(2)}', textPrimary: textPrimary, textSecondary: textSecondary),
                      const SizedBox(height: 7),
                      _feeRow(appSettings.tr('distance_rate'), '৳${breakdown.distanceFareComponent.toStringAsFixed(2)}', textPrimary: textPrimary, textSecondary: textSecondary),
                      const SizedBox(height: 7),
                      _feeRow(appSettings.tr('trip_duration'), '${option.durationFormatted} ${appSettings.tr("time_fee_note")}', valueColor: textMuted, textPrimary: textPrimary, textSecondary: textSecondary),
                      const SizedBox(height: 7),
                      _feeRow(appSettings.tr('platform_fee'), '৳${breakdown.platformFee.toStringAsFixed(2)}', textPrimary: textPrimary, textSecondary: textSecondary),
                      const SizedBox(height: 7),
                      _feeRow(appSettings.tr('driver_earnings'), '৳${breakdown.driverEarnings.toStringAsFixed(2)}', valueColor: AppTheme.secondary, textPrimary: textPrimary, textSecondary: textSecondary),
                    ],
                  ),
                ),

                // Detour Split Visual Card (When Detour exists)
                if (hasDetour) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withValues(alpha: isDark ? 0.08 : 0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.accent.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.alt_route_rounded, color: AppTheme.accent, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  appSettings.tr('detour_fare_label', {'extra': option.extraDistanceFormatted}),
                                  style: TextStyle(
                                    color: textPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '৳${breakdown.detourCostComponent.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: AppTheme.accent,
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Visual Detour 60/40 Split Bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: SizedBox(
                            height: 8,
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 60,
                                  child: Container(color: AppTheme.accent),
                                ),
                                const SizedBox(width: 2),
                                Expanded(
                                  flex: 40,
                                  child: Container(color: AppTheme.primary),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        _feeRow(appSettings.tr('peer_detour_share'), '৳${breakdown.peerDetourShare.toStringAsFixed(2)}', valueColor: isDark ? AppTheme.accentLight : const Color(0xFFB45309), textPrimary: textPrimary, textSecondary: textSecondary),
                        const SizedBox(height: 4),
                        _feeRow(appSettings.tr('user_detour_share'), '৳${breakdown.userDetourShare.toStringAsFixed(2)}', valueColor: AppTheme.primary, textPrimary: textPrimary, textSecondary: textSecondary),
                        const SizedBox(height: 6),
                        Text(
                          appSettings.tr('detour_policy_note'),
                          style: TextStyle(color: textMuted, fontSize: 11, fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // Individual Student Shares
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      appSettings.tr('student_shares'),
                      style: TextStyle(color: textPrimary, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      appSettings.tr('reconciled_100'),
                      style: const TextStyle(color: AppTheme.primary, fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                ...breakdown.passengerShares.map((p) {
                  final displayName = (p.passengerName == 'Current Passenger' || p.passengerName == 'Primary Passenger')
                      ? (appSettings.isBangla ? 'আপনি (মূল যাত্রী)' : 'You (Primary Rider)')
                      : p.passengerName;
                  final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : '👤';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.getSurfaceLight(isDark),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: borderColor),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            gradient: AppTheme.violetGradient,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              initial,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayName,
                                style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 13.5),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                appSettings.tr('solo_was', {'amount': p.directSoloFare.toStringAsFixed(0)}),
                                style: TextStyle(color: textMuted, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '৳${p.individualFare.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                              ),
                            ),
                            if (p.savings > 0)
                              Text(
                                appSettings.tr('save_amount', {
                                  'amount': p.savings.toStringAsFixed(0),
                                  'percent': p.savingsPercent.toStringAsFixed(0),
                                }),
                                style: const TextStyle(
                                  color: AppTheme.accent,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
              ],

              // Stops & Boarding Points Section
              if (option.stops.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  appSettings.isBangla ? 'পিকআপ ও ড্রপঅফের নির্দিষ্ট স্পটসমূহ:' : 'Boarding & Dropoff Spots:',
                  style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 8),
                ...option.stops.map((s) {
                  final details = StopLocationResolver.resolve(s, isBn: appSettings.isBangla);
                  final isPickup = s.type == 'PICKUP';
                  final isDropoff = s.type == 'DROPOFF';
                  final isOrigin = s.type == 'ORIGIN';
                  final color = isOrigin
                      ? const Color(0xFF3B82F6)
                      : (isPickup
                          ? const Color(0xFF10B981)
                          : (isDropoff ? const Color(0xFFF59E0B) : const Color(0xFFEF4444)));
                  final title = isOrigin
                      ? (appSettings.isBangla ? 'আপনার পিকআপ' : 'Your Pickup')
                      : (isPickup
                          ? (appSettings.isBangla ? '${s.passengerName} উঠবে' : 'Pickup: ${s.passengerName}')
                          : (isDropoff
                              ? (appSettings.isBangla ? '${s.passengerName} নামবে' : 'Dropoff: ${s.passengerName}')
                              : (appSettings.isBangla ? 'আপনার শেষ গন্তব্য' : 'Your Destination')));
                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: isDark ? 0.10 : 0.06),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: color.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.pin_drop_rounded, size: 14, color: color),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$title: ${details.exactLandmark}',
                                style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11),
                              ),
                              if (isPickup || isDropoff) ...[
                                const SizedBox(height: 1),
                                Text(
                                  '${appSettings.isBangla ? "মূল এলাকা: " : "Area: "}${details.passengerHomeArea} • ${details.walkingGuide}',
                                  style: TextStyle(color: textMuted, fontSize: 10),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],

              const SizedBox(height: 20),

              // Close Button
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.getSurfaceLight(isDark),
                    foregroundColor: textPrimary,
                    elevation: 0,
                    side: BorderSide(color: borderColor),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(appSettings.tr('close_breakdown'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _feeRow(
    String label,
    String value, {
    bool isBold = false,
    Color? valueColor,
    double fontSize = 12.5,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isBold ? textPrimary : textSecondary,
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? (isBold ? textPrimary : textSecondary),
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
