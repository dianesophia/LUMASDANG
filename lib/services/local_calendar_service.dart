import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lumasdang/screens/calendar_events_page.dart';

/// Lightweight local cache for calendar events to support offline viewing.
/// Stores events per barangay in a Hive box.
class LocalCalendarService {
  LocalCalendarService._private();
  static final LocalCalendarService instance = LocalCalendarService._private();

  static const String _boxName = 'calendarEventsLocal';
  late Box _box;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    // Hive is already initialized via LocalDbService in main(), but calling
    // Hive.initFlutter() again is safe. We skip it here and just open the box.
    if (!Hive.isBoxOpen(_boxName)) {
      _box = await Hive.openBox(_boxName);
    } else {
      _box = Hive.box(_boxName);
    }

    _initialized = true;
  }

  /// Cache the full list of events for a barangay, replacing any previous data.
  Future<void> cacheEvents({
    required String barangayId,
    required List<CalEvent> events,
  }) async {
    await init();

    // We store all events in a single entry keyed by barangayId for simplicity.
    final serialized = events
        .map((e) => {
              'id': e.id,
              'title': e.title,
              'time': e.time,
              'description': e.description,
              'colorValue': e.color.value,
              'date': e.date.toIso8601String(),
            })
        .toList();

    await _box.put(barangayId, serialized);
  }

  /// Returns cached events for a barangay, or an empty list if none.
  Future<List<CalEvent>> getCachedEvents(String barangayId) async {
    await init();
    final raw = _box.get(barangayId);
    if (raw is! List) return <CalEvent>[];

    final List<CalEvent> result = [];
    for (final item in raw) {
      if (item is Map) {
        final map = Map<String, dynamic>.from(item as Map);
        final dateStr = map['date']?.toString() ?? '';
        final date = DateTime.tryParse(dateStr) ?? DateTime.now();
        result.add(
          CalEvent(
            id: map['id'] as String?,
            title: map['title']?.toString() ?? '',
            time: map['time']?.toString() ?? '',
            description: map['description']?.toString() ?? '',
            color: Color(map['colorValue'] as int? ?? 0xFFF5A962),
            date: date,
          ),
        );
      }
    }
    return result;
  }

  String _pendingKey(String barangayId) => '${barangayId}_pendingOps';

  Future<void> _appendPendingOp(String barangayId, Map<String, dynamic> op) async {
    await init();
    final key = _pendingKey(barangayId);
    final raw = _box.get(key);
    final List<Map<String, dynamic>> list = [];
    if (raw is List) {
      for (final item in raw) {
        if (item is Map) list.add(Map<String, dynamic>.from(item as Map));
      }
    }
    list.add(op);
    await _box.put(key, list);
  }

  Future<void> addLocalEvent(String barangayId, CalEvent event) async {
    final events = await getCachedEvents(barangayId);
    final localId =
        event.id ?? 'local_${DateTime.now().millisecondsSinceEpoch}_${events.length}';
    final newEvent = CalEvent(
      id: localId,
      title: event.title,
      time: event.time,
      description: event.description,
      color: event.color,
      date: event.date,
    );
    final updated = [...events, newEvent];
    await cacheEvents(barangayId: barangayId, events: updated);
    await _appendPendingOp(barangayId, {
      'op': 'add',
      'id': localId,
      'data': newEvent.toMap(),
    });
  }

  Future<void> updateLocalEvent(String barangayId, CalEvent event) async {
    if (event.id == null) return;
    final events = await getCachedEvents(barangayId);
    final idx = events.indexWhere((e) => e.id == event.id);
    if (idx < 0) return;
    final updatedEvents = [...events];
    updatedEvents[idx] = event;
    await cacheEvents(barangayId: barangayId, events: updatedEvents);
    await _appendPendingOp(barangayId, {
      'op': 'update',
      'id': event.id,
      'data': event.toMap(),
    });
  }

  Future<void> deleteLocalEvent(String barangayId, String eventId) async {
    final events = await getCachedEvents(barangayId);
    final updatedEvents = events.where((e) => e.id != eventId).toList();
    await cacheEvents(barangayId: barangayId, events: updatedEvents);
    await _appendPendingOp(barangayId, {
      'op': 'delete',
      'id': eventId,
    });
  }

  /// Pushes all pending local operations to Firestore, then clears the queue.
  Future<void> syncPending(String barangayId, CollectionReference eventsRef) async {
    await init();
    final key = _pendingKey(barangayId);
    final raw = _box.get(key);
    if (raw is! List || raw.isEmpty) return;

    final pending = <Map<String, dynamic>>[];
    for (final item in raw) {
      if (item is Map) {
        pending.add(Map<String, dynamic>.from(item as Map));
      }
    }

    if (pending.isEmpty) return;

    // Map local IDs to newly created Firestore IDs during this sync run.
    final idMap = <String, String>{};

    for (final op in pending) {
      final type = op['op'] as String?;
      String? id = op['id'] as String?;
      final dataRaw = op['data'];
      final Map<String, dynamic>? data =
          dataRaw is Map ? Map<String, dynamic>.from(dataRaw as Map) : null;

      try {
        if (type == 'add' && data != null) {
          if (id != null && id.startsWith('local_')) {
            final ref = await eventsRef.add(data);
            idMap[id] = ref.id;
          }
        } else if (type == 'update' && id != null && data != null) {
          id = idMap[id] ?? id;
          await eventsRef.doc(id).set(data, SetOptions(merge: true));
        } else if (type == 'delete' && id != null) {
          id = idMap[id] ?? id;
          await eventsRef.doc(id).delete();
        }
      } catch (_) {
        // On any individual op failure, keep going; a future sync can retry.
        continue;
      }
    }

    // Clear pending ops after attempting sync.
    await _box.delete(key);
  }

  /// Best-effort guess of the user's barangayId from cached events.
  /// Used when offline and Firestore is unreachable.
  Future<String?> getLastBarangayId() async {
    await init();
    for (final key in _box.keys) {
      if (key is String && !key.endsWith('_pendingOps')) {
        return key;
      }
    }
    return null;
  }
}

