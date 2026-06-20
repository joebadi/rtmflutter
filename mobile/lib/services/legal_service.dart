import 'package:dio/dio.dart';
import '../config/api_config.dart';

/// Fetches editable legal documents (privacy_policy | terms_of_use) served by
/// the backend and edited from the admin panel.
class LegalService {
  final Dio _dio = Dio();

  /// Returns the document `{ slug, title, content, updatedAt }` or null.
  Future<Map<String, dynamic>?> fetch(String slug) async {
    final res = await _dio.get(ApiConfig.legalDocument(slug));
    if (res.statusCode == 200 && res.data['success'] == true) {
      final doc = res.data['data']?['document'];
      return doc is Map ? Map<String, dynamic>.from(doc) : null;
    }
    return null;
  }
}
