import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import '../services/local_db_service.dart';
import '../services/connectivity_service.dart';
import '../screens/calendar_events_page.dart';
import '../screens/patient_list.dart';

class NotificationsTab extends StatefulWidget {
  const NotificationsTab({super.key});

  @override
  State<NotificationsTab> createState() => _NotificationsTabState();
}

class _NotificationsTabState extends State<NotificationsTab> {
  String _activeFilter = 'all';
  bool _isOnline = true;
  List<Map<String, dynamic>> _offlineNotifications = [];
  bool _offlineLoading = false;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
  }

  Future<void> _checkConnectivity() async {
    final online = await ConnectivityService.instance.checkOnline();
    if (mounted) setState(() => _isOnline = online);
    if (!online) _loadOffline();
    ConnectivityService.instance.startMonitoring((online) {
      if (mounted) setState(() => _isOnline = online);
      if (!online) _loadOffline();
    });
  }

  Future<void> _loadOffline() async {
    setState(() => _offlineLoading = true);
    await LocalDbService.instance.init();
    final localRecords = await LocalDbService.instance.getAllRecords();
    final notifications = localRecords.map((record) {
      final data = record['data'] as Map<String, dynamic>;
      return {
        'id': record['id'],
        'type': 'new_patient',
        'patientName':
            '${data['demographic']?['firstName'] ?? ''} ${data['demographic']?['lastName'] ?? ''}',
        'patientAge': data['demographic']?['age'] ?? '',
        'patientSex': data['demographic']?['sex'] ?? '',
        'createdAt': record['timestamp'],
        'read': record['synced'] ?? false,
      };
    }).toList();

    notifications.sort((a, b) {
      final aTime = a['createdAt'];
      final bTime = b['createdAt'];
      if (aTime is String && bTime is String) return bTime.compareTo(aTime);
      return 0;
    });

    if (mounted) {
      setState(() {
        _offlineNotifications = notifications;
        _offlineLoading = false;
      });
    }
  }

  // ── Streams ────────────────────────────────────────────────────────────────
  Stream<List<Map<String, dynamic>>> _patientNotifsStream() async* {
    final barangayId = await FirestoreService().getCurrentUserBarangayId();
    if (barangayId == null || barangayId.isEmpty) {
      yield <Map<String, dynamic>>[];
      return;
    }
    yield* FirebaseFirestore.instance
        .collection('barangays')
        .doc(barangayId)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs.map((d) {
              final data = d.data();
              data['id'] = d.id;
              return data;
            }).toList());
  }

  Stream<List<Map<String, dynamic>>> _eventNotifsStream() async* {
    final barangayId = await FirestoreService().getCurrentUserBarangayId();
    if (barangayId == null || barangayId.isEmpty) {
      yield <Map<String, dynamic>>[];
      return;
    }
    yield* FirebaseFirestore.instance
        .collection('barangays')
        .doc(barangayId)
        .collection('calendarNotifications')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs.map((d) {
              final data = d.data();
              data['id'] = d.id;
              return data;
            }).toList());
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  List<Map<String, dynamic>> _merged(
    List<Map<String, dynamic>> patients,
    List<Map<String, dynamic>> events,
  ) {
    final all = [...patients, ...events];
    all.sort((a, b) {
      final aTs = a['createdAt'];
      final bTs = b['createdAt'];
      if (aTs is Timestamp && bTs is Timestamp) return bTs.compareTo(aTs);
      return 0;
    });
    return all;
  }

  List<Map<String, dynamic>> _filtered(List<Map<String, dynamic>> all) {
    if (_activeFilter == 'all') return all;
    return all.where((n) => n['type'] == _activeFilter).toList();
  }

  int _unreadCount(List<Map<String, dynamic>> all) =>
      all.where((n) => n['read'] == false).length;

  String _formatTimestamp(dynamic timestamp) {
    try {
      DateTime dt;
      if (timestamp is Timestamp) {
        dt = timestamp.toDate();
      } else if (timestamp is String) {
        dt = DateTime.parse(timestamp);
      } else {
        return 'Unknown time';
      }
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${m[dt.month - 1]} ${dt.day}, ${dt.year}';
    } catch (_) {
      return 'Unknown time';
    }
  }

  Color _avatarColor(String sex) {
    final s = sex.toLowerCase();
    if (s == 'male' || s == 'm') return const Color(0xFF5CAA7F);
    if (s == 'female' || s == 'f') return const Color(0xFFF5A962);
    return const Color(0xFF8BC88A);
  }

  IconData _avatarIcon(String sex) {
    final s = sex.toLowerCase();
    if (s == 'male' || s == 'm') return Icons.boy;
    if (s == 'female' || s == 'f') return Icons.girl;
    return Icons.person;
  }

  // ── Navigation ─────────────────────────────────────────────────────────────
  void _navigateToCalendar() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const CalendarEventsPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final tween = Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)
              .chain(CurveTween(curve: Curves.easeInOutCubic));
          return SlideTransition(position: animation.drive(tween), child: child);
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  void _navigateToPatientList() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF2E8B7B), Color(0xFF5CAA7F), Color(0xFF8BC88A)],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 8, 16, 4),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back_ios_new_rounded,
                              color: Colors.white, size: 20),
                        ),
                        const Text(
                          'Patient List',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Expanded(child: PatientListTab()),
                ],
              ),
            ),
          ),
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final tween = Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)
              .chain(CurveTween(curve: Curves.easeInOutCubic));
          return SlideTransition(position: animation.drive(tween), child: child);
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (!_isOnline) return _buildOfflineView();

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _patientNotifsStream(),
      builder: (context, patientSnap) {
        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: _eventNotifsStream(),
          builder: (context, eventSnap) {
            final patients = patientSnap.data ?? [];
            final events = eventSnap.data ?? [];
            final all = _merged(patients, events);
            final filtered = _filtered(all);
            final unread = _unreadCount(all);
            final isLoading = patientSnap.connectionState ==
                    ConnectionState.waiting ||
                eventSnap.connectionState == ConnectionState.waiting;

            return Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF2E8B7B), Color(0xFF5CAA7F), Color(0xFF8BC88A)],
                ),
              ),
              child: Column(
                children: [
                  _buildHeader(unread),
                  _buildFilterChips(all),
                  if (isLoading)
                    const LinearProgressIndicator(
                      backgroundColor: Colors.transparent,
                      color: Colors.white54,
                    ),
                  Expanded(child: _buildList(filtered)),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader(int unread) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_active, color: Colors.white, size: 28),
                if (unread > 0)
                  Positioned(
                    top: -5,
                    right: -5,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                          color: Color(0xFFF08030), shape: BoxShape.circle),
                      child: Text('$unread',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Notifications',
                    style: TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                Text('Shared with your barangay team',
                    style: TextStyle(fontSize: 13, color: Colors.white70)),
              ],
            ),
          ),
          // Live indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                      color: Color(0xFF8BC88A), shape: BoxShape.circle),
                ),
                const SizedBox(width: 4),
                const Text('Live',
                    style: TextStyle(
                        color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Filter chips ────────────────────────────────────────────────────────────
  Widget _buildFilterChips(List<Map<String, dynamic>> all) {
    final patientCount = all.where((n) => n['type'] == 'new_patient').length;
    final eventCount = all.where((n) => n['type'] == 'new_event').length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Row(
        children: [
          _chip('All', 'all', all.length),
          const SizedBox(width: 8),
          _chip('Patients', 'new_patient', patientCount),
          const SizedBox(width: 8),
          _chip('Events', 'new_event', eventCount),
        ],
      ),
    );
  }

  Widget _chip(String label, String filter, int count) {
    final isActive = _activeFilter == filter;
    return GestureDetector(
      onTap: () => setState(() => _activeFilter = filter),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isActive ? const Color(0xFF2E8B7B) : Colors.white)),
            if (count > 0) ...[
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFF2E8B7B)
                      : Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('$count',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── List ────────────────────────────────────────────────────────────────────
  Widget _buildList(List<Map<String, dynamic>> items) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none,
                size: 72, color: Colors.white.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            Text('No notifications yet',
                style: TextStyle(
                    fontSize: 17,
                    color: Colors.white.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            Text(
              _activeFilter == 'new_patient'
                  ? 'Patient assessments will appear here'
                  : _activeFilter == 'new_event'
                      ? 'Calendar events will appear here'
                      : 'New activity from your barangay\nteam will appear here in real-time',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13, color: Colors.white.withValues(alpha: 0.5)),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final n = items[i];
        return n['type'] == 'new_event'
            ? _buildEventCard(n)
            : _buildPatientCard(n);
      },
    );
  }

  // ── Patient card ────────────────────────────────────────────────────────────
  Widget _buildPatientCard(Map<String, dynamic> n) {
    final isRead = n['read'] ?? false;
    final patientName = n['patientName'] ?? '';
    final patientAge = n['patientAge'] ?? '';
    final patientSex = n['patientSex'] ?? '';
    final createdBy = n['createdByName'] ?? 'Unknown';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isRead ? Colors.transparent : const Color(0xFF2E8B7B),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            // Mark as read
            if (!isRead && n['id'] != null) {
              await FirestoreService().markNotificationAsRead(n['id']);
            }
            // Navigate to Patient List
            if (mounted) _navigateToPatientList();
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                      color: _avatarColor(patientSex), shape: BoxShape.circle),
                  child: Icon(_avatarIcon(patientSex), color: Colors.white, size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text('New Assessment',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isRead
                                        ? Colors.grey
                                        : const Color(0xFF2E8B7B))),
                          ),
                          if (!isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                  color: Color(0xFF2E8B7B), shape: BoxShape.circle),
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(patientName,
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight:
                                  isRead ? FontWeight.normal : FontWeight.bold,
                              color: Colors.black87)),
                      const SizedBox(height: 2),
                      Text('Added by $createdBy',
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                              fontStyle: FontStyle.italic)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.cake, size: 11, color: Colors.grey.shade500),
                          const SizedBox(width: 3),
                          Text(
                              patientAge.isNotEmpty ? '$patientAge months' : 'Age N/A',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey.shade600)),
                          const SizedBox(width: 10),
                          Icon(_avatarIcon(patientSex),
                              size: 11, color: Colors.grey.shade500),
                          const SizedBox(width: 3),
                          Text(patientSex.isNotEmpty ? patientSex : 'N/A',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey.shade600)),
                          const Spacer(),
                          Icon(Icons.access_time,
                              size: 11, color: Colors.grey.shade400),
                          const SizedBox(width: 3),
                          Text(_formatTimestamp(n['createdAt']),
                              style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade500,
                                  fontStyle: FontStyle.italic)),
                        ],
                      ),
                    ],
                  ),
                ),
                // Destination hint
                Column(
                  children: [
                    Icon(Icons.people_rounded,
                        color: const Color(0xFF2E8B7B).withValues(alpha: 0.4),
                        size: 16),
                    const SizedBox(height: 2),
                    Icon(Icons.chevron_right,
                        color: Colors.grey.shade300, size: 20),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Event card ──────────────────────────────────────────────────────────────
  Widget _buildEventCard(Map<String, dynamic> n) {
    final isRead = n['read'] ?? false;
    final eventTitle = n['eventTitle'] ?? 'Untitled Event';
    final eventTime = n['eventTime'] ?? '';
    final eventDate = n['eventDate'];
    final createdBy = n['createdByName'] ?? 'Unknown';
    final eventColor = Color(n['colorValue'] ?? 0xFFF5A962);

    String dateLabel = '';
    if (eventDate is Timestamp) {
      final d = eventDate.toDate();
      const months = ['Jan','Feb','Mar','Apr','May','Jun',
                      'Jul','Aug','Sep','Oct','Nov','Dec'];
      dateLabel = '${months[d.month - 1]} ${d.day}, ${d.year}';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isRead ? Colors.transparent : eventColor,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            // Mark as read
            if (!isRead && n['id'] != null) {
              await FirestoreService().markCalendarNotificationAsRead(n['id']);
            }
            // Navigate to Calendar
            if (mounted) _navigateToCalendar();
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: eventColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(color: eventColor, width: 2),
                  ),
                  child: Icon(Icons.event_rounded, color: eventColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text('New Event Added',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isRead ? Colors.grey : eventColor)),
                          ),
                          if (!isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                  color: eventColor, shape: BoxShape.circle),
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(eventTitle,
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight:
                                  isRead ? FontWeight.normal : FontWeight.bold,
                              color: Colors.black87)),
                      const SizedBox(height: 2),
                      Text('Added by $createdBy',
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                              fontStyle: FontStyle.italic)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.calendar_today_rounded,
                              size: 11, color: Colors.grey.shade500),
                          const SizedBox(width: 3),
                          Text(dateLabel,
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey.shade600)),
                          if (eventTime.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Icon(Icons.access_time_rounded,
                                size: 11, color: Colors.grey.shade500),
                            const SizedBox(width: 3),
                            Text(eventTime,
                                style: TextStyle(
                                    fontSize: 11, color: Colors.grey.shade600)),
                          ],
                          const Spacer(),
                          Icon(Icons.access_time,
                              size: 11, color: Colors.grey.shade400),
                          const SizedBox(width: 3),
                          Text(_formatTimestamp(n['createdAt']),
                              style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade500,
                                  fontStyle: FontStyle.italic)),
                        ],
                      ),
                    ],
                  ),
                ),
                // Destination hint
                Column(
                  children: [
                    Icon(Icons.calendar_month_rounded,
                        color: eventColor.withValues(alpha: 0.4), size: 16),
                    const SizedBox(height: 2),
                    Icon(Icons.chevron_right,
                        color: Colors.grey.shade300, size: 20),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Offline view ────────────────────────────────────────────────────────────
  Widget _buildOfflineView() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2E8B7B), Color(0xFF5CAA7F), Color(0xFF8BC88A)],
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.notifications_active,
                      color: Colors.white, size: 28),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Notifications',
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                      Text('Offline mode — local records only',
                          style: TextStyle(fontSize: 13, color: Colors.white70)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.wifi_off, color: Colors.white, size: 12),
                      SizedBox(width: 4),
                      Text('Offline',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _offlineLoading
                ? const Center(
                    child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                : _offlineNotifications.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.wifi_off,
                                size: 64,
                                color: Colors.white.withValues(alpha: 0.4)),
                            const SizedBox(height: 12),
                            Text('You are offline',
                                style: TextStyle(
                                    fontSize: 17,
                                    color: Colors.white.withValues(alpha: 0.7),
                                    fontWeight: FontWeight.w500)),
                            const SizedBox(height: 6),
                            Text(
                              'Connect to the internet to see\nshared barangay notifications',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white.withValues(alpha: 0.5)),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: _offlineNotifications.length,
                        itemBuilder: (context, i) =>
                            _buildPatientCard(_offlineNotifications[i]),
                      ),
          ),
        ],
      ),
    );
  }
}