import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  ConnectivityService._private();
  static final ConnectivityService instance = ConnectivityService._private();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult>? _sub;

  /// Returns a best-effort online status by checking connectivity result
  /// and doing a quick DNS lookup to confirm internet access.
  Future<bool> checkOnline() async {
    try {
      final result = await _connectivity.checkConnectivity();
      if (result == ConnectivityResult.none) return false;

      // Confirm by doing a lightweight DNS lookup.
      final lookup = await InternetAddress.lookup('example.com');
      return lookup.isNotEmpty && lookup.first.rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  void startMonitoring(void Function(bool online) onStatusChanged) {
    _sub?.cancel();
    _sub = _connectivity.onConnectivityChanged.listen((result) async {
      final online = await checkOnline();
      onStatusChanged(online);
    });
  }

  void stopMonitoring() {
    _sub?.cancel();
    _sub = null;
  }
}
