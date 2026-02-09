import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../config/api_config.dart';

class MessageProvider extends ChangeNotifier {
  final Dio _dio = Dio();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  IO.Socket? _socket;

  // State
  int _unreadCount = 0;
  bool _isLoading = false;

  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  IO.Socket? get socket => _socket;

  MessageProvider() {
    _dio.options.baseUrl = ApiConfig.baseUrl;
  }

  // Initialize: connect socket and fetch count
  Future<void> init() async {
    await Future.wait([
      _connectSocket(),
      fetchUnreadCount(),
    ]);
  }

  Future<void> _connectSocket() async {
    try {
      final token = await _storage.read(key: 'access_token');
      if (token == null) return;

      if (_socket != null && _socket!.connected) return;

      _socket = IO.io(
        ApiConfig.socketUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .setAuth({'token': token})
            .enableAutoConnect()
            .build(),
      );

      _socket!.onConnect((_) {
        debugPrint('[MessageProvider] Socket connected');
      });

      _socket!.onDisconnect((_) {
        debugPrint('[MessageProvider] Socket disconnected');
      });

      // Listen for new messages
      _socket!.on('new_message', (data) {
        debugPrint('[MessageProvider] New message received: $data');
        _incrementUnreadCount();
      });

      // Listen for read events (from other devices or self)
      _socket!.on('conversation_read', (data) {
        debugPrint('[MessageProvider] Conversation read: $data');
        // Since we don't know exactly how many were unread in that specific conversation
        // without complex state tracking, simple re-fetch is safest.
        fetchUnreadCount();
      });

      _socket!.connect();
    } catch (e) {
      debugPrint('[MessageProvider] Socket connection error: $e');
    }
  }

  Future<void> fetchUnreadCount() async {
    try {
      final token = await _storage.read(key: 'access_token');
      if (token == null) return;

      _dio.options.headers['Authorization'] = 'Bearer $token';

      final response = await _dio.get('/messages/unread/count');

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
        _unreadCount = data['totalUnread'] ?? 0;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[MessageProvider] Error fetching unread count: $e');
    }
  }

  void _incrementUnreadCount() {
    _unreadCount++;
    notifyListeners();
  }
  
  // Optimistic update when user enters a chat
  void markAsReadLocally() {
    // This is tricky without knowing how many unread in that specific chat.
    // For now, let's rely on fetchUnreadCount() triggered by navigation or explicit refresh.
    // Or call fetchUnreadCount() immediately.
    fetchUnreadCount();
  }

  @override
  void dispose() {
    _socket?.disconnect();
    _socket?.dispose();
    super.dispose();
  }
}
