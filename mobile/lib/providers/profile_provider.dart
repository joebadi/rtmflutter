import 'package:flutter/material.dart';
import '../services/profile_service.dart';

class ProfileProvider extends ChangeNotifier {
  final ProfileService _profileService = ProfileService();

  Map<String, dynamic>? _profile;
  bool _isLoading = false;
  String? _error;

  Map<String, dynamic>? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasProfile => _profile != null;

  Future<void> fetchProfile() async {
    _setLoading(true);
    try {
      _profile = await _profileService.getMyProfile();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    _setLoading(true);
    try {
      final updated = await _profileService.updateProfile(data);
      _profile = updated;
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
