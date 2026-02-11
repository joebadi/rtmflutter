import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';

class MatchService {
  final Dio _dio = Dio();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  MatchService() {
    _dio.options.baseUrl = ApiConfig.baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);
  }

  // Get nearby users
  Future<List<dynamic>> getNearbyUsers({
    required double latitude,
    required double longitude,
    int radius = 50,
    int limit = 20,
  }) async {
    try {
      final token = await _storage.read(key: 'access_token');
      _dio.options.headers['Authorization'] = 'Bearer $token';

      final response = await _dio.post(
        '${ApiConfig.baseUrl}/matches/nearby',
        data: {
          'latitude': latitude,
          'longitude': longitude,
          'radius': radius,
          'limit': limit,
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data']['users'];
      } else {
        throw Exception(response.data['message'] ?? 'Failed to fetch nearby users');
      }
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 401) {
        await _storage.delete(key: 'access_token');
        await _storage.delete(key: 'refresh_token');
        throw Exception('UNAUTHORIZED');
      }
      throw Exception('Error fetching nearby users: $e');
    }
  }

  // Get match suggestions (for cards/grid)
  Future<List<dynamic>> getMatchSuggestions({int limit = 10}) async {
    try {
      final token = await _storage.read(key: 'access_token');
      _dio.options.headers['Authorization'] = 'Bearer $token';

      final response = await _dio.get(
        '${ApiConfig.baseUrl}/matches/suggestions',
        queryParameters: {'limit': limit},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data']['suggestions'];
      } else {
        throw Exception(response.data['message'] ?? 'Failed to fetch suggestions');
      }
    } catch (e) {
      throw Exception('Error fetching suggestions: $e');
    }
  }
  // Get match preferences
  Future<Map<String, dynamic>> getPreferences() async {
    try {
      final token = await _storage.read(key: 'access_token');
      if (token != null) {
        _dio.options.headers['Authorization'] = 'Bearer $token'; // Update header logic
      } else {
         // Handle case where token might be missing or rely on what's set elsewhere? 
         // For now, let's just ensure we try to read it.
      }
      // Note: check where 'access_token' vs 'accessToken' key consistency. 
      // AuthService uses 'access_token'. MatchService uses 'accessToken'. 
      // I MUST FIX THIS KEY MISMATCH FIRST.

      final response = await _dio.get(ApiConfig.preferences);

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
        // Backend returns { preferences: { ... } } - extract the inner object
        if (data is Map && data.containsKey('preferences') && data['preferences'] != null) {
          return Map<String, dynamic>.from(data['preferences']);
        }
        return Map<String, dynamic>.from(data ?? {});
      } else {
        return {};
      }
    } catch (e) {
      print('Error fetching preferences: $e');
      return {};
    }
  }

  // Update match preferences
  Future<bool> updatePreferences(Map<String, dynamic> preferences) async {
    try {
      final token = await _storage.read(key: 'access_token');
       _dio.options.headers['Authorization'] = 'Bearer $token';

      final response = await _dio.post(
        ApiConfig.preferences,
        data: preferences,
      );

      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      print('Error updating preferences: $e');
      return false;
    }
  }
}
