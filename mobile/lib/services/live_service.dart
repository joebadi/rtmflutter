import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';

/// Talks to the Live Dates endpoints (`/api/live`).
class LiveService {
  final Dio _dio = Dio();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  LiveService() {
    _dio.options.baseUrl = ApiConfig.baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 15);
    _dio.options.receiveTimeout = const Duration(seconds: 15);
  }

  Future<void> _attachToken() async {
    final token = await _storage.read(key: 'access_token');
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  /// Upcoming + live events, each decorated with my booking status.
  Future<List<dynamic>> getEvents() async {
    await _attachToken();
    final response = await _dio.get('/live/events');
    if (response.statusCode == 200 && response.data['success'] == true) {
      return response.data['data']['events'] ?? [];
    }
    throw Exception(response.data['message'] ?? 'Failed to load events');
  }

  Future<Map<String, dynamic>> getEvent(String id) async {
    await _attachToken();
    final response = await _dio.get('/live/events/$id');
    if (response.statusCode == 200 && response.data['success'] == true) {
      return Map<String, dynamic>.from(response.data['data']['event']);
    }
    throw Exception(response.data['message'] ?? 'Failed to load event');
  }

  /// Book a slot. Throws 'INSUFFICIENT_DIAMONDS' when the user can't afford it.
  Future<Map<String, dynamic>> bookEvent(String id) async {
    await _attachToken();
    try {
      final response = await _dio.post('/live/events/$id/book');
      if (response.statusCode == 200 && response.data['success'] == true) {
        return Map<String, dynamic>.from(response.data['data']['booking']);
      }
      throw Exception(response.data['message'] ?? 'Failed to book');
    } catch (e) {
      if (e is DioException && e.response?.data is Map) {
        final data = e.response!.data as Map;
        if (data['code'] == 'INSUFFICIENT_DIAMONDS') {
          throw Exception('INSUFFICIENT_DIAMONDS');
        }
        throw Exception(data['message'] ?? 'Failed to book');
      }
      rethrow;
    }
  }

  Future<void> cancelBooking(String id) async {
    await _attachToken();
    try {
      await _dio.delete('/live/events/$id/book');
    } catch (e) {
      debugPrint('[LiveService] cancel failed: $e');
      rethrow;
    }
  }

  // ----- Realtime lobby / rounds -----

  Future<void> joinLobby(String eventId) async {
    await _attachToken();
    await _dio.post('/live/events/$eventId/lobby');
  }

  /// { status, roundNumber, maxRounds, myPairing }
  Future<Map<String, dynamic>> getEventState(String eventId) async {
    await _attachToken();
    final response = await _dio.get('/live/events/$eventId/state');
    if (response.statusCode == 200 && response.data['success'] == true) {
      return Map<String, dynamic>.from(response.data['data']);
    }
    throw Exception(response.data['message'] ?? 'Failed to load event state');
  }

  /// Agora token bound to a specific pairing channel.
  Future<Map<String, dynamic>> getPairingToken(String pairingId) async {
    await _attachToken();
    final response = await _dio.post('/live/pairings/$pairingId/token');
    if (response.statusCode == 200 && response.data['success'] == true) {
      return Map<String, dynamic>.from(response.data['data']);
    }
    throw Exception(response.data['message'] ?? 'Failed to get call token');
  }

  Future<bool> sendInterest(String pairingId, bool interested) async {
    await _attachToken();
    final response = await _dio.post(
      '/live/pairings/$pairingId/interest',
      data: {'interested': interested},
    );
    return response.data['data']?['matched'] == true;
  }

  Future<void> ratePairing(String pairingId, int rating) async {
    await _attachToken();
    await _dio.post('/live/pairings/$pairingId/rate', data: {'rating': rating});
  }

  /// Reveal a blind-date partner. Throws 'INSUFFICIENT_DIAMONDS' when a paid
  /// unveil can't be afforded. Returns { partner, charged, free, diamondBalance,
  /// unveilsRemaining, unveilCost, ... }.
  Future<Map<String, dynamic>> unveilPartner(String pairingId) async {
    await _attachToken();
    try {
      final response = await _dio.post('/live/pairings/$pairingId/unveil');
      if (response.statusCode == 200 && response.data['success'] == true) {
        return Map<String, dynamic>.from(response.data['data']);
      }
      throw Exception(response.data['message'] ?? 'Failed to unveil');
    } catch (e) {
      if (e is DioException && e.response?.data is Map) {
        final data = e.response!.data as Map;
        if (data['code'] == 'INSUFFICIENT_DIAMONDS') {
          throw Exception('INSUFFICIENT_DIAMONDS');
        }
        throw Exception(data['message'] ?? 'Failed to unveil');
      }
      rethrow;
    }
  }

  /// Post-event results: { event, blind, matches, unveils, pairings: [...] }.
  Future<Map<String, dynamic>> getEventResults(String eventId) async {
    await _attachToken();
    final response = await _dio.get('/live/events/$eventId/results');
    if (response.statusCode == 200 && response.data['success'] == true) {
      return Map<String, dynamic>.from(response.data['data']);
    }
    throw Exception(response.data['message'] ?? 'Failed to load results');
  }
}
