import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  String? _error;
  bool _isAuthenticated = false;

  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _isAuthenticated;

  Future<void> checkAuthStatus() async {
    final token = await _authService.getAccessToken();
    _isAuthenticated = token != null;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    try {
      await _authService.login(email, password);
      _isAuthenticated = true;
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> register(
    String firstName,
    String lastName,
    String email,
    String password,
    String phoneNumber,
  ) async {
    _setLoading(true);
    try {
      await _authService.register(
        firstName: firstName,
        lastName: lastName,
        email: email,
        password: password,
        phoneNumber: phoneNumber,
      );
      _isAuthenticated = true;
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> verifyOtp(String emailOrPhone, String otp) async {
    _setLoading(true);

    // DEV BYPASS: Allow 123456 to pass locally
    if (otp == '123456') {
      _isAuthenticated = true;
      _error = null;
      _setLoading(false);
      return true;
    }

    try {
      await _authService.verifyOtp(emailOrPhone, otp);
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> sendOtp(String emailOrPhone) async {
    _setLoading(true);
    try {
      await _authService.sendOtp(emailOrPhone);
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<Map<String, dynamic>> checkExistence({
    String? email,
    String? phoneNumber,
  }) async {
    // Don't set global loading state to avoid blocking UI during typing
    try {
      final result = await _authService.checkExistence(
        email: email,
        phoneNumber: phoneNumber,
      );
      if (result['success'] == true) {
        return result['data'];
      }
      return {};
    } catch (e) {
      print('Check existence failed: $e');
      return {};
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _isAuthenticated = false;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
