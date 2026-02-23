import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'local_db_service.dart';
import 'firestore_service.dart';

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
      print('ConnectivityService: connectivity changed -> online=$online');
      onStatusChanged(online);
    });
  }

  /// Convenience helper to automatically sync pending local records when
  /// connection is restored. Will use provided FirestoreService or create one.
  void startAutoSync({FirestoreService? firestoreService}) {
    print('ConnectivityService: startAutoSync called');
    startMonitoring((online) async {
      print('ConnectivityService.startAutoSync: online=$online');
      if (online) {
        try {
          final fs = firestoreService ?? FirestoreService();
          await LocalDbService.instance.init();
          print('ConnectivityService.startAutoSync: running LocalDbService.syncPending');
          final synced = await LocalDbService.instance.syncPending(fs);
          print('ConnectivityService.startAutoSync: syncPending result=$synced');
        } catch (e) {
          print('ConnectivityService.startAutoSync: error during sync $e');
          // swallow; will retry on next connection change
        }
      }
    });
  }

  void stopMonitoring() {
    _sub?.cancel();
    _sub = null;
  }
}
