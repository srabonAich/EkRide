import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ekride_frontend/models/user.dart';
import 'package:ekride_frontend/models/place.dart';
import 'package:ekride_frontend/models/candidate.dart';
import 'package:ekride_frontend/models/route_option.dart';
import 'package:ekride_frontend/models/booking.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:8080/api/v1';

  String? _token;

  void setToken(String? token) {
    _token = token;
  }

  Map<String, String> get _headers {
    final map = {'Content-Type': 'application/json'};
    if (_token != null && _token!.isNotEmpty) {
      map['Authorization'] = 'Bearer $_token';
    }
    return map;
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300 && data['success'] == true) {
      return data['data'];
    }
    throw Exception(data['message'] ?? 'Login failed');
  }

  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String fullName,
    String? phone,
    String? university,
    String? studentId,
    String role = 'PASSENGER',
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'fullName': fullName,
        'phone': phone,
        'university': university,
        'studentId': studentId,
        'role': role,
      }),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300 && data['success'] == true) {
      return data['data'];
    }
    throw Exception(data['message'] ?? 'Registration failed');
  }

  Future<User> getProfile() async {
    final response = await http.get(Uri.parse('$baseUrl/users/me'), headers: _headers);
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return User.fromJson(data['data']);
    }
    throw Exception(data['message'] ?? 'Failed to load profile');
  }

  Future<User> switchRole(String newRole) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/switch-role'),
      headers: _headers,
      body: jsonEncode({'role': newRole}),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return User.fromJson(data['data']);
    }
    throw Exception(data['message'] ?? 'Failed to switch role');
  }

  Future<List<PlacePrediction>> autocomplete(String query) async {
    final uri = Uri.parse('$baseUrl/routes/autocomplete?query=${Uri.encodeComponent(query)}');
    final response = await http.get(uri, headers: _headers);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        final list = data['data'] as List;
        return list.map((e) => PlacePrediction.fromJson(e)).toList();
      }
    }
    return [];
  }

  Future<PlacePrediction> getPlaceDetails(String placeId) async {
    final uri = Uri.parse('$baseUrl/routes/place-details?placeId=${Uri.encodeComponent(placeId)}');
    final response = await http.get(uri, headers: _headers);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return PlacePrediction.fromJson(data['data']);
      }
    }
    throw Exception('Failed to get place details');
  }

  Future<List<CandidatePassenger>> getNearbyPassengers(double lat, double lng, {double? destLat, double? destLng, String? address}) async {
    var url = '$baseUrl/rides/nearby?lat=$lat&lng=$lng';
    if (destLat != null && destLng != null) {
      url += '&destLat=$destLat&destLng=$destLng';
    }
    if (address != null && address.isNotEmpty) {
      url += '&address=${Uri.encodeComponent(address)}';
    }
    final uri = Uri.parse(url);
    final response = await http.get(uri, headers: _headers);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        final list = data['data'] as List;
        return list.map((e) => CandidatePassenger.fromJson(e)).toList();
      }
    }
    return [];
  }

  Future<List<RouteOption>> getRouteOptions({
    required double originLat,
    required double originLng,
    required String originAddress,
    required double destLat,
    required double destLng,
    required String destAddress,
    int seats = 1,
  }) async {
    final uri = Uri.parse('$baseUrl/rides/options');
    final body = jsonEncode({
      'origin': {'lat': originLat, 'lng': originLng, 'address': originAddress},
      'destination': {'lat': destLat, 'lng': destLng, 'address': destAddress},
      'seatsRequired': seats,
    });
    final response = await http.post(uri, headers: _headers, body: body);
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      final list = data['data'] as List;
      return list.map((e) => RouteOption.fromJson(e)).toList();
    }
    throw Exception(data['message'] ?? 'Failed to calculate options');
  }

  Future<RouteOption> getCustomPoolRoute({
    required double originLat,
    required double originLng,
    required String originAddress,
    required double destLat,
    required double destLng,
    required String destAddress,
    required List<int> selectedRideIds,
  }) async {
    final uri = Uri.parse('$baseUrl/rides/custom-pool');
    final body = jsonEncode({
      'origin': {'lat': originLat, 'lng': originLng, 'address': originAddress},
      'destination': {'lat': destLat, 'lng': destLng, 'address': destAddress},
      'selectedCandidateIds': selectedRideIds,
    });
    final response = await http.post(uri, headers: _headers, body: body);
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return RouteOption.fromJson(data['data']);
    }
    throw Exception(data['message'] ?? 'Failed to build custom pool');
  }

  Future<Booking> createBooking({
    required int rideId,
    required double pickupLat,
    required double pickupLng,
    required String pickupAddress,
    required double dropoffLat,
    required double dropoffLng,
    required String dropoffAddress,
    required int seats,
    required double individualFare,
    required double savings,
  }) async {
    final uri = Uri.parse('$baseUrl/bookings');
    final body = jsonEncode({
      'rideId': rideId,
      'pickup': {'lat': pickupLat, 'lng': pickupLng, 'address': pickupAddress},
      'dropoff': {'lat': dropoffLat, 'lng': dropoffLng, 'address': dropoffAddress},
      'seatsBooked': seats,
      'individualFare': individualFare,
      'savings': savings,
    });
    final response = await http.post(uri, headers: _headers, body: body);
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return Booking.fromJson(data['data']);
    }
    throw Exception(data['message'] ?? 'Booking failed');
  }

  Future<List<Booking>> getMyBookings() async {
    final response = await http.get(Uri.parse('$baseUrl/bookings/me'), headers: _headers);
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      final list = data['data'] as List;
      return list.map((e) => Booking.fromJson(e)).toList();
    }
    return [];
  }

  Future<Booking> cancelBooking(int bookingId) async {
    final response = await http.post(Uri.parse('$baseUrl/bookings/$bookingId/cancel'), headers: _headers);
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return Booking.fromJson(data['data']);
    }
    throw Exception(data['message'] ?? 'Cancellation failed');
  }

  Future<void> updateLocation({
    required int rideId,
    required double lat,
    required double lng,
    double heading = 0.0,
    double speed = 5.0,
    bool isSimulated = true,
  }) async {
    final uri = Uri.parse('$baseUrl/location/update');
    final body = jsonEncode({
      'rideId': rideId,
      'lat': lat,
      'lng': lng,
      'heading': heading,
      'speed': speed,
      'isSimulated': isSimulated,
    });
    await http.post(uri, headers: _headers, body: body);
  }
}
