import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';

class LikeService {
  final Dio _dio = Dio();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  LikeService() {
    _dio.options.baseUrl = ApiConfig.baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);
  }

  /// Send a like to another user
  Future<Map<String, dynamic>> sendLike(String likedUserId) async {
    try {
      final token = await _storage.read(key: 'access_token');
      _dio.options.headers['Authorization'] = 'Bearer $token';

      debugPrint('[LikeService] Sending like to user: $likedUserId');

      final response = await _dio.post(
        '/likes/send',
        data: {'likedUserId': likedUserId},
      );

      debugPrint('[LikeService] Response: ${response.data}');

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          response.data['success'] == true) {
        return response.data['data'];
      } else {
        throw Exception(response.data['message'] ?? 'Failed to send like');
      }
    } catch (e) {
      debugPrint('[LikeService] Error sending like: $e');
      if (e is DioException && e.response?.statusCode == 401) {
        await _storage.delete(key: 'access_token');
        await _storage.delete(key: 'refresh_token');
        throw Exception('UNAUTHORIZED');
      }
      throw Exception('Error sending like: $e');
    }
  }

  /// Unlike a user
  Future<void> unlikeUser(String likedUserId) async {
    try {
      final token = await _storage.read(key: 'access_token');
      _dio.options.headers['Authorization'] = 'Bearer $token';

      debugPrint('[LikeService] Unliking user: $likedUserId');

      final response = await _dio.delete('/likes/$likedUserId');

      if (response.statusCode != 200 || response.data['success'] != true) {
        throw Exception(response.data['message'] ?? 'Failed to unlike user');
      }
    } catch (e) {
      debugPrint('[LikeService] Error unliking user: $e');
      if (e is DioException && e.response?.statusCode == 401) {
        await _storage.delete(key: 'access_token');
        await _storage.delete(key: 'refresh_token');
        throw Exception('UNAUTHORIZED');
      }
      throw Exception('Error unliking user: $e');
    }
  }

  /// Get likes sent by the current user
  Future<List<dynamic>> getSentLikes() async {
    try {
      final token = await _storage.read(key: 'access_token');
      _dio.options.headers['Authorization'] = 'Bearer $token';

      final response = await _dio.get('/likes/sent');

      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data']['likes'] ?? [];
      } else {
        throw Exception(response.data['message'] ?? 'Failed to fetch sent likes');
      }
    } catch (e) {
      debugPrint('[LikeService] Error fetching sent likes: $e');
      if (e is DioException && e.response?.statusCode == 401) {
        await _storage.delete(key: 'access_token');
        await _storage.delete(key: 'refresh_token');
        throw Exception('UNAUTHORIZED');
      }
      throw Exception('Error fetching sent likes: $e');
    }
  }

  /// Get likes received by the current user
  Future<List<dynamic>> getReceivedLikes() async {
    try {
      final token = await _storage.read(key: 'access_token');
      _dio.options.headers['Authorization'] = 'Bearer $token';

      final response = await _dio.get('/likes/received');

      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data']['likes'] ?? [];
      } else {
        throw Exception(response.data['message'] ?? 'Failed to fetch received likes');
      }
    } catch (e) {
      debugPrint('[LikeService] Error fetching received likes: $e');
      if (e is DioException && e.response?.statusCode == 401) {
        await _storage.delete(key: 'access_token');
        await _storage.delete(key: 'refresh_token');
        throw Exception('UNAUTHORIZED');
      }
      throw Exception('Error fetching received likes: $e');
    }
  }

  /// Get mutual likes (matches)
  Future<List<dynamic>> getMutualLikes() async {
    try {
      final token = await _storage.read(key: 'access_token');
      _dio.options.headers['Authorization'] = 'Bearer $token';

      final response = await _dio.get('/likes/mutual');

      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data']['matches'] ?? [];
      } else {
        throw Exception(response.data['message'] ?? 'Failed to fetch mutual likes');
      }
    } catch (e) {
      debugPrint('[LikeService] Error fetching mutual likes: $e');
      if (e is DioException && e.response?.statusCode == 401) {
        await _storage.delete(key: 'access_token');
        await _storage.delete(key: 'refresh_token');
        throw Exception('UNAUTHORIZED');
      }
      throw Exception('Error fetching mutual likes: $e');
    }
  }

  /// Check if current user has liked another user
  Future<bool> checkIfLiked(String targetUserId) async {
    try {
      final token = await _storage.read(key: 'access_token');
      _dio.options.headers['Authorization'] = 'Bearer $token';

      final response = await _dio.get('/likes/check/$targetUserId');

      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data']['hasLiked'] ?? false;
      } else {
        return false;
      }
    } catch (e) {
      debugPrint('[LikeService] Error checking if liked: $e');
      return false;
    }
  }

  /// Get like statistics
  Future<Map<String, dynamic>> getLikeStats() async {
    try {
      final token = await _storage.read(key: 'access_token');
      _dio.options.headers['Authorization'] = 'Bearer $token';

      final response = await _dio.get('/likes/stats');

      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'] ?? {};
      } else {
        return {};
      }
    } catch (e) {
      debugPrint('[LikeService] Error fetching like stats: $e');
      return {};
    }
  }
}
