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

  /// Helper to handle Dio errors robustly (parses backend Zod errors)
  String _handleDioError(DioException e, String defaultMessage) {
    String errorMessage = defaultMessage;
    if (e.response != null) {
      // Check for 'message' field
      if (e.response!.data is Map) {
        final data = e.response!.data as Map;
        if (data.containsKey('message')) {
          errorMessage = data['message'];
        }

        // Check for 'errors' field (Zod/Backend validation details)
        if (data.containsKey('errors')) {
          final errors = data['errors'];
          if (errors is List) {
            final errorMessages = errors.map((err) {
              if (err is Map) {
                final path = (err['path'] as List?)?.join('.') ?? 'Field';
                return '$path: ${err['message']}';
              }
              return err.toString();
            }).join('\n');
            errorMessage = '$errorMessage\n$errorMessages';
          }
        }
      }
    } else if (e.type == DioExceptionType.connectionTimeout || 
               e.type == DioExceptionType.receiveTimeout) {
      errorMessage = 'Connection timeout. Please check your internet.';
    } else if (e.type == DioExceptionType.connectionError) {
      errorMessage = 'Connection error. Please check your internet.';
    }
    
    return errorMessage;
  }

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
      throw Exception(_handleDioError(e, 'Failed to fetch profile'));
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
      // If 404, it might mean the endpoint is wrong OR profile doesn't exist to update
      // But updateProfile usually creates/updates or we use a separate create.
      // Backend controller: updateProfile
      throw Exception(_handleDioError(e, 'Failed to update profile'));
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
      throw Exception(_handleDioError(e, 'Failed to upload photo'));
    }
  }

  /// Delete profile photo
  Future<void> deletePhoto(String photoId) async {
    final token = await _storage.read(key: 'access_token');
    if (token == null) throw Exception('Not authenticated');

    try {
      await _dio.delete(
        '${ApiConfig.profileBase}/photo/$photoId',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } on DioException catch (e) {
      throw Exception(_handleDioError(e, 'Failed to delete photo'));
    }
  }

  /// Save match preferences
  Future<Map<String, dynamic>> savePreferences(
    Map<String, dynamic> preferences,
  ) async {
    final token = await _storage.read(key: 'access_token');
    if (token == null) throw Exception('Not authenticated');

    try {
      final response = await _dio.post(
        ApiConfig.preferences,
        data: preferences,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(_handleDioError(e, 'Failed to save preferences'));
    }
  }

  /// Get match preferences
  Future<Map<String, dynamic>?> getPreferences() async {
    final token = await _storage.read(key: 'access_token');
    if (token == null) throw Exception('Not authenticated');

    try {
      final response = await _dio.get(
        ApiConfig.preferences,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw Exception(_handleDioError(e, 'Failed to get preferences'));
    }
  }
}
