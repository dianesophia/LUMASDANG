import 'package:hive_flutter/hive_flutter.dart';
import 'firestore_service.dart';

class LocalDbService {
  LocalDbService._private();
  static final LocalDbService instance = LocalDbService._private();

  // Boxes
  static const String _homepageBoxName = 'homepageData';
  static const String _userBoxName = 'userBox';

  late Box _homepageBox;
  late Box _userBox;

  bool _initialized = false;

  /// ================= Hive Initialization =================
  Future<void> init() async {
    if (_initialized) return;

    await Hive.initFlutter();

    // Open homepage box
    if (!Hive.isBoxOpen(_homepageBoxName)) {
      _homepageBox = await Hive.openBox(_homepageBoxName);
    } else {
      _homepageBox = Hive.box(_homepageBoxName);
    }

    // Open user box
    if (!Hive.isBoxOpen(_userBoxName)) {
      _userBox = await Hive.openBox(_userBoxName);
    } else {
      _userBox = Hive.box(_userBoxName);
    }

    _initialized = true;
  }

  /// ================== Homepage Box Methods ==================
  Box get homepageBox {
    if (!_initialized) throw Exception("LocalDbService not initialized. Call init() first.");
    return _homepageBox;
  }

  Future<int> saveLocalRecord(Map<String, dynamic> data,
      {bool synced = false, String? firestoreId}) async {
    final record = {
      'data': data,
      'createdAt': DateTime.now().toIso8601String(),
      'synced': synced,
      'firestoreId': firestoreId,
      'isDeleted': false,
    };
    return await homepageBox.add(record);
  }

  Future<List<Map<String, dynamic>>> getAllRecords({bool includeDeleted = false}) async {
    final results = <Map<String, dynamic>>[];
    for (var i = 0; i < homepageBox.length; i++) {
      final value = homepageBox.getAt(i);
      if (value is Map) {
        if (!includeDeleted && value['isDeleted'] == true) continue;
        results.add({'key': i, 'value': Map<String, dynamic>.from(value)});
      }
    }
    return results;
  }

  Future<List<Map<String, dynamic>>> getUnsyncedRecords() async {
    final results = <Map<String, dynamic>>[];
    for (var i = 0; i < homepageBox.length; i++) {
      final value = homepageBox.getAt(i);
      if (value is Map && value['synced'] == false && value['isDeleted'] == false) {
        results.add({'key': i, 'value': Map<String, dynamic>.from(value)});
      }
    }
    return results;
  }

  Future<void> markAsSynced(int localKey, String firestoreId) async {
    final value = homepageBox.getAt(localKey);
    if (value is Map) {
      final updated = Map<String, dynamic>.from(value);
      updated['synced'] = true;
      updated['firestoreId'] = firestoreId;
      await homepageBox.putAt(localKey, updated);
    }
  }

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

  Future<void> softDeleteByKey(int key) async {
    final value = homepageBox.getAt(key);
    if (value is Map) {
      final updated = Map<String, dynamic>.from(value);
      updated['isDeleted'] = true;
      await homepageBox.putAt(key, updated);
    }
  }

  Future<void> softDeleteByUserId(String userId) async {
    for (var i = 0; i < homepageBox.length; i++) {
      final value = homepageBox.getAt(i);
      if (value is Map) {
        final data = Map<String, dynamic>.from(value['data'] ?? {});
        if (data['uid'] == userId) {
          final updated = Map<String, dynamic>.from(value);
          updated['isDeleted'] = true;
          await homepageBox.putAt(i, updated);
        }
      }
    }
  }

  Future<void> hardDeleteByKey(int key) async {
    await homepageBox.deleteAt(key);
  }

  /// ================== User Box Methods ==================
  Box get userBox {
    if (!_initialized) throw Exception("LocalDbService not initialized. Call init() first.");
    return _userBox;
  }

  Future<void> setUserInfo(String key, dynamic value) async {
    try {
      await userBox.put(key, value);
    } catch (e) {
      print("Hive setUserInfo error: $e");
      rethrow;
    }
  }

  dynamic getUserInfo(String key) {
    try {
      return userBox.get(key);
    } catch (e) {
      print("Hive getUserInfo error: $e");
      return null;
    }
  }

  Future<void> clearUserBox() async {
    await userBox.clear();
  }
}
