import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Holds the app-wide light/dark preference and persists it.
class ThemeProvider extends ChangeNotifier {
  static const _key = 'theme_mode'; // 'light' | 'dark' | 'system'
  final _storage = const FlutterSecureStorage();

  ThemeMode _mode = ThemeMode.dark;
  ThemeMode get mode => _mode;

  bool isDark(BuildContext context) {
    if (_mode == ThemeMode.system) {
      return MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    }
    return _mode == ThemeMode.dark;
  }

  Future<void> load() async {
    try {
      final saved = await _storage.read(key: _key);
      switch (saved) {
        case 'light':
          _mode = ThemeMode.light;
          break;
        case 'system':
          _mode = ThemeMode.system;
          break;
        case 'dark':
          _mode = ThemeMode.dark;
          break;
      }
      notifyListeners();
    } catch (_) {
      // Keep the default on any read error.
    }
  }

  Future<void> setMode(ThemeMode mode) async {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
    try {
      await _storage.write(
        key: _key,
        value: mode == ThemeMode.light
            ? 'light'
            : mode == ThemeMode.system
                ? 'system'
                : 'dark',
      );
    } catch (_) {}
  }

  Future<void> toggle() =>
      setMode(_mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
}
