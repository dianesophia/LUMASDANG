import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lumasdang/services/firestore_service.dart';
import 'package:lumasdang/services/local_calendar_service.dart';
import 'package:lumasdang/services/connectivity_service.dart';
import 'package:flutter/foundation.dart';

// ─── Model ────────────────────────────────────────────────────────────────────
class CalEvent {
  final String? id;
  final String title;
  final String time;
  final String description;
  final Color color;
  final DateTime date;

  const CalEvent({
    this.id,
    required this.title,
    required this.time,
    required this.description,
    required this.color,
    required this.date,
  });

  Map<String, dynamic> toMap() => {
        'title': title,
        'time': time,
        'description': description,
        'colorValue': color.value,
        'date': Timestamp.fromDate(date),
      };

  factory CalEvent.fromMap(String id, Map<String, dynamic> map) {
    final ts = map['date'];
    final date = ts is Timestamp ? ts.toDate() : DateTime.now();
    return CalEvent(
      id: id,
      title: map['title'] ?? '',
      time: map['time'] ?? '',
      description: map['description'] ?? '',
      color: Color(map['colorValue'] ?? 0xFFF5A962),
      date: date,
    );
  }
}

// ─── Service ──────────────────────────────────────────────────────────────────
class CalendarService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String?> _getBarangayId() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final doc = await _db.collection('users').doc(user.uid).get();
    return doc.data()?['barangayId'] as String?;
  }

  CollectionReference? _eventsRef(String barangayId) => _db
      .collection('barangays')
      .doc(barangayId)
      .collection('calendarEvents');

  Stream<List<CalEvent>> eventsStream() async* {
    //final online = await ConnectivityService.instance.checkOnline();
    final online = kIsWeb ? true : await ConnectivityService.instance.checkOnline();
    String? barangayId;

    if (online) {
      barangayId = await _getBarangayId();
    } else {
      barangayId = await LocalCalendarService.instance.getLastBarangayId();
    }

    if (barangayId == null) {
      yield <CalEvent>[];
      return;
    }

    if (!online) {
      // Offline: return cached events if available.
      yield await LocalCalendarService.instance.getCachedEvents(barangayId);
      return;
    }

    // Online: first try to sync any pending local operations, then stream.
    final ref = _eventsRef(barangayId)!;
    await LocalCalendarService.instance.syncPending(barangayId, ref);

    yield* ref
        .orderBy('date', descending: false)
        .snapshots()
        .asyncMap((snap) async {
          final events = snap.docs
              .map((d) => CalEvent.fromMap(d.id, d.data() as Map<String, dynamic>))
              .toList();
          // Cache latest events for offline use.
          await LocalCalendarService.instance.cacheEvents(
            barangayId: barangayId!,
            events: events,
          );
          return events;
        });
  }

  Future<void> addEvent(CalEvent event) async {
    //final online = await ConnectivityService.instance.checkOnline();
    final online = kIsWeb ? true : await ConnectivityService.instance.checkOnline();
    final user = _auth.currentUser;
    if (user == null && online) return;

    String? barangayId;
    if (online) {
      barangayId = await _getBarangayId();
    } else {
      barangayId = await LocalCalendarService.instance.getLastBarangayId();
    }
    if (barangayId == null) return;

    if (!online) {
      // Offline: store locally and mark as pending for sync.
      await LocalCalendarService.instance.addLocalEvent(barangayId, event);
      return;
    }

    final userDoc = await _db.collection('users').doc(user!.uid).get();
    final creatorName = userDoc.data()?['fullName'] ??
        userDoc.data()?['username'] ??
        user.email ??
        'Unknown';

    final ref = await _eventsRef(barangayId)!.add({
      ...event.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': user.uid,
      'createdByName': creatorName,
      'barangayId': barangayId,
    });

    await FirestoreService().createCalendarEventNotification(
      barangayId: barangayId,
      eventId: ref.id,
      eventData: {
        ...event.toMap(),
        'createdByName': creatorName,
      },
    );
  }

  Future<void> updateEvent(CalEvent event) async {
    //final online = await ConnectivityService.instance.checkOnline();
    final online = kIsWeb ? true : await ConnectivityService.instance.checkOnline();
    String? barangayId;
    if (online) {
      barangayId = await _getBarangayId();
    } else {
      barangayId = await LocalCalendarService.instance.getLastBarangayId();
    }
    if (barangayId == null || event.id == null) return;

    if (!online) {
      await LocalCalendarService.instance.updateLocalEvent(barangayId, event);
      return;
    }

    await _eventsRef(barangayId)!.doc(event.id).update({
      ...event.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteEvent(String eventId) async {
    //final online = await ConnectivityService.instance.checkOnline();
    final online = kIsWeb ? true : await ConnectivityService.instance.checkOnline();
    String? barangayId;
    if (online) {
      barangayId = await _getBarangayId();
    } else {
      barangayId = await LocalCalendarService.instance.getLastBarangayId();
    }
    if (barangayId == null) return;

    if (!online) {
      await LocalCalendarService.instance.deleteLocalEvent(barangayId, eventId);
      return;
    }

    await _eventsRef(barangayId)!.doc(eventId).delete();
  }
}

// ─── Page ─────────────────────────────────────────────────────────────────────
class CalendarEventsPage extends StatefulWidget {
  const CalendarEventsPage({super.key});

  @override
  State<CalendarEventsPage> createState() => _CalendarEventsPageState();
}

class _CalendarEventsPageState extends State<CalendarEventsPage>
    with SingleTickerProviderStateMixin {
  final CalendarService _service = CalendarService();

  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;

  static const _colorOptions = [
    Color(0xFFF5A962),
    Color(0xFF2E8B7B),
    Color(0xFF5CAA7F),
    Color(0xFFF08030),
    Color(0xFF6C8EBF),
    Color(0xFFD45F5F),
  ];

  static String _fmtKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Map<String, List<CalEvent>> _groupByDay(List<CalEvent> events) {
    final map = <String, List<CalEvent>>{};
    for (final e in events) {
      map.putIfAbsent(_fmtKey(e.date), () => <CalEvent>[]).add(e);
    }
    return map;
  }

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _fadeAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _onDayTap(DateTime day) {
    setState(() => _selectedDay = day);
    _animController.forward(from: 0);
  }

  void _prevMonth() =>
      setState(() => _focusedDay =
          DateTime(_focusedDay.year, _focusedDay.month - 1));

  void _nextMonth() =>
      setState(() => _focusedDay =
          DateTime(_focusedDay.year, _focusedDay.month + 1));

  void _showSnackBar(String message, {Color? color}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color ?? const Color(0xFF2E8B7B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<CalEvent>>(
      stream: _service.eventsStream(),
      builder: (context, snapshot) {
        final allEvents = snapshot.data ?? <CalEvent>[];
        final grouped = _groupByDay(allEvents);
        final selectedEvents =
            grouped[_fmtKey(_selectedDay)] ?? <CalEvent>[];

        return Scaffold(
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showEventDialog(context),
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF2E8B7B),
            elevation: 4,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.add_rounded, size: 28),
          ),

          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF2E8B7B),
                  Color(0xFF5CAA7F),
                  Color(0xFF8BC88A)
                ],
                stops: [0.0, 0.35, 1.0],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  _buildHeader(context),
                  _buildCalendarCard(grouped),
                  Expanded(
                      child: _buildEventsList(
                          selectedEvents, snapshot.hasError)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 12, 0),
      child: Column(
        children: [
          Row(
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(50),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white.withOpacity(0.35), width: 1.2),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 18),
                  ),
                ),
              ),
              const Expanded(
                child: Center(
                  child: Text(
                    'Events Calendar',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => setState(() {
                    _focusedDay = DateTime.now();
                    _selectedDay = DateTime.now();
                  }),
                  borderRadius: BorderRadius.circular(50),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white.withOpacity(0.35), width: 1.2),
                    ),
                    child: const Icon(Icons.today_rounded,
                        color: Colors.white, size: 18),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.white.withOpacity(0.35),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Calendar card ──────────────────────────────────────────────────────────
  Widget _buildCalendarCard(Map<String, List<CalEvent>> grouped) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildMonthHeader(),
          _buildWeekdayLabels(),
          _buildDaysGrid(grouped),
          const SizedBox(height: 8),
          _buildLegend(),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildMonthHeader() {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          _calNavBtn(Icons.chevron_left_rounded, _prevMonth),
          Expanded(
            child: Text(
              '${months[_focusedDay.month - 1]} ${_focusedDay.year}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2E8B7B),
                letterSpacing: 0.3,
              ),
            ),
          ),
          _calNavBtn(Icons.chevron_right_rounded, _nextMonth),
        ],
      ),
    );
  }

  Widget _calNavBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: const Color(0xFF2E8B7B).withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: const Color(0xFF2E8B7B), size: 22),
      ),
    );
  }

  Widget _buildWeekdayLabels() {
    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: days
            .map((d) => Expanded(
                  child: Center(
                    child: Text(
                      d,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: d == 'Sun'
                            ? const Color(0xFFF08030)
                            : Colors.black38,
                      ),
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildDaysGrid(Map<String, List<CalEvent>> grouped) {
    final firstDay = DateTime(_focusedDay.year, _focusedDay.month, 1);
    final daysInMonth =
        DateTime(_focusedDay.year, _focusedDay.month + 1, 0).day;
    final startWeekday = firstDay.weekday % 7;
    final today = DateTime.now();
    final cells = <Widget>[];

    for (int i = 0; i < startWeekday; i++) cells.add(const SizedBox());

    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_focusedDay.year, _focusedDay.month, day);
      final isToday = date.year == today.year &&
          date.month == today.month &&
          date.day == today.day;
      final isSelected = date.year == _selectedDay.year &&
          date.month == _selectedDay.month &&
          date.day == _selectedDay.day;
      final dayEvents = grouped[_fmtKey(date)] ?? <CalEvent>[];
      cells.add(_buildDayCell(date, day, isToday, isSelected, dayEvents));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: GridView.count(
        crossAxisCount: 7,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 1.0,
        children: cells,
      ),
    );
  }

  Widget _buildDayCell(
    DateTime date,
    int day,
    bool isToday,
    bool isSelected,
    List<CalEvent> dayEvents,
  ) {
    Color? bgColor;
    Color textColor = Colors.black87;
    FontWeight fontWeight = FontWeight.w400;

    if (isSelected) {
      bgColor = const Color(0xFF2E8B7B);
      textColor = Colors.white;
      fontWeight = FontWeight.w700;
    } else if (isToday) {
      bgColor = const Color(0xFFF5A962).withOpacity(0.15);
      textColor = const Color(0xFFF08030);
      fontWeight = FontWeight.w700;
    }
    if (date.weekday == DateTime.sunday && !isSelected) {
      textColor = const Color(0xFFF08030);
    }

    return GestureDetector(
      onTap: () => _onDayTap(date),
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration:
            BoxDecoration(color: bgColor, shape: BoxShape.circle),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text('$day',
                style: TextStyle(
                    fontSize: 13,
                    color: textColor,
                    fontWeight: fontWeight)),
            if (dayEvents.isNotEmpty)
              Positioned(
                bottom: 3,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: dayEvents
                      .take(3)
                      .map((e) => Container(
                            width: 4,
                            height: 4,
                            margin:
                                const EdgeInsets.symmetric(horizontal: 1),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.white.withOpacity(0.8)
                                  : e.color,
                              shape: BoxShape.circle,
                            ),
                          ))
                      .toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _legendDot(const Color(0xFF2E8B7B), 'Selected'),
          const SizedBox(width: 16),
          _legendDot(const Color(0xFFF5A962), 'Has events'),
          const SizedBox(width: 16),
          _legendDot(const Color(0xFFF08030).withOpacity(0.3), 'Today'),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(
            width: 8,
            height: 8,
            decoration:
                BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(fontSize: 10, color: Colors.black45)),
      ],
    );
  }

  // ── Events list ────────────────────────────────────────────────────────────
  Widget _buildEventsList(List<CalEvent> events, bool hasError) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    const weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final dateLabel =
        '${weekdays[_selectedDay.weekday % 7]}, ${months[_selectedDay.month - 1]} ${_selectedDay.day}';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: Colors.white.withOpacity(0.25), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.event_note_rounded,
                      color: Colors.white, size: 17),
                ),
                const SizedBox(width: 10),
                Text(
                  dateLabel,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.3), width: 1),
                  ),
                  child: Text(
                    '${events.length} event${events.length != 1 ? 's' : ''}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.white.withOpacity(0.2)),
          Expanded(
            child: hasError
                ? _emptyState(
                    Icons.wifi_off_rounded, 'Could not load events')
                : events.isEmpty
                    ? _emptyState(Icons.event_available_rounded,
                        'No events on this day')
                    : FadeTransition(
                        opacity: _fadeAnim,
                        child: ListView.builder(
                          padding:
                              const EdgeInsets.fromLTRB(12, 10, 12, 12),
                          itemCount: events.length,
                          itemBuilder: (context, i) =>
                              _buildEventCard(events[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(IconData icon, String label) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child:
                Icon(icon, color: Colors.white.withOpacity(0.6), size: 28),
          ),
          const SizedBox(height: 12),
          Text(label,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.7), fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildEventCard(CalEvent event) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 5,
            height: 72,
            decoration: BoxDecoration(
              color: event.color,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                bottomLeft: Radius.circular(14),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: event.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child:
                Icon(Icons.event_rounded, color: event.color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  event.title,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87),
                ),
                const SizedBox(height: 3),
                if (event.time.isNotEmpty)
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded,
                          size: 11, color: Colors.black38),
                      const SizedBox(width: 3),
                      Text(event.time,
                          style: const TextStyle(
                              fontSize: 11, color: Colors.black45)),
                    ],
                  ),
                if (event.description.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    event.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 10, color: Colors.black38),
                  ),
                ],
              ],
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _cardAction(
                Icons.edit_rounded,
                const Color(0xFF2E8B7B),
                () => _showEventDialog(context, existingEvent: event),
              ),
              const SizedBox(height: 4),
              _cardAction(
                Icons.delete_rounded,
                const Color(0xFFD45F5F),
                () => _confirmDelete(context, event),
              ),
            ],
          ),
          const SizedBox(width: 10),
        ],
      ),
    );
  }

  Widget _cardAction(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 16),
      ),
    );
  }

  // ── Add/Edit dialog ────────────────────────────────────────────────────────
  void _showEventDialog(BuildContext context, {CalEvent? existingEvent}) {
    final titleCtrl =
        TextEditingController(text: existingEvent?.title ?? '');
    final timeCtrl =
        TextEditingController(text: existingEvent?.time ?? '');
    final descCtrl =
        TextEditingController(text: existingEvent?.description ?? '');
    Color selectedColor = existingEvent?.color ?? _colorOptions.first;
    DateTime selectedDate = existingEvent?.date ?? _selectedDay;
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                          color: Colors.black12,
                          borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E8B7B).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          existingEvent == null
                              ? Icons.add_rounded
                              : Icons.edit_rounded,
                          color: const Color(0xFF2E8B7B),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        existingEvent == null
                            ? 'Add New Event'
                            : 'Edit Event',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _dialogField(
                      controller: titleCtrl,
                      hint: 'Event title *',
                      icon: Icons.title_rounded),
                  const SizedBox(height: 12),
                  _dialogField(
                      controller: timeCtrl,
                      hint: 'Time (e.g. 09:00 AM)',
                      icon: Icons.access_time_rounded),
                  const SizedBox(height: 12),
                  _dialogField(
                      controller: descCtrl,
                      hint: 'Description (optional)',
                      icon: Icons.notes_rounded,
                      maxLines: 2),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                        builder: (c, child) => Theme(
                          data: ThemeData.light().copyWith(
                            colorScheme: const ColorScheme.light(
                                primary: Color(0xFF2E8B7B)),
                          ),
                          child: child!,
                        ),
                      );
                      if (picked != null) {
                        setModalState(() => selectedDate = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FAF7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded,
                              color: Color(0xFF2E8B7B), size: 20),
                          const SizedBox(width: 12),
                          Text(
                            '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}',
                            style: const TextStyle(
                                fontSize: 14, color: Colors.black87),
                          ),
                          const Spacer(),
                          const Icon(Icons.arrow_drop_down,
                              color: Colors.black38),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'EVENT COLOR',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.black45,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: _colorOptions.map((c) {
                      final isSelected = selectedColor == c;
                      return GestureDetector(
                        onTap: () =>
                            setModalState(() => selectedColor = c),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: isSelected ? 36 : 32,
                          height: isSelected ? 36 : 32,
                          margin: const EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(
                            color: c,
                            shape: BoxShape.circle,
                            border: isSelected
                                ? Border.all(
                                    color: Colors.black38, width: 2.5)
                                : Border.all(
                                    color: Colors.transparent,
                                    width: 2.5),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                        color: c.withOpacity(0.5),
                                        blurRadius: 8,
                                        spreadRadius: 1)
                                  ]
                                : null,
                          ),
                          child: isSelected
                              ? const Icon(Icons.check_rounded,
                                  color: Colors.white, size: 16)
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isSaving
                          ? null
                          : () async {
                              if (titleCtrl.text.trim().isEmpty) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  SnackBar(
                                    content: const Text(
                                        'Please enter an event title'),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                    margin: const EdgeInsets.all(16),
                                  ),
                                );
                                return;
                              }
                              setModalState(() => isSaving = true);
                              try {
                                final event = CalEvent(
                                  id: existingEvent?.id,
                                  title: titleCtrl.text.trim(),
                                  time: timeCtrl.text.trim(),
                                  description: descCtrl.text.trim(),
                                  color: selectedColor,
                                  date: selectedDate,
                                );
                                if (existingEvent == null) {
                                  await _service.addEvent(event);
                                } else {
                                  await _service.updateEvent(event);
                                }
                                if (ctx.mounted) Navigator.pop(ctx);
                                if (mounted) {
                                  setState(
                                      () => _selectedDay = selectedDate);
                                }
                              } catch (e) {
                                setModalState(() => isSaving = false);
                                if (ctx.mounted) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    SnackBar(
                                      content: Text('Error: $e'),
                                      backgroundColor: Colors.redAccent,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                      margin: const EdgeInsets.all(16),
                                    ),
                                  );
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E8B7B),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            const Color(0xFF2E8B7B).withOpacity(0.5),
                        padding:
                            const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2.5),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                    existingEvent == null
                                        ? Icons.add_rounded
                                        : Icons.check_rounded,
                                    size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  existingEvent == null
                                      ? 'Save Event'
                                      : 'Update Event',
                                  style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _dialogField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 14, color: Colors.black87),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            TextStyle(color: Colors.grey.shade400, fontSize: 14),
        prefixIcon:
            Icon(icon, color: const Color(0xFF2E8B7B), size: 20),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
              color: Color(0xFF2E8B7B), width: 1.5),
        ),
        filled: true,
        fillColor: const Color(0xFFF0FAF7),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 14),
      ),
    );
  }

  // ── Delete confirm ─────────────────────────────────────────────────────────
  void _confirmDelete(BuildContext context, CalEvent event) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Event',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text(
          'Are you sure you want to delete "${event.title}"?',
          style: const TextStyle(color: Colors.black54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.black45)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _service.deleteEvent(event.id!);
              _showSnackBar('Event deleted');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD45F5F),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: const Text('Delete',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}