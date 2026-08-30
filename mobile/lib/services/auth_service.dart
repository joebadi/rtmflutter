import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';

class AuthService {
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: ApiConfig.connectTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
    ),
  );
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  /// Login with email and password
  /// Backend response: { success: true, data: { user: {...}, tokens: { accessToken, refreshToken } } }
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dio.post(
        ApiConfig.login,
        // Backend expects 'emailOrPhone'
        data: {'emailOrPhone': email, 'password': password},
      );

      // Extract tokens from response
      if (response.data['success'] == true && response.data['data'] != null) {
        final tokens = response.data['data']['tokens'];
        if (tokens != null) {
          await _storage.write(
            key: 'access_token',
            value: tokens['accessToken'],
          );
          await _storage.write(
            key: 'refresh_token',
            value: tokens['refreshToken'],
          );
        }
      }

      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e, 'Login failed');
    }
  }

  /// Register new user
  /// Backend expects: firstName, lastName, email, password, phoneNumber
  /// Optional: dateOfBirth, gender
  Future<Map<String, dynamic>> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String phoneNumber,
    String? dateOfBirth,
    String? gender,
  }) async {
    try {
      final requestData = {
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'password': password,
        'phoneNumber': phoneNumber,
        if (dateOfBirth != null) 'dateOfBirth': dateOfBirth,
        if (gender != null) 'gender': gender,
      };

      final response = await _dio.post(ApiConfig.register, data: requestData);

      // Extract tokens from response
      if (response.data['success'] == true && response.data['data'] != null) {
        final tokens = response.data['data']['tokens'];
        if (tokens != null) {
          await _storage.write(
            key: 'access_token',
            value: tokens['accessToken'],
          );
          await _storage.write(
            key: 'refresh_token',
            value: tokens['refreshToken'],
          );
        }

        // Trigger OTP send immediately after successful registration
        try {
          await sendOtp(email);
          debugPrint('Auto-sent OTP after registration to $email');
        } catch (e) {
          debugPrint('Failed to auto-send OTP: $e');
        }
      }

      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e, 'Registration failed');
    } catch (e) {
      debugPrint('Unexpected error during registration: $e');
      throw AuthException(
          'We couldn’t complete your registration. Please try again.');
    }
  }

  /// Turns a Dio error into a friendly, human-readable [AuthException] — no raw
  /// "Exception: ..." text and no developer jargon shown to users.
  Exception _handleDioError(DioException e, String defaultMessage) {
    // Log status for debugging; avoid logging response bodies (may contain PII).
    debugPrint('$defaultMessage error: ${e.message}');
    debugPrint('Status code: ${e.response?.statusCode}');

    // Connectivity problems (no/poor network).
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return AuthException(
            'This is taking longer than usual. Please check your connection and try again.');
      case DioExceptionType.connectionError:
        return AuthException(
            'We couldn’t reach the server. Please check your internet connection and try again.');
      default:
        break;
    }

    // Pull a server-provided message if there is one.
    String? serverMessage;
    final data = e.response?.data;
    if (data is Map) {
      if (data['message'] is String) {
        serverMessage = data['message'] as String;
      }
      if ((serverMessage == null || serverMessage.isEmpty) &&
          data['errors'] is List &&
          (data['errors'] as List).isNotEmpty) {
        final first = (data['errors'] as List).first;
        if (first is Map && first['message'] != null) {
          serverMessage = first['message'].toString();
        }
      }
    }

    // Map by HTTP status to plain English.
    switch (e.response?.statusCode) {
      case 400:
      case 422:
        return AuthException(_friendly(serverMessage) ??
            'Please check the details you entered and try again.');
      case 401:
        return AuthException(
            'Your email or password is incorrect. Please try again.');
      case 403:
        return AuthException(
            _friendly(serverMessage) ?? 'You don’t have permission to do that.');
      case 404:
        return AuthException(_friendly(serverMessage) ??
            'We couldn’t find an account with those details.');
      case 409:
        return AuthException(_friendly(serverMessage) ??
            'An account with these details already exists.');
      case 429:
        return AuthException(
            'Too many attempts. Please wait a moment and try again.');
    }
    final status = e.response?.statusCode ?? 0;
    if (status >= 500) {
      return AuthException(
          'Something went wrong on our end. Please try again in a moment.');
    }
    return AuthException(_friendly(serverMessage) ?? defaultMessage);
  }

  /// Cleans a server message: maps known developer phrases to friendly copy and
  /// capitalises the first letter. Returns null for empty input.
  String? _friendly(String? raw) {
    if (raw == null) return null;
    var s = raw.trim();
    if (s.isEmpty) return null;
    final lower = s.toLowerCase();
    if (lower.contains('invalid credentials') ||
        lower.contains('incorrect password') ||
        lower.contains('wrong password')) {
      return 'Your email or password is incorrect. Please try again.';
    }
    if (lower.contains('user not found') || lower.contains('no user')) {
      return 'We couldn’t find an account with those details.';
    }
    if (lower.contains('already exists') ||
        lower.contains('already registered') ||
        lower.contains('duplicate')) {
      return 'An account with these details already exists.';
    }
    if (lower.contains('expired') && lower.contains('token')) {
      return 'Your session has expired. Please sign in again.';
    }
    return s[0].toUpperCase() + s.substring(1);
  }

  /// Send OTP for verification
  /// Backend expects: { "emailOrPhone": "email@example.com", "type": "email" }
  Future<Map<String, dynamic>> sendOtp(String emailOrPhone) async {
    try {
      final response = await _dio.post(
        ApiConfig.sendOtp,
        data: {
          'emailOrPhone': emailOrPhone,
          'type': 'email', // Enforce strict type 'email'
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to send OTP');
    }
  }

  /// Verify OTP
  /// Backend expects: { "emailOrPhone": "email@example.com", "type": "email", "otp": "123456" }
  Future<Map<String, dynamic>> verifyOtp(
    String emailOrPhone,
    String otp,
  ) async {
    try {
      final response = await _dio.post(
        ApiConfig.verifyOtp,
        data: {
          'emailOrPhone': emailOrPhone,
          'type': 'email', // Enforce strict type 'email'
          'otp': otp,
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'OTP verification failed');
    }
  }

  /// Check if email or phone exists
  Future<Map<String, dynamic>> checkExistence({
    String? email,
    String? phoneNumber,
  }) async {
    try {
      final response = await _dio.post(
        ApiConfig.checkExistence,
        data: {
          if (email != null) 'email': email,
          if (phoneNumber != null) 'phoneNumber': phoneNumber,
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to check existence',
      );
    }
  }

  /// Forgot password - request reset token via email
  Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final response = await _dio.post(
        ApiConfig.forgotPassword,
        data: {'email': email},
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e, 'Failed to send reset link');
    }
  }

  /// Reset password with token and new password
  Future<Map<String, dynamic>> resetPassword(String token, String newPassword) async {
    try {
      final response = await _dio.post(
        ApiConfig.resetPassword,
        data: {'token': token, 'newPassword': newPassword},
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e, 'Failed to reset password');
    }
  }

  /// Refresh access token
  Future<String?> refreshAccessToken() async {
    try {
      final refreshToken = await _storage.read(key: 'refresh_token');
      if (refreshToken == null) return null;

      final response = await _dio.post(
        ApiConfig.refreshToken,
        data: {'refreshToken': refreshToken},
      );

      if (response.data['success'] == true && response.data['data'] != null) {
        final newAccessToken = response.data['data']['accessToken'];
        await _storage.write(key: 'access_token', value: newAccessToken);
        return newAccessToken;
      }
      return null;
    } on DioException catch (e) {
      debugPrint('Token refresh failed: ${e.message}');
      return null;
    }
  }

  /// Logout
  Future<void> logout() async {
    try {
      final token = await getAccessToken();
      if (token != null) {
        await _dio.post(
          ApiConfig.logout,
          options: Options(headers: {'Authorization': 'Bearer $token'}),
        );
      }
    } catch (e) {
      debugPrint('Logout API call failed: $e');
    } finally {
      // Always clear local tokens
      await _storage.delete(key: 'access_token');
      await _storage.delete(key: 'refresh_token');
    }
  }

  /// Permanently delete the signed-in user's account, then clear local tokens.
  /// Returns true on success.
  Future<bool> deleteAccount() async {
    try {
      final token = await getAccessToken();
      final response = await _dio.delete(
        ApiConfig.deleteAccount,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data['success'] == true;
    } on DioException catch (e) {
      throw _handleDioError(e, 'Account deletion failed');
    } finally {
      await _storage.delete(key: 'access_token');
      await _storage.delete(key: 'refresh_token');
    }
  }

  /// Get stored access token
  Future<String?> getAccessToken() async {
    return await _storage.read(key: 'access_token');
  }

  /// Get stored refresh token
  Future<String?> getRefreshToken() async {
    return await _storage.read(key: 'refresh_token');
  }

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null;
  }
}

/// A user-facing authentication error. Its [toString] is the friendly message
/// itself (no "Exception:" prefix), so it can be shown directly in the UI.
class AuthException implements Exception {
  AuthException(this.message);
  final String message;

  @override
  String toString() => message;
}
