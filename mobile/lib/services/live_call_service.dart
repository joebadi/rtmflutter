import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';

/// Fetches Agora RTC tokens from the backend for Live Dates calls.
class LiveCallService {
  final Dio _dio = Dio();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  LiveCallService() {
    _dio.options.baseUrl = ApiConfig.baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 15);
    _dio.options.receiveTimeout = const Duration(seconds: 15);
  }

  /// Returns { appId, channelName, uid, token, expiresAt }.
  /// Throws 'AGORA_NOT_CONFIGURED' if the server has no Agora credentials.
  Future<Map<String, dynamic>> getRtcToken(String channelName) async {
    final token = await _storage.read(key: 'access_token');
    _dio.options.headers['Authorization'] = 'Bearer $token';
    try {
      final response = await _dio.post(
        '/live/rtc/token',
        data: {'channelName': channelName},
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        return Map<String, dynamic>.from(response.data['data']);
      }
      throw Exception(response.data['message'] ?? 'Failed to get call token');
    } catch (e) {
      if (e is DioException && e.response?.data is Map) {
        final data = e.response!.data as Map;
        if (data['code'] == 'AGORA_NOT_CONFIGURED') {
          throw Exception('AGORA_NOT_CONFIGURED');
        }
        throw Exception(data['message'] ?? 'Failed to get call token');
      }
      rethrow;
    }
  }
}
