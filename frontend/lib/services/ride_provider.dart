import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ekride_frontend/models/place.dart';
import 'package:ekride_frontend/models/candidate.dart';
import 'package:ekride_frontend/models/route_option.dart';
import 'package:ekride_frontend/models/booking.dart';
import 'package:ekride_frontend/services/api_service.dart';
import 'package:ekride_frontend/core/polyline_utils.dart';

class RideProvider extends ChangeNotifier {
  final ApiService apiService;

  // Selected Route Points (Default: Dhaka University TSC -> Banani 11)
  double originLat = 23.7328;
  double originLng = 90.3957;
  String originAddress = 'TSC, University of Dhaka';

  double destLat = 23.7937;
  double destLng = 90.4066;
  String destAddress = 'Road 11, Banani, Dhaka';

  // Active search state
  String activeSearchTarget = 'none'; // 'origin', 'destination', 'none'
  List<PlacePrediction> autocompletePredictions = [];
  List<CandidatePassenger> nearbyCandidates = [];
  List<RouteOption> routeOptions = [];
  RouteOption? selectedOption;

  // Car Capacity & Candidate Selection State
  int carCapacity = 4; // Total seats (e.g. 2, 3, or 4 seats: driver + passengers)
  Set<int> selectedPassengerRideIds = {};
  bool isPoolCalculating = false;

  int get maxAllowedPeers => max(1, carCapacity - 1);
  int get remainingSeats => max(0, maxAllowedPeers - selectedPassengerRideIds.length);
  bool isPassengerSelected(CandidatePassenger c) => selectedPassengerRideIds.contains(c.rideId);
  bool get canSelectMorePassengers => selectedPassengerRideIds.length < maxAllowedPeers;

  // Pin on map mode
  String mapPinMode = 'none'; // 'origin', 'destination', 'none'

  bool isLoading = false;
  String? errorMessage;

  // Active Booking & Live Simulation
  Booking? activeBooking;
  Timer? _simulationTimer;
  Timer? _debounceTimer;
  double driverLat = 23.7328;
  double driverLng = 90.3957;
  double driverBearing = 0.0;
  double driverSpeedKmh = 35.0;
  double remainingDistanceKm = 0.0;
  int remainingDurationSeconds = 0;
  double tripProgress = 0.0;
  bool isSimulating = false;
  bool isSimulationPaused = false;
  double simulationSpeed = 1.0;
  String trackingStatus = 'Driver en route to pickup';
  String trackingStatusBn = 'চালক পিকআপে আসছেন';

  int _currentPathIndex = 0;
  List<PolylineCoord> _smoothRoadPath = [];
  final Set<int> _reachedStopOrders = {};
  int _stopPauseTicksRemaining = 0;

  RideProvider(this.apiService);

  void setMapPinMode(String mode) {
    mapPinMode = mode;
    notifyListeners();
  }

  void setActiveSearchTarget(String target) {
    activeSearchTarget = target;
    autocompletePredictions = [];
    notifyListeners();
  }

  void setOrigin(double lat, double lng, String address) {
    originLat = lat;
    originLng = lng;
    originAddress = address;
    notifyListeners();
    fetchNearbyAndOptions();
  }

  void setDestination(double lat, double lng, String address) {
    destLat = lat;
    destLng = lng;
    destAddress = address;
    notifyListeners();
    fetchNearbyAndOptions();
  }

  void swapOriginAndDestination() {
    final tempLat = originLat;
    final tempLng = originLng;
    final tempAddr = originAddress;

    originLat = destLat;
    originLng = destLng;
    originAddress = destAddress;

    destLat = tempLat;
    destLng = tempLng;
    destAddress = tempAddr;

    activeSearchTarget = 'none';
    autocompletePredictions = [];
    notifyListeners();
    fetchNearbyAndOptions();
  }

  void selectOptionByPassengerName(String passengerName) {
    if (routeOptions.isEmpty) return;
    try {
      final match = routeOptions.firstWhere(
        (opt) => opt.title.toLowerCase().contains(passengerName.toLowerCase()),
      );
      selectedOption = match;
      notifyListeners();
    } catch (_) {}
  }

  void searchPlaces(String query, String target) {
    activeSearchTarget = target;
    _debounceTimer?.cancel();
    if (query.trim().isEmpty) {
      autocompletePredictions = [];
      notifyListeners();
      return;
    }
    _debounceTimer = Timer(const Duration(milliseconds: 200), () async {
      try {
        autocompletePredictions = await apiService.autocomplete(query);
        notifyListeners();
      } catch (_) {}
    });
  }

