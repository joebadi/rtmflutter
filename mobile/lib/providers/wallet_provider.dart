import 'package:flutter/foundation.dart';
import '../services/wallet_service.dart';

/// Holds the user's diamond balance + packages app-wide so the wallet page,
/// chat screen, and balance chips all stay in sync.
class WalletProvider extends ChangeNotifier {
  final WalletService _service = WalletService();

  int _balance = 0;
  List<dynamic> _packages = [];
  bool _isLoading = false;
  bool _loadedOnce = false;

  int get balance => _balance;
  List<dynamic> get packages => _packages;
  bool get isLoading => _isLoading;
  bool get loadedOnce => _loadedOnce;

  /// Fetch balance + packages from the backend.
  Future<void> refresh() async {
    _isLoading = true;
    notifyListeners();
    try {
      final wallet = await _service.getWallet();
      _balance = (wallet['balance'] ?? 0) as int;
      _packages = (wallet['packages'] ?? []) as List<dynamic>;
      _loadedOnce = true;
    } catch (e) {
      debugPrint('[WalletProvider] refresh failed: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update the balance locally (e.g. after the server reports a new balance
  /// from sending a paid message) without a round-trip.
  void setBalance(int balance) {
    if (balance == _balance) return;
    _balance = balance;
    notifyListeners();
  }

  WalletService get service => _service;
}
