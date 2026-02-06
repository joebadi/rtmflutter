import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/api_config.dart';

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
      final token = await _storage.read(key: 'accessToken');
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
      throw Exception('Error fetching nearby users: $e');
    }
  }

  // Get match suggestions (for cards/grid)
  Future<List<dynamic>> getMatchSuggestions({int limit = 10}) async {
    try {
      final token = await _storage.read(key: 'accessToken');
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
}
