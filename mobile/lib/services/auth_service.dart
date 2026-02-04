import 'package:dio/dio.dart';
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
        data: {'email': email, 'password': password},
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
      throw Exception(e.response?.data['message'] ?? 'Login failed');
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

      print('Registration request data: $requestData');

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
        // Using email as the primary identifier for OTP as requested
        try {
          await sendOtp(email);
          print('Auto-sent OTP after registration to $email');
        } catch (e) {
          print('Failed to auto-send OTP: $e');
          // We don't throw here, as registration was successful.
          // User can request OTP resend from the verification screen.
        }
      }

      return response.data;
    } on DioException catch (e) {
      // Enhanced error logging
      print('Registration error: ${e.message}');
      print('Response data: ${e.response?.data}');
      print('Status code: ${e.response?.statusCode}');

      // Extract error message from response
      String errorMessage = 'Registration failed';
      if (e.response?.data != null) {
        final data = e.response!.data;
        if (data is Map<String, dynamic>) {
          // Check for validation errors with details
          if (data.containsKey('errors') && data['errors'] is Map) {
            final errors = data['errors'] as Map<String, dynamic>;
            final errorList = errors.entries
                .map((e) => '${e.key}: ${e.value}')
                .join(', ');
            errorMessage = 'Validation error: $errorList';
          } else if (data.containsKey('message')) {
            errorMessage = data['message'].toString();
            // If there's additional error details, append them
            if (data.containsKey('error') && data['error'] is Map) {
              final errorDetails = data['error'] as Map<String, dynamic>;
              if (errorDetails.containsKey('details')) {
                errorMessage += '\nDetails: ${errorDetails['details']}';
              }
            }
          } else if (data['error'] is Map) {
            errorMessage = data['error']['message']?.toString() ?? errorMessage;
          } else if (data['error'] is String) {
            errorMessage = data['error'];
          }
        }
      }
      throw Exception(errorMessage);
    } catch (e) {
      print('Unexpected error during registration: $e');
      throw Exception(
        'Registration failed: ${e.toString().replaceAll('Exception: ', '')}',
      );
    }
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
      print('Token refresh failed: ${e.message}');
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
      print('Logout API call failed: $e');
    } finally {
      // Always clear local tokens
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
