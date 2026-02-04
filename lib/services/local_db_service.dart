import 'package:hive_flutter/hive_flutter.dart';

import 'firestore_service.dart';

/// Local DB service using Hive to cache homepage data for offline support.
class LocalDbService {
  LocalDbService._private();
  static final LocalDbService instance = LocalDbService._private();

  static const String _boxName = 'homepageData';
  late Box _box;

  Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox(_boxName);
  }

  /// Save a local record. Returns the local key (int).
  /// record example: { 'data': Map<String,dynamic>, 'createdAt': DateTime, 'synced': bool, 'firestoreId': String? }
  Future<int> saveLocalRecord(Map<String, dynamic> data, {bool synced = false, String? firestoreId}) async {
    final record = {
      'data': data,
      'createdAt': DateTime.now().toIso8601String(),
      'synced': synced,
      'firestoreId': firestoreId,
    };
    return await _box.add(record);
  }

  /// Returns list of Map containing local key and value
  Future<List<Map<String, dynamic>>> getUnsyncedRecords() async {
    final results = <Map<String, dynamic>>[];
    for (var i = 0; i < _box.length; i++) {
      final value = _box.getAt(i) as Map;
      if (value['synced'] == false) {
        results.add({'key': i, 'value': Map<String, dynamic>.from(value)});
      }
    }
    return results;
  }

  Future<void> markAsSynced(int localKey, String firestoreId) async {
    final value = _box.getAt(localKey) as Map;
    final updated = Map<String, dynamic>.from(value);
    updated['synced'] = true;
    updated['firestoreId'] = firestoreId;
    await _box.putAt(localKey, updated);
  }

  Future<void> saveAndSync(Map<String, dynamic> data, FirestoreService firestoreService) async {
    // Save locally as pending first
    final localKey = await saveLocalRecord(data, synced: false);

    // Attempt to push to Firestore
    try {
      final docId = await firestoreService.saveHomePageData(data);
      await markAsSynced(localKey, docId);
    } catch (e) {
      // keep record as unsynced; caller can notify user
      rethrow;
    }
  }

  /// Try to sync all unsynced records through the provided FirestoreService
  /// Returns number of successfully synced records.
  Future<int> syncPending(FirestoreService firestoreService) async {
    final unsynced = await getUnsyncedRecords();
    int success = 0;

    for (final item in unsynced) {
      final int key = item['key'] as int;
      final Map<String, dynamic> value = item['value'] as Map<String, dynamic>;
      final data = Map<String, dynamic>.from(value['data'] as Map);
      try {
        final docId = await firestoreService.saveHomePageData(data);
        await markAsSynced(key, docId);
        success++;
      } catch (_) {
        // leave unsynced if error
      }
    }
    return success;
  }

  Future<List<Map<String, dynamic>>> getAllRecords() async {
    final results = <Map<String, dynamic>>[];
    for (var i = 0; i < _box.length; i++) {
      final value = _box.getAt(i) as Map;
      results.add({'key': i, 'value': Map<String, dynamic>.from(value)});
    }
    return results;
  }
}
