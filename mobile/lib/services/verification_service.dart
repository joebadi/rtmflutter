import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';

class VerificationService {
  final Dio _dio = Dio();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  VerificationService() {
    _dio.options.baseUrl = ApiConfig.baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 15);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
  }

  Future<Map<String, String>> _headers() async {
    final token = await _storage.read(key: 'access_token');
    return {'Authorization': 'Bearer $token'};
  }

  /// Returns the current verification request, or null if none submitted.
  Future<Map<String, dynamic>?> getStatus() async {
    try {
      final res = await _dio.get('/verification',
          options: Options(headers: await _headers()));
      if (res.statusCode == 200 && res.data['success'] == true) {
        final v = res.data['data']?['verification'];
        return v is Map ? Map<String, dynamic>.from(v) : null;
      }
    } catch (_) {}
    return null;
  }

  /// Submits a selfie + ID document for review. Returns true on success.
  Future<bool> submit({required String selfiePath, required String idPath}) async {
    final form = FormData.fromMap({
      'selfie': await MultipartFile.fromFile(selfiePath, filename: 'selfie.jpg'),
      'idDocument':
          await MultipartFile.fromFile(idPath, filename: 'id.jpg'),
    });
    final res = await _dio.post('/verification',
        data: form, options: Options(headers: await _headers()));
    return (res.statusCode == 200 || res.statusCode == 201) &&
        res.data['success'] == true;
  }
}
