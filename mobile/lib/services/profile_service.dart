import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';

class ProfileService {
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: ApiConfig.connectTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
    ),
  );
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  /// Get my profile
  Future<Map<String, dynamic>?> getMyProfile() async {
    final token = await _storage.read(key: 'access_token');
    if (token == null) return null;

    try {
      final response = await _dio.get(
        ApiConfig.myProfile,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null; // No profile yet
      throw Exception(e.response?.data['message'] ?? 'Failed to fetch profile');
    }
  }

  /// Update my profile
  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    final token = await _storage.read(key: 'access_token');
    if (token == null) throw Exception('Not authenticated');

    try {
      final response = await _dio.put(
        ApiConfig.updateProfile,
        data: data,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to update profile',
      );
    }
  }

  /// Upload profile photo
  Future<Map<String, dynamic>> uploadPhoto(String filePath) async {
    final token = await _storage.read(key: 'access_token');
    if (token == null) throw Exception('Not authenticated');

    try {
      FormData formData = FormData.fromMap({
        'photo': await MultipartFile.fromFile(filePath),
      });

      final response = await _dio.post(
        ApiConfig.uploadPhoto,
        data: formData,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to upload photo');
    }
  }

  /// Delete profile photo
  Future<void> deletePhoto(String photoId) async {
    final token = await _storage.read(key: 'access_token');
    if (token == null) throw Exception('Not authenticated');

    try {
      await _dio.delete(
        '${ApiConfig.uploadPhoto}/$photoId',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to delete photo');
    }
  }

  /// Update match preferences
  Future<Map<String, dynamic>> updatePreferences(
    Map<String, dynamic> preferences,
  ) async {
    final token = await _storage.read(key: 'access_token');
    if (token == null) throw Exception('Not authenticated');

    try {
      final response = await _dio.put(
        ApiConfig.updatePreferences,
        data: preferences,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to update preferences',
      );
    }
  }
}
