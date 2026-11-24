import 'package:flutter/material.dart';
import 'package:ekride_frontend/models/user.dart';
import 'package:ekride_frontend/services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService apiService;
  User? _currentUser;
  String? _token;
  bool _isLoading = false;
  String? _errorMessage;

  AuthProvider(this.apiService);

  User? get currentUser => _currentUser;
  String? get token => _token;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _token != null && _currentUser != null;

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final res = await apiService.login(email, password);
      _token = res['token'];
      apiService.setToken(_token);
      _currentUser = User.fromJson(res);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String fullName,
    String? phone,
    String? university,
    String? studentId,
    String role = 'PASSENGER',
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final res = await apiService.register(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
        university: university,
        studentId: studentId,
        role: role,
      );
      _token = res['token'];
      apiService.setToken(_token);
      _currentUser = User.fromJson(res);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> switchRole(String newRole) async {
    try {
      _currentUser = await apiService.switchRole(newRole);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  void logout() {
    _currentUser = null;
    _token = null;
    apiService.setToken(null);
    notifyListeners();
  }
}
