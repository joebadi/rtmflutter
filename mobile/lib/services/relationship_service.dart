import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';

/// Saved / Hidden / Blocked profile relationships.
class RelationshipService {
  final Dio _dio = Dio();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  RelationshipService() {
    _dio.options.baseUrl = ApiConfig.baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);
  }

  Future<Options> _auth() async {
    final token = await _storage.read(key: 'access_token');
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  Future<List<dynamic>> _getList(String path) async {
    try {
      final res = await _dio.get(path, options: await _auth());
      if (res.statusCode == 200 && res.data['success'] == true) {
        return res.data['data']['profiles'] ?? [];
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load: $e');
    }
  }

  Future<void> _send(String method, String path) async {
    await _dio.request(path,
        options: Options(
          method: method,
          headers: (await _auth()).headers,
        ));
  }

  // Saved
  Future<List<dynamic>> getSaved() => _getList('/relationships/saved');
  Future<void> save(String userId) => _send('POST', '/relationships/saved/$userId');
  Future<void> unsave(String userId) =>
      _send('DELETE', '/relationships/saved/$userId');

  // Hidden
  Future<List<dynamic>> getHidden() => _getList('/relationships/hidden');
  Future<void> hide(String userId) => _send('POST', '/relationships/hidden/$userId');
  Future<void> unhide(String userId) =>
      _send('DELETE', '/relationships/hidden/$userId');

  // Blocked (block/unblock live under /messages/block)
  Future<List<dynamic>> getBlocked() => _getList('/relationships/blocked');
  Future<void> block(String userId) async {
    await _dio.post('/messages/block',
        data: {'blockedUserId': userId}, options: await _auth());
  }

  Future<void> unblock(String userId) =>
      _send('DELETE', '/messages/block/$userId');
}