  Future<void> selectPlace(PlacePrediction place, String target) async {
    double lat = place.lat ?? 0;
    double lng = place.lng ?? 0;
    String address = place.fullText;

    if (lat == 0 || lng == 0) {
      try {
        final details = await apiService.getPlaceDetails(place.placeId);
        lat = details.lat ?? 23.7808;
        lng = details.lng ?? 90.4152;
        address = details.fullText.isNotEmpty ? details.fullText : address;
      } catch (_) {
        lat = 23.7808;
        lng = 90.4152;
      }
    }

    if (target == 'origin') {
      originLat = lat;
      originLng = lng;
      originAddress = address;
    } else {
      destLat = lat;
      destLng = lng;
      destAddress = address;
    }

    activeSearchTarget = 'none';
    autocompletePredictions = [];
    notifyListeners();

    await fetchNearbyAndOptions();
  }

  Future<void> searchAndSelectTopPlace(String query, String target) async {
    if (query.trim().isEmpty) return;
    try {
      final list = await apiService.autocomplete(query);
      if (list.isNotEmpty) {
        await selectPlace(list.first, target);
        return;
      }
    } catch (_) {}
    if (target == 'origin') {
      originAddress = query;
    } else {
      destAddress = query;
    }
    activeSearchTarget = 'none';
    autocompletePredictions = [];
    notifyListeners();
    await fetchNearbyAndOptions();
  }

  void setPointFromMapTap(double lat, double lng) {
    if (mapPinMode == 'origin') {
      originLat = lat;
      originLng = lng;
      originAddress = 'Map Pin (${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)})';
      mapPinMode = 'none';
      notifyListeners();
      fetchNearbyAndOptions();
    } else if (mapPinMode == 'destination') {
      destLat = lat;
      destLng = lng;
      destAddress = 'Map Pin (${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)})';
      mapPinMode = 'none';
      notifyListeners();
      fetchNearbyAndOptions();
    }
  }

  Future<void> fetchNearbyAndOptions() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      nearbyCandidates = await apiService.getNearbyPassengers(originLat, originLng, destLat: destLat, destLng: destLng, address: originAddress);
      routeOptions = await apiService.getRouteOptions(
        originLat: originLat,
        originLng: originLng,
        originAddress: originAddress,
        destLat: destLat,
        destLng: destLng,
        destAddress: destAddress,
      );

