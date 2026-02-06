import 'package:hive_flutter/hive_flutter.dart';
import 'firestore_service.dart';

class LocalDbService {
  LocalDbService._private();
  static final LocalDbService instance = LocalDbService._private();

  static const String _boxName = 'homepageData';
  late Box _box;
  bool _initialized = false;

  /// Initialize Hive
  Future<void> init() async {
    if (_initialized) return;

    await Hive.initFlutter();

    if (!Hive.isBoxOpen(_boxName)) {
      _box = await Hive.openBox(_boxName);
    } else {
      _box = Hive.box(_boxName);
    }

    _initialized = true;
  }

  Box get box {
    if (!_initialized) throw Exception("LocalDbService not initialized. Call init() first.");
    return _box;
  }

  /// Save a local record
  Future<int> saveLocalRecord(Map<String, dynamic> data,
      {bool synced = false, String? firestoreId}) async {
    final record = {
      'data': data,
      'createdAt': DateTime.now().toIso8601String(),
      'synced': synced,
      'firestoreId': firestoreId,
      'isDeleted': false, // Soft delete flag
    };
    return await box.add(record);
  }

  /// Get all records (optionally include deleted)
  Future<List<Map<String, dynamic>>> getAllRecords({bool includeDeleted = false}) async {
    final results = <Map<String, dynamic>>[];
    for (var i = 0; i < box.length; i++) {
      final value = box.getAt(i);
      if (value is Map) {
        if (!includeDeleted && value['isDeleted'] == true) continue;
        results.add({'key': i, 'value': Map<String, dynamic>.from(value)});
      }
    }
    return results;
  }

  /// Get unsynced records
  Future<List<Map<String, dynamic>>> getUnsyncedRecords() async {
    final results = <Map<String, dynamic>>[];
    for (var i = 0; i < box.length; i++) {
      final value = box.getAt(i);
      if (value is Map && value['synced'] == false && value['isDeleted'] == false) {
        results.add({'key': i, 'value': Map<String, dynamic>.from(value)});
      }
    }
    return results;
  }

  /// Mark a local record as synced
  Future<void> markAsSynced(int localKey, String firestoreId) async {
    final value = box.getAt(localKey);
    if (value is Map) {
      final updated = Map<String, dynamic>.from(value);
      updated['synced'] = true;
      updated['firestoreId'] = firestoreId;
      await box.putAt(localKey, updated);
    }
  }

  /// Save and sync a record to Firestore
  Future<void> saveAndSync(Map<String, dynamic> data, FirestoreService firestoreService) async {
    final localKey = await saveLocalRecord(data, synced: false);
    try {
      final docId = await firestoreService.saveHomePageData(data);
      await markAsSynced(localKey, docId);
    } catch (_) {
      // Keep unsynced if Firestore fails
      rethrow;
    }
  }

  /// Sync all pending local records
  Future<int> syncPending(FirestoreService firestoreService) async {
    final unsynced = await getUnsyncedRecords();
    int success = 0;

    for (final item in unsynced) {
      final key = item['key'] as int;
      final value = item['value'] as Map<String, dynamic>;
      final data = Map<String, dynamic>.from(value['data'] as Map);
      try {
        final docId = await firestoreService.saveHomePageData(data);
        await markAsSynced(key, docId);
        success++;
      } catch (_) {}
    }

    return success;
  }

  /// Soft delete a record by local key
  Future<void> softDeleteByKey(int key) async {
    final value = box.getAt(key);
    if (value is Map) {
      final updated = Map<String, dynamic>.from(value);
      updated['isDeleted'] = true;
      await box.putAt(key, updated);
    }
  }

  /// Soft delete all records for a user (using uid field in data)
  Future<void> softDeleteByUserId(String userId) async {
    for (var i = 0; i < box.length; i++) {
      final value = box.getAt(i);
      if (value is Map) {
        final data = Map<String, dynamic>.from(value['data'] ?? {});
        if (data['uid'] == userId) {
          final updated = Map<String, dynamic>.from(value);
          updated['isDeleted'] = true;
          await box.putAt(i, updated);
        }
      }
    }
  }

  /// Permanently remove a record (if you ever need hard delete)
  Future<void> hardDeleteByKey(int key) async {
    await box.deleteAt(key);
  }
}
