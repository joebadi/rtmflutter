import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import '../config/api_config.dart';

/// Background isolate handler — must be a top-level function annotated for AOT.
/// Data-only messages arrive here when the app is killed/backgrounded.
@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
  // Firebase must be initialized in the background isolate too.
  try {
    await Firebase.initializeApp();
  } catch (_) {}
  debugPrint('[Push] bg message: ${message.messageId}');
}

/// Firebase Cloud Messaging integration.
///
/// Degrades gracefully: if Firebase isn't configured yet (no google-services.json),
/// [initialize] no-ops and the app runs without push. Once the config file is
/// added, push activates on next launch — no code change needed.
class PushService {
  PushService._();
  static final PushService instance = PushService._();

  final _storage = const FlutterSecureStorage();
  final _dio = Dio();
  final _local = FlutterLocalNotificationsPlugin();

  bool _enabled = false;
  String? _token;

  /// Called when the user taps a notification. The app sets this to route
  /// (e.g. open the relevant chat). Receives the message's `data` map.
  void Function(Map<String, dynamic> data)? onTap;

  bool get enabled => _enabled;
  String? get token => _token;

  static const _androidChannel = AndroidNotificationChannel(
    'rtm_default',
    'General',
    description: 'Messages, matches and activity',
    importance: Importance.high,
  );

  /// Safe to call at startup. Initializes Firebase + FCM if configured.
  Future<void> initialize() async {
    try {
      await Firebase.initializeApp();
    } catch (e) {
      // No FirebaseOptions (google-services.json absent) — push disabled.
      debugPrint('[Push] Firebase not configured; push disabled ($e)');
      _enabled = false;
      return;
    }

    _enabled = true;

    // Local notifications (for foreground display).
    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _local.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (resp) {
        final data = _decodePayload(resp.payload);
        if (data != null) onTap?.call(data);
      },
    );
    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_androidChannel);

    // Permissions (Android 13+ / iOS).
    await FirebaseMessaging.instance.requestPermission();

    // Foreground messages → show a local banner.
    FirebaseMessaging.onMessage.listen(_showForeground);

    // Taps that opened the app from background.
    FirebaseMessaging.onMessageOpenedApp.listen((m) => onTap?.call(_data(m)));

    // Cold start from a notification tap.
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) onTap?.call(_data(initial));

    // Token + refresh.
    _token = await FirebaseMessaging.instance.getToken();
    FirebaseMessaging.instance.onTokenRefresh.listen((t) {
      _token = t;
      syncTokenToBackend();
    });
    debugPrint('[Push] token: ${_token?.substring(0, 12)}…');
  }

  /// Send the current FCM token to the backend (call after login).
  Future<void> syncTokenToBackend() async {
    if (!_enabled) return;
    final token = _token ?? await FirebaseMessaging.instance.getToken();
    if (token == null) return;
    _token = token;
    try {
      final auth = await _storage.read(key: 'access_token');
      if (auth == null) return;
      await _dio.post(
        '${ApiConfig.baseUrl}/notifications/device-token',
        data: {'token': token, 'platform': defaultTargetPlatform.name},
        options: Options(headers: {'Authorization': 'Bearer $auth'}),
      );
      debugPrint('[Push] token synced to backend');
    } catch (e) {
      debugPrint('[Push] token sync failed: $e');
    }
  }

  /// Remove the token from the backend (call on logout).
  Future<void> clearToken() async {
    if (!_enabled) return;
    try {
      final auth = await _storage.read(key: 'access_token');
      if (auth == null) return;
      await _dio.delete(
        '${ApiConfig.baseUrl}/notifications/device-token',
        options: Options(headers: {'Authorization': 'Bearer $auth'}),
      );
    } catch (_) {}
    try {
      await FirebaseMessaging.instance.deleteToken();
    } catch (_) {}
    _token = null;
  }

  Future<void> _showForeground(RemoteMessage message) async {
    final n = message.notification;
    if (n == null) return;
    await _local.show(
      id: n.hashCode,
      title: n.title,
      body: n.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: _encodePayload(message.data),
    );
  }

  Map<String, dynamic> _data(RemoteMessage m) =>
      m.data.map((k, v) => MapEntry(k, v));

  String _encodePayload(Map<String, dynamic> data) =>
      data.entries.map((e) => '${e.key}=${e.value}').join('&');

  Map<String, dynamic>? _decodePayload(String? payload) {
    if (payload == null || payload.isEmpty) return null;
    final map = <String, dynamic>{};
    for (final pair in payload.split('&')) {
      final i = pair.indexOf('=');
      if (i > 0) map[pair.substring(0, i)] = pair.substring(i + 1);
    }
    return map;
  }
}