      if (routeOptions.isNotEmpty) {
        selectedOption = routeOptions.first;
        selectedPassengerRideIds.clear();
        for (final c in nearbyCandidates) {
          final first = c.passengerName.toLowerCase().split(' ').first;
          if (selectedOption!.title.toLowerCase().contains(first)) {
            selectedPassengerRideIds.add(c.rideId);
          }
        }
      }
      isLoading = false;
      notifyListeners();
    } catch (e) {
      errorMessage = e.toString().replaceAll('Exception: ', '');
      isLoading = false;
      notifyListeners();
    }
  }

  void selectOption(RouteOption option) {
    selectedOption = option;
    selectedPassengerRideIds.clear();
    for (final c in nearbyCandidates) {
      final first = c.passengerName.toLowerCase().split(' ').first;
      if (option.title.toLowerCase().contains(first)) {
        selectedPassengerRideIds.add(c.rideId);
      }
    }
    notifyListeners();
  }

  void setCarCapacity(int capacity) {
    if (carCapacity == capacity) return;
    carCapacity = capacity;
    final maxPeers = max(1, capacity - 1);
    if (selectedPassengerRideIds.length > maxPeers) {
      selectedPassengerRideIds = selectedPassengerRideIds.take(maxPeers).toSet();
      recalculateCustomPool();
    } else {
      notifyListeners();
    }
  }

  Future<void> togglePassengerSelection(CandidatePassenger c) async {
    if (selectedPassengerRideIds.contains(c.rideId)) {
      selectedPassengerRideIds.remove(c.rideId);
    } else {
      if (selectedPassengerRideIds.length >= maxAllowedPeers) {
        return;
      }
      selectedPassengerRideIds.add(c.rideId);
    }
    await recalculateCustomPool();
  }

  Future<void> clearPoolToSolo() async {
    selectedPassengerRideIds.clear();
    await recalculateCustomPool();
  }

  Future<void> recalculateCustomPool() async {
    isPoolCalculating = true;
    notifyListeners();
    try {
      final opt = await apiService.getCustomPoolRoute(
        originLat: originLat,
        originLng: originLng,
        originAddress: originAddress,
        destLat: destLat,
        destLng: destLng,
        destAddress: destAddress,
        selectedRideIds: selectedPassengerRideIds.toList(),
      );
      selectedOption = opt;
      isPoolCalculating = false;
      notifyListeners();
      if (isSimulating) {
        startLiveTrackingSimulation(selectedOption);
      }
    } catch (e) {
      isPoolCalculating = false;
      notifyListeners();
    }
  }

  Future<bool> bookSelectedOption() async {
    if (selectedOption == null) return false;
    isLoading = true;
    notifyListeners();

    try {
      activeBooking = await apiService.createBooking(
        rideId: selectedOption!.rideId,
        pickupLat: originLat,
        pickupLng: originLng,
        pickupAddress: originAddress,
        dropoffLat: destLat,
        dropoffLng: destLng,
        dropoffAddress: destAddress,
        seats: 1,
        individualFare: selectedOption!.userIndividualFare,
        savings: selectedOption!.savings,
      );

      isLoading = false;
      notifyListeners();
      startLiveTrackingSimulation();
      return true;
    } catch (e) {
      errorMessage = e.toString().replaceAll('Exception: ', '');
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  List<PolylineCoord> _buildRoadPathForOption(RouteOption? option) {
    if (option == null) {
      return PolylineUtils.interpolatePath([
        PolylineCoord(originLat, originLng),
        PolylineCoord(destLat, destLng),
      ], maxStepMeters: 30.0);
    }

    List<PolylineCoord> rawPoints = [];

    // 1. If pathCoordinates are supplied
    if (option.pathCoordinates.isNotEmpty) {
      rawPoints = option.pathCoordinates
          .where((pt) => pt.length >= 2)
          .map((pt) => PolylineCoord(pt[0], pt[1]))
          .toList();
    }

    // 2. Otherwise decode encodedPolyline
    if (rawPoints.isEmpty && option.encodedPolyline != null && option.encodedPolyline!.isNotEmpty) {
      rawPoints = PolylineUtils.decodePolyline(option.encodedPolyline);
    }

    // 3. Fallback: stops sequence
    if (rawPoints.isEmpty) {
      rawPoints.add(PolylineCoord(originLat, originLng));
      for (final s in option.stops) {
        if (s.type != 'ORIGIN' && s.type != 'DESTINATION') {
          rawPoints.add(PolylineCoord(s.lat, s.lng));
        }
      }
      rawPoints.add(PolylineCoord(destLat, destLng));
    }

    // Sub-sample along the road network so that car advances smoothly every frame
    return PolylineUtils.interpolatePath(rawPoints, maxStepMeters: 25.0);
  }

  void startLiveLocationSimulation([int? rideId]) {
    startLiveTrackingSimulation();
  }

  void trackBookingOnMap(Booking booking) {
    originLat = booking.pickupLat;
    originLng = booking.pickupLng;
    originAddress = booking.pickupAddress;
    destLat = booking.dropoffLat;
    destLng = booking.dropoffLng;
    destAddress = booking.dropoffAddress;

    RouteOption? matched;
    for (final opt in routeOptions) {
      if (opt.rideId == booking.rideId) {
        matched = opt;
        break;
      }
    }
    if (matched != null) {
      selectedOption = matched;
    }
    startLiveTrackingSimulation(selectedOption);
  }

  void startLiveTrackingSimulation([RouteOption? opt]) {
    if (opt != null) {
      selectedOption = opt;
    }

    final option = selectedOption;
    _smoothRoadPath = _buildRoadPathForOption(option);
    if (_smoothRoadPath.isEmpty) return;

    isSimulating = true;
    isSimulationPaused = false;
    _currentPathIndex = 0;
    _reachedStopOrders.clear();
    _stopPauseTicksRemaining = 0;

    final start = _smoothRoadPath.first;
    driverLat = start.lat;
    driverLng = start.lng;
    if (_smoothRoadPath.length > 1) {
      driverBearing = PolylineUtils.calculateBearing(
        start.lat, start.lng,
        _smoothRoadPath[1].lat, _smoothRoadPath[1].lng,
      );
    } else {
      driverBearing = 0.0;
    }

    final totalMeters = option?.totalDistanceMeters ?? 6000;
    final totalSeconds = option?.totalDurationSeconds ?? 720;
    remainingDistanceKm = totalMeters / 1000.0;
    remainingDurationSeconds = totalSeconds;
    tripProgress = 0.0;
    driverSpeedKmh = 35.0;

    trackingStatus = 'Driver en route to pickup';
    trackingStatusBn = 'চালক পিকআপে আসছেন';

    notifyListeners();
    _launchSimulationTimer();
  }

  void _launchSimulationTimer() {
    _simulationTimer?.cancel();

    // Fast 250ms tick for smooth road navigation
    _simulationTimer = Timer.periodic(const Duration(milliseconds: 250), (timer) {
      if (!isSimulating) {
        timer.cancel();
        return;
      }

      if (isSimulationPaused) {
        return;
      }

      // If pausing at a stop (e.g. passenger boarding)
      if (_stopPauseTicksRemaining > 0) {
        _stopPauseTicksRemaining--;
        return;
      }

      if (_smoothRoadPath.isEmpty) return;

      int stepIncrement = simulationSpeed <= 1.0 ? 1 : simulationSpeed.round();
      _currentPathIndex += stepIncrement;

      if (_currentPathIndex >= _smoothRoadPath.length - 1) {
        // Arrived at destination
        _currentPathIndex = _smoothRoadPath.length - 1;
        final last = _smoothRoadPath.last;
        driverLat = last.lat;
        driverLng = last.lng;
        driverSpeedKmh = 0.0;
        remainingDistanceKm = 0.0;
        remainingDurationSeconds = 0;
        tripProgress = 1.0;
        trackingStatus = 'Arrived at destination! Trip completed successfully.';
        trackingStatusBn = 'গন্তব্যে পৌঁছেছেন! সফল যাত্রা সম্পন্ন হয়েছে।';
        timer.cancel();
        notifyListeners();
        return;
      }

      final curr = _smoothRoadPath[_currentPathIndex];
      final next = _smoothRoadPath[_currentPathIndex + 1];

      driverLat = curr.lat;
      driverLng = curr.lng;
      driverBearing = PolylineUtils.calculateBearing(curr.lat, curr.lng, next.lat, next.lng);

      tripProgress = _currentPathIndex / (_smoothRoadPath.length - 1);
      final totalMeters = selectedOption?.totalDistanceMeters ?? 6000;
      final totalSeconds = selectedOption?.totalDurationSeconds ?? 720;

      remainingDistanceKm = (totalMeters / 1000.0) * (1.0 - tripProgress);
      remainingDurationSeconds = ((totalSeconds) * (1.0 - tripProgress)).round();

      // Dynamic city speed simulation (28 - 44 km/h)
      driverSpeedKmh = 32.0 + (5.0 * sin(_currentPathIndex * 0.15));

      // Check intermediate stops (Student pickups / dropoffs along corridor)
      if (selectedOption != null && selectedOption!.stops.isNotEmpty) {
        for (final stop in selectedOption!.stops) {
          if (stop.type != 'ORIGIN' && stop.type != 'DESTINATION') {
            if (!_reachedStopOrders.contains(stop.order)) {
              final distToStop = PolylineUtils.distanceMeters(curr.lat, curr.lng, stop.lat, stop.lng);
              if (distToStop < 45.0) {
                _reachedStopOrders.add(stop.order);
                _stopPauseTicksRemaining = (6 / simulationSpeed).ceil(); // ~1.5 sec pause
                final isPickup = stop.type == 'PICKUP';
                final name = stop.passengerName ?? 'Peer';
                if (isPickup) {
                  trackingStatus = 'Curbside stop • $name is boarding';
                  trackingStatusBn = 'কার্বসাইড স্টপ • $name গাড়িতে উঠছেন';
                } else {
                  trackingStatus = 'Curbside stop • $name is alighting';
                  trackingStatusBn = 'কার্বসাইড স্টপ • $name নামছেন';
                }
                notifyListeners();
                return;
              }
            }
          }
        }
      }

      // General corridor progression status
      if (tripProgress < 0.15) {
        trackingStatus = 'En route to student pickup point';
        trackingStatusBn = 'পিকআপ পয়েন্টের দিকে আসছেন';
      } else if (tripProgress < 0.85) {
        trackingStatus = 'Cruising along corridor • Live traffic-aware';
        trackingStatusBn = 'করিডোরে যাত্রা চলছে • লাইভ ট্রাফিক পর্যবেক্ষণ';
      } else {
        trackingStatus = 'Approaching final destination';
        trackingStatusBn = 'গন্তব্যের কাছাকাছি পৌঁছাচ্ছে';
      }

      apiService.updateLocation(
        rideId: selectedOption?.rideId ?? 1,
        lat: driverLat,
        lng: driverLng,
        heading: driverBearing,
        speed: driverSpeedKmh / 3.6,
        isSimulated: true,
      );

      notifyListeners();
    });
  }

  void toggleSimulationPause() {
    isSimulationPaused = !isSimulationPaused;
    notifyListeners();
  }

  void setSimulationSpeed(double speed) {
    simulationSpeed = speed;
    notifyListeners();
  }

  void restartSimulation() {
    startLiveTrackingSimulation(selectedOption);
  }

  void stopLiveTrackingSimulation() {
    _simulationTimer?.cancel();
    isSimulating = false;
    isSimulationPaused = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _simulationTimer?.cancel();
    _debounceTimer?.cancel();
    super.dispose();
  }
}
