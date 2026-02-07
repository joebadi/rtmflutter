import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';

class MessageService {
  final Dio _dio = Dio();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  MessageService() {
    _dio.options.baseUrl = ApiConfig.baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);
  }

  /// Get all conversations for the current user
  Future<List<dynamic>> getConversations() async {
    try {
      final token = await _storage.read(key: 'access_token');
      _dio.options.headers['Authorization'] = 'Bearer $token';

      final response = await _dio.get('/messages/conversations');

      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data']['conversations'] ?? [];
      } else {
        throw Exception(response.data['message'] ?? 'Failed to fetch conversations');
      }
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 401) {
        await _storage.delete(key: 'access_token');
        await _storage.delete(key: 'refresh_token');
        throw Exception('UNAUTHORIZED');
      }
      throw Exception('Error fetching conversations: $e');
    }
  }

  /// Get messages in a specific conversation
  Future<List<dynamic>> getMessages(String conversationId) async {
    try {
      final token = await _storage.read(key: 'access_token');
      _dio.options.headers['Authorization'] = 'Bearer $token';

      final response = await _dio.get('/messages/conversation/$conversationId');

      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data']['messages'] ?? [];
      } else {
        throw Exception(response.data['message'] ?? 'Failed to fetch messages');
      }
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 401) {
        await _storage.delete(key: 'access_token');
        await _storage.delete(key: 'refresh_token');
        throw Exception('UNAUTHORIZED');
      }
      throw Exception('Error fetching messages: $e');
    }
  }

  /// Send a message to a user
  Future<Map<String, dynamic>> sendMessage({
    required String receiverId,
    required String content,
  }) async {
    try {
      final token = await _storage.read(key: 'access_token');
      _dio.options.headers['Authorization'] = 'Bearer $token';

      final response = await _dio.post(
        '/messages/send',
        data: {
          'receiverId': receiverId,
          'content': content,
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data']['message'];
      } else {
        throw Exception(response.data['message'] ?? 'Failed to send message');
      }
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 401) {
        await _storage.delete(key: 'access_token');
        await _storage.delete(key: 'refresh_token');
        throw Exception('UNAUTHORIZED');
      }
      throw Exception('Error sending message: $e');
    }
  }

  /// Mark a message as read
  Future<void> markAsRead(String messageId) async {
    try {
      final token = await _storage.read(key: 'access_token');
      _dio.options.headers['Authorization'] = 'Bearer $token';

      await _dio.patch('/messages/$messageId/read');
    } catch (e) {
      debugPrint('Error marking message as read: $e');
    }
  }

  /// Mark all messages in a conversation as read
  Future<void> markConversationAsRead(String conversationId) async {
    try {
      final token = await _storage.read(key: 'access_token');
      _dio.options.headers['Authorization'] = 'Bearer $token';

      await _dio.patch('/messages/conversation/$conversationId/read');
    } catch (e) {
      debugPrint('Error marking conversation as read: $e');
    }
  }

  /// Get or create a conversation with a specific user
  Future<String> getOrCreateConversation(String receiverId) async {
    try {
      final token = await _storage.read(key: 'access_token');
      _dio.options.headers['Authorization'] = 'Bearer $token';

      // First, try to find existing conversation
      final conversations = await getConversations();
      for (var conv in conversations) {
        final otherUser = conv['otherUser'];
        if (otherUser != null && otherUser['id'].toString() == receiverId) {
          return conv['id'].toString();
        }
      }

      // If no conversation exists, send a message to create one
      // The backend will create a conversation when we send the first message
      // For now, we'll use the receiverId as a temporary conversationId
      // and let the chat screen handle the first message send
      return receiverId;
    } catch (e) {
      debugPrint('Error getting/creating conversation: $e');
      // Return receiverId as fallback
      return receiverId;
    }
  }
}
