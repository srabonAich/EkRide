import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ekride_frontend/core/theme.dart';
import 'package:ekride_frontend/services/app_settings_provider.dart';
import 'package:ekride_frontend/services/auth_provider.dart';
import 'package:ekride_frontend/services/ride_provider.dart';
import 'package:ekride_frontend/widgets/interactive_map_view.dart';
import 'package:ekride_frontend/widgets/route_option_card.dart';
import 'package:ekride_frontend/widgets/fare_breakdown_dialog.dart';
import 'package:ekride_frontend/screens/my_bookings_screen.dart';
import 'package:ekride_frontend/screens/profile_screen.dart';
import 'package:ekride_frontend/screens/driver_screen.dart';
import 'package:ekride_frontend/models/candidate.dart';
import 'package:ekride_frontend/models/stop.dart';
import 'package:ekride_frontend/core/stop_location_resolver.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final TextEditingController _originSearchController = TextEditingController();
  final TextEditingController _destSearchController = TextEditingController();
  Widget _buildCompatiblePassengerCard({
    required BuildContext context,
    required CandidatePassenger candidate,
    required bool isSelected,
    required bool canSelectMore,
    required bool isDark,
    required bool isBn,
    required Color cardBg,
    required Color border,
    required Color textPrimary,
    required Color textSec,
    required Color textMuted,
    required VoidCallback onToggle,
  }) {
    final firstName = candidate.passengerName.trim().split(' ').first;
    final initial = firstName.isNotEmpty ? firstName[0].toUpperCase() : '👤';
    final pickupStop = RouteStop(order: 2, type: 'PICKUP', lat: candidate.pickupLat, lng: candidate.pickupLng, address: candidate.pickupAddress, passengerName: candidate.passengerName);
    final pickupDetails = StopLocationResolver.resolve(pickupStop, isBn: isBn);

    return Container(
      margin: const EdgeInsets.only(bottom: 11),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? const Color(0xFF2563EB)
              : (canSelectMore ? border : border.withValues(alpha: 0.45)),
          width: isSelected ? 2.0 : 1.0,
        ),
        boxShadow: [
          if (isSelected)
            BoxShadow(
              color: const Color(0xFF2563EB).withValues(alpha: isDark ? 0.22 : 0.15),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: (isSelected || canSelectMore) ? onToggle : null,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(13),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Avatar, Name + University, Star Rating & Action Button
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)])
                            : const LinearGradient(colors: [Color(0xFF0F766E), Color(0xFF0D9488)]),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? const Color(0xFF60A5FA) : Colors.white,
                          width: 1.8,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          initial,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  candidate.passengerName,
                                  style: TextStyle(
                                    color: textPrimary,
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4.5, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F172A),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFFF59E0B), width: 1.0),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 10),
                                    const SizedBox(width: 2),
                                    Text(
                                      candidate.rating.toStringAsFixed(1),
                                      style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            candidate.university,
                            style: TextStyle(color: textSec, fontSize: 11, fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Action Toggle / Button
                    if (isSelected)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF10B981), width: 1.2),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 14),
                            const SizedBox(width: 4),
                            Text(
                              isBn ? 'পুলে আছে' : 'In Pool',
                              style: const TextStyle(color: Color(0xFF10B981), fontSize: 11.5, fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                      )
                    else if (canSelectMore)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6.5),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)]),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2563EB).withValues(alpha: 0.35),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.add_rounded, color: Colors.white, size: 14),
                            const SizedBox(width: 3),
                            Text(
                              isBn ? 'পুলে নিন' : 'Add to Pool',
                              style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5.5),
                        decoration: BoxDecoration(
                          color: AppTheme.getSurfaceLight(isDark),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: border.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          isBn ? 'সিট পূর্ণ' : 'Seats Full',
                          style: TextStyle(color: textMuted, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 10),

                // Middle: Route Details (Pickup + Dropoff Chips)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppTheme.getSurfaceLight(isDark).withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.circle_rounded, size: 8, color: Color(0xFF10B981)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '${isBn ? "পিকআপ স্পট: " : "Pickup: "}${pickupDetails.exactLandmark}',
                              style: TextStyle(color: textPrimary, fontSize: 11, fontWeight: FontWeight.w700),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(Icons.circle_rounded, size: 8, color: Color(0xFFF59E0B)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '${isBn ? "ড্রপঅফ: " : "Dropoff: "}${candidate.dropoffAddress}',
                              style: TextStyle(color: textSec, fontSize: 10.5, fontWeight: FontWeight.w500),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ride = context.read<RideProvider>();
      _originSearchController.text = ride.originAddress;
      _destSearchController.text = ride.destAddress;
      ride.fetchNearbyAndOptions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final ride = context.watch<RideProvider>();
    final appSettings = context.watch<AppSettingsProvider>();

    final isDark = appSettings.isDarkMode;
    final isBn = appSettings.isBangla;

    final bg = AppTheme.getBackground(isDark);
    final surface = AppTheme.getSurface(isDark);
    final border = AppTheme.getBorder(isDark);
    final textPrimary = AppTheme.getTextPrimary(isDark);
    final textMuted = AppTheme.getTextMuted(isDark);
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 920;

    // Sync input controllers if state changed externally
    if (_originSearchController.text != ride.originAddress && ride.activeSearchTarget != 'origin') {
      _originSearchController.text = ride.originAddress;
    }
    if (_destSearchController.text != ride.destAddress && ride.activeSearchTarget != 'destination') {
      _destSearchController.text = ride.destAddress;
    }

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        toolbarHeight: 64,
        backgroundColor: surface,
        elevation: 0,
        title: Row(
          children: [
            // EkRide Logo Badge
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.directions_car_filled_rounded, color: Colors.black, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      isBn ? 'একরাইড' : 'EkRide',
                      style: TextStyle(color: textPrimary, fontWeight: FontWeight.w900, fontSize: 19, letterSpacing: -0.5),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isBn ? 'EkRide' : 'Campus Commute',
                      style: const TextStyle(color: AppTheme.primaryLight, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: AppTheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '${auth.currentUser?.university ?? appSettings.tr("campus_network")} • ${appSettings.tr("live_corridor")}',
                      style: TextStyle(color: textMuted, fontSize: 10.5, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          // 1. Language Switcher (EN | বাং)
          InkWell(
            onTap: () => appSettings.toggleLanguage(),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.getSurfaceLight(isDark),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: border),
              ),
              child: Row(
                children: [
                  Text(
                    isBn ? '🇧🇩 বাং' : '🇬🇧 EN',
                    style: TextStyle(
                      color: textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),

          // 2. Theme Switcher (Dark / Light)
          IconButton(
            tooltip: isDark ? appSettings.tr('theme_light') : appSettings.tr('theme_dark'),
            icon: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              color: isDark ? AppTheme.accent : AppTheme.violet,
              size: 20,
            ),
            onPressed: () => appSettings.toggleTheme(),
          ),
          const SizedBox(width: 4),

          // 3. My Rides Navigation
          TextButton.icon(
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MyBookingsScreen()));
            },
            style: TextButton.styleFrom(
              backgroundColor: AppTheme.getSurfaceLight(isDark),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.confirmation_number_outlined, color: AppTheme.primaryLight, size: 16),
            label: Text(
              appSettings.tr('my_rides'),
              style: TextStyle(color: textPrimary, fontWeight: FontWeight.w700, fontSize: 12.5),
            ),
          ),
          const SizedBox(width: 8),

          // 4. Driver Hub Button (if role is DRIVER)
          if (auth.currentUser?.role == 'DRIVER') ...[
            TextButton.icon(
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DriverScreen()));
              },
              style: TextButton.styleFrom(
                backgroundColor: AppTheme.secondary.withValues(alpha: 0.15),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.drive_eta_rounded, color: AppTheme.secondary, size: 16),
              label: Text(
                appSettings.tr('driver_hub'),
                style: const TextStyle(color: AppTheme.secondary, fontWeight: FontWeight.w700, fontSize: 12.5),
              ),
            ),
            const SizedBox(width: 8),
          ],

          // 5. User Profile Avatar
          InkWell(
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppTheme.getSurfaceLight(isDark),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: border),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: AppTheme.violet.withValues(alpha: 0.25),
                    child: Text(
                      auth.currentUser?.fullName.isNotEmpty == true ? auth.currentUser!.fullName[0] : 'U',
                      style: const TextStyle(color: AppTheme.violetLight, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 7),
                  Text(
                    auth.currentUser?.fullName.split(' ').first ?? 'Student',
                    style: TextStyle(color: textPrimary, fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 4),

          // 6. Logout
          IconButton(
            tooltip: isBn ? 'লগআউট' : 'Sign Out',
            icon: const Icon(Icons.logout_rounded, color: AppTheme.danger, size: 18),
            onPressed: () => auth.logout(),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: isDesktop
          ? Row(
              children: [
                // Left Panel: Commute Planner & Route Options (470px)
                SizedBox(
                  width: 470,
                  child: _buildControlsPanel(context, ride, appSettings),
                ),
                // Right Panel: Interactive Street Map
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 14, 16, 16),
                    child: _buildMapArea(ride, isDark, isBn),
                  ),
                ),
              ],
            )
          : Column(
              children: [
                // Narrow Screen: Map top (320px), controls below
                SizedBox(
                  height: 320,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: _buildMapArea(ride, isDark, isBn),
                  ),
                ),
                Expanded(
                  child: _buildControlsPanel(context, ride, appSettings),
                ),
              ],
            ),
    );
  }

  Widget _buildMapArea(RideProvider ride, bool isDark, bool isBn) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.getBorder(isDark), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: InteractiveMapView(
        originLat: ride.originLat,
        originLng: ride.originLng,
        originAddress: ride.originAddress,
        destLat: ride.destLat,
        destLng: ride.destLng,
        destAddress: ride.destAddress,
        selectedOption: ride.selectedOption,
        candidates: ride.nearbyCandidates,
        driverLat: ride.isSimulating ? ride.driverLat : null,
        driverLng: ride.isSimulating ? ride.driverLng : null,
        driverBearing: ride.driverBearing,
        driverSpeedKmh: ride.driverSpeedKmh,
        remainingDistanceKm: ride.remainingDistanceKm,
        remainingDurationSeconds: ride.remainingDurationSeconds,
        tripProgress: ride.tripProgress,
        trackingStatus: isBn ? ride.trackingStatusBn : ride.trackingStatus,
        isSimulating: ride.isSimulating,
        isSimulationPaused: ride.isSimulationPaused,
        simulationSpeed: ride.simulationSpeed,
        onToggleSimulationPause: () => ride.toggleSimulationPause(),
        onSimulationSpeedChange: (s) => ride.setSimulationSpeed(s),
        onRestartSimulation: () => ride.restartSimulation(),
        onStopSimulation: () => ride.stopLiveTrackingSimulation(),
        onStartSimulation: () => ride.startLiveTrackingSimulation(ride.selectedOption),
        mapPinMode: ride.mapPinMode,
        onMapTap: (lat, lng) {
          ride.setPointFromMapTap(lat, lng);
          if (_originSearchController.text != ride.originAddress) {
            _originSearchController.text = ride.originAddress;
          }
          if (_destSearchController.text != ride.destAddress) {
            _destSearchController.text = ride.destAddress;
          }
        },
      ),
    );
  }

  Widget _buildControlsPanel(BuildContext context, RideProvider ride, AppSettingsProvider appSettings) {
    final isDark = appSettings.isDarkMode;
    final isBn = appSettings.isBangla;
    final surface = AppTheme.getSurface(isDark);
    final cardBg = AppTheme.getCardColor(isDark);
    final border = AppTheme.getBorder(isDark);
    final textPrimary = AppTheme.getTextPrimary(isDark);
    final textMuted = AppTheme.getTextMuted(isDark);
    final textSec = isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569);

    return Container(
      decoration: BoxDecoration(
        color: surface,
        border: Border(right: BorderSide(color: border, width: 1)),
      ),
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          // Commute Planning Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.26 : 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.route_rounded, color: AppTheme.primary, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          appSettings.tr('plan_commute'),
                          style: TextStyle(color: textPrimary, fontWeight: FontWeight.w800, fontSize: 14.5),
                        ),
                      ],
                    ),
                    if (ride.isLoading)
                      const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary))
                    else
                      InkWell(
                        onTap: () => ride.fetchNearbyAndOptions(),
                        borderRadius: BorderRadius.circular(6),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.refresh_rounded, size: 13, color: textMuted),
                              const SizedBox(width: 4),
                              Text(appSettings.tr('refresh'), style: TextStyle(color: textMuted, fontSize: 11)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),

                // Connected Route Inputs (From -> To with Swap button)
                Stack(
                  alignment: Alignment.centerRight,
                  children: [
                    Column(
                      children: [
                        // 1. Pickup Input (Origin)
                        _buildSearchInput(
                          controller: _originSearchController,
                          target: 'origin',
                          icon: Icons.trip_origin_rounded,
                          iconColor: AppTheme.primary,
                          label: appSettings.tr('from_pickup'),
                          hint: appSettings.tr('pickup_hint'),
                          isPinning: ride.mapPinMode == 'origin',
                          onPinTap: () {
                            ride.setMapPinMode(ride.mapPinMode == 'origin' ? 'none' : 'origin');
                          },
                          ride: ride,
                          appSettings: appSettings,
                        ),

                        // Autocomplete dropdown directly under Pickup
                        if (ride.activeSearchTarget == 'origin' && ride.autocompletePredictions.isNotEmpty)
                          _buildSuggestionsList(ride, 'origin', appSettings),

                        const SizedBox(height: 10),

                        // 2. Destination Input
                        _buildSearchInput(
                          controller: _destSearchController,
                          target: 'destination',
                          icon: Icons.location_on_rounded,
                          iconColor: AppTheme.secondary,
                          label: appSettings.tr('to_dropoff'),
                          hint: appSettings.tr('dropoff_hint'),
                          isPinning: ride.mapPinMode == 'destination',
                          onPinTap: () {
                            ride.setMapPinMode(ride.mapPinMode == 'destination' ? 'none' : 'destination');
                          },
                          ride: ride,
                          appSettings: appSettings,
                        ),

                        // Autocomplete dropdown directly under Destination
                        if (ride.activeSearchTarget == 'destination' && ride.autocompletePredictions.isNotEmpty)
                          _buildSuggestionsList(ride, 'destination', appSettings),
                      ],
                    ),

                    // Floating Swap Button
                    Positioned(
                      right: 48,
                      child: Tooltip(
                        message: appSettings.tr('swap_locations'),
                        child: InkWell(
                          onTap: () {
                            ride.swapOriginAndDestination();
                            _originSearchController.text = ride.originAddress;
                            _destSearchController.text = ride.destAddress;
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppTheme.getSurfaceLight(isDark),
                              shape: BoxShape.circle,
                              border: Border.all(color: AppTheme.primary.withValues(alpha: 0.5)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.15),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.swap_vert_rounded, color: AppTheme.primary, size: 18),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Quick Campus Corridor Shortcuts
                Row(
                  children: [
                    const Icon(Icons.bolt_rounded, size: 14, color: AppTheme.accent),
                    const SizedBox(width: 4),
                    Text(
                      appSettings.tr('tap_campus_corridors'),
                      style: TextStyle(color: textMuted, fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _campusPill(isBn ? '🏛️ ঢাবি → বনানী ১১' : '🏛️ DU → Banani 11', 23.7328, 90.3957, 'TSC, University of Dhaka', 23.7937, 90.4066, 'Road 11, Banani, Dhaka', ride, isDark),
                      const SizedBox(width: 8),
                      _campusPill(isBn ? '🎓 ব্র্যাক → ধানমন্ডি' : '🎓 BRAC → Dhanmondi', 23.7716, 90.4253, 'BRAC University New Campus', 23.7465, 90.3760, 'Dhanmondi 32, Dhaka', ride, isDark),
                      const SizedBox(width: 8),
                      _campusPill(isBn ? '🏢 এনএসইউ → শাহবাগ' : '🏢 NSU → Shahbagh', 23.8151, 90.4255, 'North South University (NSU)', 23.7380, 90.3950, 'Shahbagh, Dhaka', ride, isDark),
                      const SizedBox(width: 8),
                      _campusPill(isBn ? '⚡ বুয়েট → উত্তরা' : '⚡ BUET → Uttara', 23.7265, 90.3888, 'Palashi Campus, BUET', 23.8759, 90.3795, 'Sector 7, Uttara, Dhaka', ride, isDark),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 1. Vehicle Capacity / Car Limit Selector
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: border),
            ),
            child: Row(
              children: [
                Row(
                  children: [
                    const Icon(Icons.airline_seat_recline_normal_rounded, color: AppTheme.primary, size: 20),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isBn ? 'গাড়ির সিট সংখ্যা (Car Limit)' : 'Car Seat Limit',
                          style: TextStyle(color: textPrimary, fontSize: 13, fontWeight: FontWeight.w800),
                        ),
                        Text(
                          isBn
                              ? '${ride.selectedPassengerRideIds.length}/${ride.maxAllowedPeers} জন সহযাত্রী যুক্ত (${ride.remainingSeats == 0 ? "সিট পূর্ণ" : "${ride.remainingSeats}টি খালি"})'
                              : '${ride.selectedPassengerRideIds.length}/${ride.maxAllowedPeers} Peers in Carpool (${ride.remainingSeats == 0 ? "Full" : "${ride.remainingSeats} left"})',
                          style: TextStyle(
                            color: ride.remainingSeats == 0 ? const Color(0xFF10B981) : AppTheme.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const Spacer(),
                // Seat Option Pills [ 2 | 3 | 4 ]
                Row(
                  children: [2, 3, 4].map((capacity) {
                    final isSelected = ride.carCapacity == capacity;
                    return Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: InkWell(
                        onTap: () => ride.setCarCapacity(capacity),
                        borderRadius: BorderRadius.circular(10),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: isSelected ? AppTheme.primaryGradient : null,
                            color: isSelected ? null : AppTheme.getSurfaceLight(isDark),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected ? AppTheme.primary : border,
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Text(
                            isBn ? '$capacity সিট' : '$capacity Seats',
                            style: TextStyle(
                              color: isSelected ? Colors.black : textPrimary,
                              fontSize: 11.5,
                              fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // 2. Compatible Nearby Passengers List (The People!)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.people_alt_rounded, color: AppTheme.secondary, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    isBn ? 'সম্ভাব্য সহযাত্রী' : 'Compatible Passengers',
                    style: TextStyle(color: textPrimary, fontWeight: FontWeight.w800, fontSize: 14.5),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: isDark ? 0.15 : 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${ride.nearbyCandidates.length} ${isBn ? "জন" : "Peers"}',
                      style: const TextStyle(color: AppTheme.primary, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              if (ride.selectedPassengerRideIds.isNotEmpty)
                InkWell(
                  onTap: () => ride.clearPoolToSolo(),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    child: Text(
                      isBn ? '✕ সলো চলুন' : '✕ Go Solo',
                      style: const TextStyle(color: Color(0xFFEF4444), fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                  ),
                )
              else
                Text(
                  isBn ? 'পুলে নিতে ট্যাপ করুন' : 'Tap to add to pool',
                  style: TextStyle(color: textMuted, fontSize: 11, fontStyle: FontStyle.italic),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Candidate Passenger List Cards
          if (ride.nearbyCandidates.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: border),
              ),
              child: Text(
                appSettings.tr('scanning_corridor'),
                style: TextStyle(color: textMuted, fontSize: 12),
              ),
            )
          else
            ...ride.nearbyCandidates.map((candidate) {
              final isSelected = ride.isPassengerSelected(candidate);
              final canAddMore = ride.canSelectMorePassengers;

              return _buildCompatiblePassengerCard(
                context: context,
                candidate: candidate,
                isSelected: isSelected,
                canSelectMore: canAddMore,
                isDark: isDark,
                isBn: isBn,
                cardBg: cardBg,
                border: border,
                textPrimary: textPrimary,
                textSec: textSec,
                textMuted: textMuted,
                onToggle: () => ride.togglePassengerSelection(candidate),
              );
            }),

          const SizedBox(height: 18),

          // 3. Consolidated Active Route & Fare Details Card
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.route_rounded, color: Color(0xFF10B981), size: 18),
                  const SizedBox(width: 6),
                  Text(
                    isBn ? 'বর্তমান কারপুল রুট ও ভাড়ার বিবরণ' : 'Active Pool Route & Fare Details',
                    style: TextStyle(color: textPrimary, fontWeight: FontWeight.w800, fontSize: 14.5),
                  ),
                ],
              ),
              if (ride.isPoolCalculating)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary),
                ),
            ],
          ),
          const SizedBox(height: 10),

          if (ride.errorMessage != null)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppTheme.danger.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.danger.withValues(alpha: 0.4)),
              ),
              child: Text(ride.errorMessage!, style: const TextStyle(color: AppTheme.danger, fontSize: 12)),
            ),

          if (ride.selectedOption != null)
            RouteOptionCard(
              option: ride.selectedOption!,
              isSelected: true,
              isBest: true,
              onSelect: () {},
              onShowDetails: () {
                showDialog(context: context, builder: (_) => FareBreakdownDialog(option: ride.selectedOption!));
              },
            ),
          const SizedBox(height: 16),

          // Select and Confirm Booking Action Button
          if (ride.selectedOption != null)
            Container(
              height: 54,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: ride.isLoading
                    ? null
                    : () async {
                        final ok = await ride.bookSelectedOption();
                        if (ok && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: AppTheme.primary,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              content: Text(
                                appSettings.tr('booking_success', {'title': ride.selectedOption!.title}),
                                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                              ),
                            ),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: ride.isLoading
                    ? const CircularProgressIndicator(color: Colors.black)
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle_rounded, color: Colors.black, size: 22),
                          const SizedBox(width: 10),
                          Text(
                            appSettings.tr('confirm_booking', {
                              'fare': ride.selectedOption!.userIndividualFare.toStringAsFixed(0),
                            }),
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                          ),
                        ],
                      ),
              ),
            ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSearchInput({
    required TextEditingController controller,
    required String target,
    required IconData icon,
    required Color iconColor,
    required String label,
    required String hint,
    required bool isPinning,
    required VoidCallback onPinTap,
    required RideProvider ride,
    required AppSettingsProvider appSettings,
  }) {
    final isDark = appSettings.isDarkMode;
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.getSurfaceLight(isDark),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isPinning
              ? AppTheme.accent
              : (ride.activeSearchTarget == target ? AppTheme.primary : AppTheme.getBorder(isDark)),
          width: (isPinning || ride.activeSearchTarget == target) ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              style: TextStyle(
                color: AppTheme.getTextPrimary(isDark),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              onTap: () {
                ride.setActiveSearchTarget(target);
                ride.searchPlaces(controller.text, target);
              },
              onChanged: (val) {
                ride.searchPlaces(val, target);
              },
              onSubmitted: (val) async {
                if (val.trim().isNotEmpty) {
                  if (ride.autocompletePredictions.isNotEmpty) {
                    await ride.selectPlace(ride.autocompletePredictions.first, target);
                  } else {
                    await ride.searchAndSelectTopPlace(val, target);
                  }
                }
              },
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                  color: AppTheme.getTextMuted(isDark),
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            IconButton(
              icon: Icon(Icons.clear_rounded, size: 16, color: AppTheme.getTextMuted(isDark)),
              onPressed: () {
                controller.clear();
                ride.searchPlaces('', target);
              },
            ),
          Tooltip(
            message: isPinning ? appSettings.tr('cancel_pin') : appSettings.tr('pin_on_map'),
            child: IconButton(
              icon: Icon(
                Icons.pin_drop_rounded,
                size: 19,
                color: isPinning ? AppTheme.accent : AppTheme.getTextSecondary(isDark),
              ),
              onPressed: onPinTap,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionsList(RideProvider ride, String target, AppSettingsProvider appSettings) {
    final isDark = appSettings.isDarkMode;
    return Container(
      margin: const EdgeInsets.only(top: 6),
      constraints: const BoxConstraints(maxHeight: 220),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(isDark),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.54 : 0.12),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: ride.autocompletePredictions.length,
        separatorBuilder: (_, __) => Divider(color: AppTheme.getBorder(isDark), height: 1),
        itemBuilder: (ctx, idx) {
          final place = ride.autocompletePredictions[idx];
          return ListTile(
            dense: true,
            leading: const Icon(Icons.place_rounded, color: AppTheme.primary, size: 18),
            title: Text(
              place.primaryText,
              style: TextStyle(
                color: AppTheme.getTextPrimary(isDark),
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            subtitle: Text(
              place.secondaryText,
              style: TextStyle(color: AppTheme.getTextMuted(isDark), fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () {
              if (target == 'origin') {
                _originSearchController.text = place.fullText;
              } else {
                _destSearchController.text = place.fullText;
              }
              ride.selectPlace(place, target);
            },
          );
        },
      ),
    );
  }

  Widget _campusPill(
    String title,
    double oLat,
    double oLng,
    String oAddr,
    double dLat,
    double dLng,
    String dAddr,
    RideProvider ride,
    bool isDark,
  ) {
    return InkWell(
      onTap: () {
        _originSearchController.text = oAddr;
        _destSearchController.text = dAddr;
        ride.originAddress = oAddr;
        ride.originLat = oLat;
        ride.originLng = oLng;
        ride.destAddress = dAddr;
        ride.destLat = dLat;
        ride.destLng = dLng;
        ride.activeSearchTarget = 'none';
        ride.autocompletePredictions = [];
        ride.fetchNearbyAndOptions();
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.getSurfaceLight(isDark),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.getBorder(isDark)),
        ),
        child: Text(
          title,
          style: const TextStyle(color: AppTheme.secondaryLight, fontSize: 11.5, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
