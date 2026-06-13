import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';

/// Talks to the backend diamond wallet / payment endpoints.
class WalletService {
  final Dio _dio = Dio();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  WalletService() {
    _dio.options.baseUrl = ApiConfig.baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 15);
    _dio.options.receiveTimeout = const Duration(seconds: 15);
  }

  Future<void> _attachToken() async {
    final token = await _storage.read(key: 'access_token');
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  /// Returns the wallet: { balance, packages }.
  Future<Map<String, dynamic>> getWallet() async {
    await _attachToken();
    final response = await _dio.get('/payments/wallet');
    if (response.statusCode == 200 && response.data['success'] == true) {
      return Map<String, dynamic>.from(response.data['data']);
    }
    throw Exception(response.data['message'] ?? 'Failed to load wallet');
  }

  /// Diamond packages available for purchase.
  Future<List<dynamic>> getPackages() async {
    await _attachToken();
    final response = await _dio.get('/payments/packages');
    if (response.statusCode == 200 && response.data['success'] == true) {
      return response.data['data']['packages'] ?? [];
    }
    throw Exception(response.data['message'] ?? 'Failed to load packages');
  }

  /// Start a purchase. Returns { reference, authorizationUrl, accessCode }.
  /// Throws 'PAYMENT_NOT_CONFIGURED' if the server has no payment provider set.
  Future<Map<String, dynamic>> initializePurchase(String packageId) async {
    await _attachToken();
    try {
      final response = await _dio.post(
        '/payments/initialize',
        data: {'packageId': packageId},
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        return Map<String, dynamic>.from(response.data['data']);
      }
      throw Exception(response.data['message'] ?? 'Failed to initialize payment');
    } catch (e) {
      if (e is DioException && e.response?.data is Map) {
        final data = e.response!.data as Map;
        if (data['code'] == 'PAYMENT_NOT_CONFIGURED') {
          throw Exception('PAYMENT_NOT_CONFIGURED');
        }
        throw Exception(data['message'] ?? 'Failed to initialize payment');
      }
      rethrow;
    }
  }

  /// Verify a payment by reference after the user completes checkout.
  /// Returns { status, diamonds, balance }.
  Future<Map<String, dynamic>> verifyPurchase(String reference) async {
    await _attachToken();
    final response = await _dio.get('/payments/verify/$reference');
    if (response.statusCode == 200 && response.data['success'] == true) {
      return Map<String, dynamic>.from(response.data['data']);
    }
    throw Exception(response.data['message'] ?? 'Verification failed');
  }

  /// Purchase history.
  Future<List<dynamic>> getTransactions() async {
    await _attachToken();
    final response = await _dio.get('/payments/transactions');
    if (response.statusCode == 200 && response.data['success'] == true) {
      return response.data['data']['transactions'] ?? [];
    }
    return [];
  }
}
