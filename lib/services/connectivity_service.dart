// services/connectivity_service.dart - THEO DÕI KẾT NỐI MẠNG
// Dùng connectivity_plus: hệ điều hành báo khi đổi Wi-Fi / dữ liệu di động / mất mạng,
// không cần dò mạng định kỳ.
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class ConnectivityService with ChangeNotifier {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  bool _isOnline = true;
  bool get isOnline => _isOnline;
  StreamSubscription<List<ConnectivityResult>>? _sub;

  void start() {
    _sub ??= _connectivity.onConnectivityChanged.listen(_update);
    check();
  }

  Future<bool> check() async {
    try {
      _update(await _connectivity.checkConnectivity());
    } catch (_) {
      // Nền tảng không hỗ trợ (ví dụ môi trường test): giữ trạng thái hiện tại
    }
    return _isOnline;
  }

  void _update(List<ConnectivityResult> results) {
    final online = results.any((r) => r != ConnectivityResult.none);
    if (online == _isOnline) return;
    _isOnline = online;
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
