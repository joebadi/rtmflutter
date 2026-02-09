import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import '../config/api_config.dart';

class NotificationService extends ChangeNotifier {
  final _storage = const FlutterSecureStorage();
  final Dio _dio = Dio();
  IO.Socket? _socket;
  int _unreadCount = 0;
  bool _initialized = false;
  
  int get unreadCount => _unreadCount;

  Future<void> init() async {
    if (_initialized) return;
    
    // 1. Fetch initial count from API
    await _fetchInitialCount();
    
    // 2. Connect Socket
    await _connectSocket();
    
    _initialized = true;
  }

  Future<void> _fetchInitialCount() async {
    try {
      final token = await _storage.read(key: 'accessToken');
      if (token == null) return;
      
      final response = await _dio.get(
        '${ApiConfig.baseUrl}/notifications/unread-count',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      
      if (response.statusCode == 200) {
        _unreadCount = response.data['unreadCount'] ?? 0;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching notification count: $e');
    }
  }

  Future<void> _connectSocket() async {
    final token = await _storage.read(key: 'accessToken');
    if (token == null) return;

    // Initialize socket
    _socket = IO.io(ApiConfig.socketUrl, IO.OptionBuilder()
      .setTransports(['websocket'])
      .setAuth({'token': token})
      .enableAutoConnect()
      .build());

    _socket!.onConnect((_) {
      debugPrint('Socket connected');
    });

    _socket!.onConnectError((err) {
      debugPrint('Socket connection error: $err');
    });

    _socket!.on('notification', (data) {
      debugPrint('Received notification: $data');
      _unreadCount++;
      notifyListeners();
    });
    
    _socket!.connect();
  }
  
  Future<void> markAllRead() async {
    try {
      final token = await _storage.read(key: 'accessToken');
      if (token == null) return;

      await _dio.patch(
        '${ApiConfig.baseUrl}/notifications/read-all',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      
      _unreadCount = 0;
      notifyListeners();
    } catch (e) {
      debugPrint('Error marking all read: $e');
    }
  }

  @override
  void dispose() {
    _socket?.disconnect();
    _socket?.dispose();
    super.dispose();
  }
}
