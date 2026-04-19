import 'package:hive_flutter/hive_flutter.dart';
import 'firestore_service.dart';
import 'dart:async';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';

class LocalDbService {
  LocalDbService._private();
  static final LocalDbService instance = LocalDbService._private();

  static const String _boxName = 'homepageData';
  late Box _box;
  bool _initialized = false;
  bool _isSyncing = false;
  bool _offlineAuthenticated = false;
  final Uuid _uuid = const Uuid();

  /// Initialize Hive (idempotent)
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
    if (!_initialized) throw Exception("LocalDbService not initialized.");
    return _box;
  }

  /// Whether the current session is using cached offline authentication.
  bool get offlineAuthenticated => _offlineAuthenticated;

  /// Set offline authenticated state (used when user signs in with cached credentials).
  void setOfflineAuthenticated(bool v) {
    _offlineAuthenticated = v;
  }

  /// Save a local record with username included. Returns the local key (int).
  /// Keeps parameter name `synced` for backward compatibility but stores `isSynced` internally.
  Future<int> saveLocalRecord(Map<String, dynamic> data,
      {bool synced = false, String? firestoreId}) async {
    final id = (data['id'] as String?) ?? _uuid.v4();
    final now = DateTime.now().toIso8601String();
    final record = {
      'id': id,
      'data': {...data, 'id': id},
      'username': data['username'] ?? '',
      'createdAt': now,
      'lastModified': now,
      'isSynced': synced,
      'synced': synced, // backward compatibility
      'firestoreId': firestoreId ?? id,
      'isDeleted': data['isDeleted'] == true ? true : false,
    };
    final key = await box.add(record);
    debugPrint(
        'LocalDbService: saved local record key=$key id=$id synced=$synced firestoreId=${record['firestoreId']}');
    return key;
  }

  /// Get count of patients screened today (records with createdAt date = today)
  Future<int> getTodayScreenedCount() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    int count = 0;

    for (final key in box.keys) {
      final value = box.get(key);
      if (value is Map && value['isDeleted'] != true) {
        final createdAtStr = value['createdAt'] as String?;
        if (createdAtStr != null) {
          final createdAt = DateTime.tryParse(createdAtStr);
          if (createdAt != null) {
            final recordDate =
                DateTime(createdAt.year, createdAt.month, createdAt.day);
            if (recordDate == today) count++;
          }
        }
      }
    }
    return count;
  }

  /// Get all records (optionally include deleted)
  /// Returns records in a UI-friendly shape: {id, data, timestamp, synced, firestoreId, isDeleted}
  Future<List<Map<String, dynamic>>> getAllRecords(
      {bool includeDeleted = false}) async {
    final results = <Map<String, dynamic>>[];
    for (final key in box.keys) {
      final value = box.get(key);
      if (value is Map) {
        if (!includeDeleted && value['isDeleted'] == true) continue;
        results.add({
          'id': value['id'] ?? key,
          'data': Map<String, dynamic>.from(value['data'] ?? {}),
          'timestamp': value['createdAt'],
          'lastModified': value['lastModified'],
          'synced':
              (value['isSynced'] == true) || (value['synced'] == true),
          'firestoreId': value['firestoreId'],
          'isDeleted': value['isDeleted'] == true,
        });
      }
    }
    return results;
  }

  /// Get unsynced records
  Future<List<Map<String, dynamic>>> getUnsyncedRecords() async {
    final results = <Map<String, dynamic>>[];
    for (final key in box.keys) {
      final value = box.get(key);
      if (value is Map && value['isDeleted'] != true) {
        final isSynced =
            (value['isSynced'] == true) || (value['synced'] == true);
        if (!isSynced) {
          results.add(
              {'key': key, 'value': Map<String, dynamic>.from(value)});
        }
      }
    }
    return results;
  }

  /// Clear all records that are already synced to Firestore.
  /// Returns the number of deleted records.
  Future<int> clearSyncedRecords() async {
    if (!_initialized) {
      await init();
    }

    final keysToDelete = <int>[];

    for (final key in box.keys) {
      final value = box.get(key);
      if (value is Map) {
        final isSynced =
            (value['isSynced'] == true) || (value['synced'] == true);
        if (isSynced) {
          keysToDelete.add(key as int);
        }
      }
    }

    if (keysToDelete.isNotEmpty) {
      await box.deleteAll(keysToDelete);
    }

    return keysToDelete.length;
  }

  /// Mark a local record as synced
  Future<void> markAsSynced(int localKey, String firestoreId) async {
    final value = box.get(localKey);
    if (value is Map) {
      final updated = Map<String, dynamic>.from(value);
      updated['isSynced'] = true;
      updated['synced'] = true; // backward compatibility
      updated['firestoreId'] = firestoreId;
      updated['syncedAt'] = DateTime.now().toIso8601String();
      updated['lastModified'] = DateTime.now().toIso8601String();
      await box.put(localKey, updated);
      debugPrint(
          'LocalDbService: marked localKey=$localKey id=${updated['id']} as synced -> firestoreId=$firestoreId');
    }
  }

  /// Save and sync a record to Firestore
  Future<void> saveAndSync(
      Map<String, dynamic> data, FirestoreService firestoreService) async {
    final localKey = await saveLocalRecord(data, synced: false);
    debugPrint(
        'LocalDbService.saveAndSync: pushing localKey=$localKey to Firestore');
    try {
      final localRecord = box.get(localKey);
      final id =
          (localRecord is Map) ? (localRecord['id'] as String?) : null;
      final docId = await firestoreService
          .saveHomePageData({...data, 'id': id ?? ''}, docId: id);
      await markAsSynced(localKey, docId);
      debugPrint(
          'LocalDbService.saveAndSync: success localKey=$localKey docId=$docId');
    } catch (e) {
      debugPrint(
          'LocalDbService.saveAndSync: failed to push localKey=$localKey error=$e');
      // Leave unsynced for later
    }
  }

  /// Sync all pending local records. Returns number of successfully synced records.
  Future<int> syncPending(FirestoreService firestoreService) async {
    if (_isSyncing) {
      debugPrint('LocalDbService.syncPending: already syncing, skipping');
      return 0;
    }
    _isSyncing = true;
    int success = 0;
    try {
      final unsynced = await getUnsyncedRecords();
      debugPrint(
          'LocalDbService.syncPending: starting, unsyncedCount=${unsynced.length}');

      for (final item in unsynced) {
        final key = item['key'];
        final value = item['value'] as Map<String, dynamic>;
        final data = Map<String, dynamic>.from(value['data'] as Map);
        try {
          final id = (value['id'] as String?) ?? key.toString();
          final existingDocId =
              (value['firestoreId'] as String?)?.isNotEmpty == true
                  ? value['firestoreId'] as String
                  : id;
          debugPrint(
              'LocalDbService.syncPending: pushing id=$id for localKey=$key existingDocId=$existingDocId');
          final docId = await firestoreService.saveHomePageData(
            {...data, 'id': id},
            docId: existingDocId,
          );

          try {
            final barangayPatientId =
                await firestoreService.savePatientToBarangay(data);
            final barangayId =
                await firestoreService.getCurrentUserBarangayId();
            if (barangayId != null &&
                barangayId.isNotEmpty &&
                barangayPatientId.isNotEmpty) {
              await firestoreService.createPatientNotification(
                barangayId: barangayId,
                patientId: barangayPatientId,
                patientData: data,
              );
            }
          } catch (e) {
            debugPrint(
                'LocalDbService.syncPending: savePatientToBarangay/notification failed for localKey=$key error=$e');
            continue;
          }

          await markAsSynced(key as int, docId);
          success++;
          debugPrint(
              'LocalDbService.syncPending: pushed localKey=$key id=$id docId=$docId');
        } catch (e) {
          debugPrint(
              'LocalDbService.syncPending: failed for localKey=$key error=$e');
          continue;
        }
      }
    } finally {
      _isSyncing = false;
      debugPrint('LocalDbService.syncPending: finished, success=$success');
    }

    return success;
  }

  /// Soft delete a record by local key
  Future<void> softDeleteByKey(int key) async {
    final value = box.get(key);
    if (value is Map) {
      final updated = Map<String, dynamic>.from(value);
      updated['isDeleted'] = true;
      await box.put(key, updated);
    }
  }

  /// Soft delete all records for a user (using uid field)
  Future<void> softDeleteByUserId(String userId) async {
    for (final key in box.keys) {
      final value = box.get(key);
      if (value is Map) {
        final data = Map<String, dynamic>.from(value['data'] ?? {});
        if (data['uid'] == userId) {
          final updated = Map<String, dynamic>.from(value);
          updated['isDeleted'] = true;
          await box.put(key, updated);
        }
      }
    }
  }

  /// Soft delete a local record by its Firestore ID.
  /// Called when a Firestore assessment is deleted so local cache stays in sync.
  Future<void> softDeleteByFirestoreId(String firestoreId) async {
    if (firestoreId.isEmpty) return;
    for (final key in box.keys) {
      final value = box.get(key);
      if (value is Map && value['firestoreId'] == firestoreId) {
        final updated = Map<String, dynamic>.from(value);
        updated['isDeleted'] = true;
        updated['lastModified'] = DateTime.now().toIso8601String();
        await box.put(key, updated);
        debugPrint(
            'LocalDbService: soft-deleted localKey=$key firestoreId=$firestoreId');
        return; // firestoreId is unique — stop after first match
      }
    }
  }

  /// Update the anthropometric data of a local record by its Firestore ID.
  /// Called after a successful Firestore edit so local cache stays in sync.
  Future<void> updateAssessmentByFirestoreId({
    required String firestoreId,
    required Map<String, dynamic> anthropometric,
  }) async {
    if (firestoreId.isEmpty) return;
    for (final key in box.keys) {
      final value = box.get(key);
      if (value is Map && value['firestoreId'] == firestoreId) {
        final updated = Map<String, dynamic>.from(value);

        // Merge anthropometric into the nested data map
        final data = Map<String, dynamic>.from(updated['data'] ?? {});
        final existingAnthro =
            Map<String, dynamic>.from(data['anthropometric'] ?? {});
        existingAnthro.addAll(anthropometric); // merge, not replace
        data['anthropometric'] = existingAnthro;

        updated['data'] = data;
        updated['lastModified'] = DateTime.now().toIso8601String();
        updated['isSynced'] = true;
        updated['synced'] = true;

        await box.put(key, updated);
        debugPrint(
            'LocalDbService: updated assessment localKey=$key firestoreId=$firestoreId');
        return; // firestoreId is unique — stop after first match
      }
    }
    debugPrint(
        'LocalDbService: firestoreId=$firestoreId not found locally, skipping local update');
  }

  /// Permanently remove a record
  Future<void> hardDeleteByKey(int key) async {
    await box.delete(key);
  }

  /// Update email for all records belonging to a user
  Future<void> updateEmailForUser(String userId, String newEmail) async {
    for (final key in box.keys) {
      final value = box.get(key);
      if (value is Map) {
        final data = Map<String, dynamic>.from(value['data'] ?? {});
        if (data['uid'] == userId) {
          final updated = Map<String, dynamic>.from(value);
          updated['data'] = {
            ...data,
            'email': newEmail,
          };
          await box.put(key, updated);
        }
      }
    }
  }

  /// Update display name for all records belonging to a user
  Future<void> updateDisplayNameForUser(
      String userId, String displayName) async {
    for (final key in box.keys) {
      final value = box.get(key);
      if (value is Map) {
        final data = Map<String, dynamic>.from(value['data'] ?? {});
        if (data['uid'] == userId) {
          final updated = Map<String, dynamic>.from(value);
          updated['data'] = {
            ...data,
            'displayName': displayName,
          };
          await box.put(key, updated);
        }
      }
    }
  }

  /// Update profile picture for all records belonging to a user
  Future<void> updateProfilePictureForUser(
      String userId, String profilePicture) async {
    for (final key in box.keys) {
      final value = box.get(key);
      if (value is Map) {
        final data = Map<String, dynamic>.from(value['data'] ?? {});
        if (data['uid'] == userId) {
          final updated = Map<String, dynamic>.from(value);
          updated['data'] = {
            ...data,
            'profilePicture': profilePicture,
          };
          await box.put(key, updated);
        }
      }
    }
  }
}