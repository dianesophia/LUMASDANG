import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'local_db_service.dart';
import 'firestore_service.dart';

class ConnectivityService {
  ConnectivityService._private();
  static final ConnectivityService instance = ConnectivityService._private();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription? _sub;

  Future<bool> checkOnline() async {
    try {
      final results = await _connectivity.checkConnectivity();

      // connectivity_plus v5+ returns List<ConnectivityResult>
      final hasConnection = results is List
          ? !(results as List).every((r) => r == ConnectivityResult.none)
          : results != ConnectivityResult.none;

      if (!hasConnection) return false;

      // On web, dart:io is unavailable — use http.get instead
      // On mobile, also use http.get for a real internet confirmation
      final response = await http
          .get(Uri.parse('https://www.google.com'))
          .timeout(const Duration(seconds: 4));

      return response.statusCode == 200;
    } catch (e) {
      print('ConnectivityService.checkOnline: error=$e');
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

  void startAutoSync({FirestoreService? firestoreService}) {
    print('ConnectivityService: startAutoSync called');
    startMonitoring((online) async {
      print('ConnectivityService.startAutoSync: online=$online');
      if (online) {
        try {
          final fs = firestoreService ?? FirestoreService();
          await LocalDbService.instance.init();
          final synced = await LocalDbService.instance.syncPending(fs);
          print('ConnectivityService.startAutoSync: syncPending result=$synced');
        } catch (e) {
          print('ConnectivityService.startAutoSync: error during sync $e');
        }
      }
    });
  }

  void stopMonitoring() {
    _sub?.cancel();
    _sub = null;
  }
}