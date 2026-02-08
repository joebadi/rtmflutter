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

      debugPrint('[MessageService] Getting messages for conversation: $conversationId');

      // FIX: Correct endpoint is /messages/:conversationId NOT /messages/conversation/:conversationId
      final response = await _dio.get('/messages/$conversationId');

      debugPrint('[MessageService] Response status: ${response.statusCode}');

      if (response.statusCode == 200 && response.data['success'] == true) {
        final messages = response.data['data']['messages'] ?? [];
        debugPrint('[MessageService] Loaded ${messages.length} messages');
        return messages;
      } else {
        throw Exception(response.data['message'] ?? 'Failed to fetch messages');
      }
    } catch (e) {
      debugPrint('[MessageService] Error getting messages: $e');
      
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

      debugPrint('[MessageService] Sending message to $receiverId');

      final response = await _dio.post(
        '/messages/send',
        data: {
          'receiverId': receiverId,
          'content': content,
        },
      );

      debugPrint('[MessageService] Response status: ${response.statusCode}');
      debugPrint('[MessageService] Response data: ${response.data}');

      // Accept both 200 and 201 status codes
      if ((response.statusCode == 200 || response.statusCode == 201) && 
          response.data['success'] == true) {
        return response.data['data']['message'];
      } else {
        throw Exception(response.data['message'] ?? 'Failed to send message');
      }
    } catch (e) {
      debugPrint('[MessageService] Error: $e');
      
      if (e is DioException) {
        // Handle 401 Unauthorized
        if (e.response?.statusCode == 401) {
          await _storage.delete(key: 'access_token');
          await _storage.delete(key: 'refresh_token');
          throw Exception('UNAUTHORIZED');
        }
        
        // Extract error message from response
        if (e.response?.data != null) {
          final errorData = e.response!.data;
          if (errorData is Map && errorData['message'] != null) {
            final errorMessage = errorData['message'].toString();
            
            // Check for match requirement error
            if (errorMessage.contains('need to match') || 
                errorMessage.contains('match with this user')) {
              throw Exception('MATCH_REQUIRED');
            }
            
            // Throw the actual backend error message
            throw Exception(errorMessage);
          }
        }
      }
      
      // Parse match requirement error from string
      final errorMessage = e.toString();
      if (errorMessage.contains('need to match') || errorMessage.contains('match with this user')) {
        throw Exception('MATCH_REQUIRED');
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
