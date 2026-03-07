import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../services/connectivity_service.dart';
import 'package:flutter/foundation.dart';

/// National Immunization Program vaccines (Philippines)
class _Vaccine {
  final String key;
  final String displayName;
  final List<String> possibleDoses;
  const _Vaccine({required this.key, required this.displayName, required this.possibleDoses});
}

const _vaccines = [
  _Vaccine(key: 'bcg',        displayName: 'BCG',         possibleDoses: ['Pending', '1st dose']),
  _Vaccine(key: 'hepatitisB', displayName: 'HEP B',       possibleDoses: ['Pending', '1st dose', '2nd dose', '3rd dose']),
  _Vaccine(key: 'dtap',       displayName: 'PENTAVALENT', possibleDoses: ['Pending', '1st dose', '2nd dose', '3rd dose', '4th dose']),
  _Vaccine(key: 'opv',        displayName: 'OPV',         possibleDoses: ['Pending', '1st dose', '2nd dose', '3rd dose']),
  _Vaccine(key: 'ipv',        displayName: 'IPV',         possibleDoses: ['Pending', '1st dose', '2nd dose', '3rd dose', '4th dose']),
  _Vaccine(key: 'pcv',        displayName: 'PCV',         possibleDoses: ['Pending', '1st dose', '2nd dose', '3rd dose', '4th dose']),
  _Vaccine(key: 'mmr',        displayName: 'MMR',         possibleDoses: ['Pending', '1st dose', '2nd dose']),
];

/// Vaccination Status card — styled to match ProfileInfoCard.
class VaccinationStatusSection extends StatefulWidget {
  final String firstName;
  final String lastName;
  final String? patientId;
  final String? barangayId;
  final bool useSharedStorage;
  final Map<String, String>? localStatuses;
  final DateTime? localLastReviewDate;

  const VaccinationStatusSection({
    super.key,
    required this.firstName,
    required this.lastName,
    this.patientId,
    this.barangayId,
    this.useSharedStorage = false,
    this.localStatuses,
    this.localLastReviewDate,
  });

  @override
  State<VaccinationStatusSection> createState() => _VaccinationStatusSectionState();
}

class _VaccinationStatusSectionState extends State<VaccinationStatusSection> {
  // ─── Design Tokens (matches ProfileInfoCard) ────────────────────────────────
  static const Color _orange      = Color(0xFFF08030);
  static const Color _orangeLight = Color(0xFFF5A962);
  static const Color _surface     = Color(0xFFFFFFFF);
  static const Color _surfaceDim  = Color(0xFFFAFAFA);
  static const Color _border      = Color(0xFFE8E8ED);
  static const Color _ink         = Color(0xFF1C1C1E);
  static const Color _inkMid      = Color(0xFF6C6C70);
  static const Color _green       = Color(0xFF34C759);
  static const Color _greenBg     = Color(0xFFEDF7F1);
  static const Color _greenText   = Color(0xFF1A7A3C);
  static const Color _amber       = Color(0xFFF08030);
  static const Color _amberBg     = Color(0xFFFFF6EE);

  static const double _r  = 18;
  static const double _ri = 12;

  static List<BoxShadow> get _shadow => [
        BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 20, offset: const Offset(0, 6)),
      ];

  // ─── State ──────────────────────────────────────────────────────────────────

  Map<String, String> _statuses = {};
  DateTime? _lastReviewDate;
  String? _lastModifiedByName;
  bool _loading = true;

  // ─── Firestore ──────────────────────────────────────────────────────────────

  String get _patientKey =>
      '${widget.firstName.trim().toLowerCase()}_${widget.lastName.trim().toLowerCase()}';

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    // If we have local statuses and we're offline, prefer them and skip Firestore.
    //final online = await ConnectivityService.instance.checkOnline();
    final online = kIsWeb ? true : await ConnectivityService.instance.checkOnline();
    if (!online && widget.localStatuses != null && widget.localStatuses!.isNotEmpty) {
      setState(() {
        _statuses = Map<String, String>.from(widget.localStatuses!);
        _lastReviewDate = widget.localLastReviewDate;
        _loading = false;
      });
      return;
    }
    _fetchVaccination();
  }

  @override
  void didUpdateWidget(covariant VaccinationStatusSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // When assessments update and we get new local statuses while offline, apply them.
    if (widget.localStatuses != null &&
        widget.localStatuses!.isNotEmpty &&
        widget.localStatuses != oldWidget.localStatuses) {
      _applyLocalIfOffline();
    }
  }

  Future<void> _applyLocalIfOffline() async {
    //final online = await ConnectivityService.instance.checkOnline();
    final online = kIsWeb ? true : await ConnectivityService.instance.checkOnline();
    if (!online && widget.localStatuses != null && widget.localStatuses!.isNotEmpty) {
      setState(() {
        _statuses = Map<String, String>.from(widget.localStatuses!);
        _lastReviewDate = widget.localLastReviewDate ?? _lastReviewDate;
        _loading = false;
      });
    }
  }

  Future<void> _fetchVaccination() async {
    try {
      // Avoid invalid document paths in offline / missing-id scenarios.
      DocumentReference? ref;
      if (widget.useSharedStorage) {
        final pid = widget.patientId;
        final bid = widget.barangayId;
        if (pid == null || pid.isEmpty || bid == null || bid.isEmpty) {
          setState(() {
            _statuses = {for (final v in _vaccines) v.key: 'Pending'};
            _loading = false;
          });
          return;
        }
        ref = FirebaseFirestore.instance
            .collection('barangays')
            .doc(bid)
            .collection('patients')
            .doc(pid)
            .collection('vaccination')
            .doc('record');
      } else {
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid == null || uid.isEmpty) {
          setState(() {
            _statuses = {for (final v in _vaccines) v.key: 'Pending'};
            _loading = false;
          });
          return;
        }
        ref = FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('vaccinationStatus')
            .doc(_patientKey);
      }

      final snap = await ref.get();
      if (snap.exists) {
        final raw = snap.data();
        final Map<String, dynamic> data =
            raw is Map<String, dynamic> ? raw : Map<String, dynamic>.from(raw as Map);

        // For shared records, vaccine fields are at the root.
        // For per-user records, they live inside a "statuses" map.
        Map<String, dynamic> source;
        if (widget.useSharedStorage) {
          source = data;
        } else {
          final rawStatuses = data['statuses'];
          if (rawStatuses is Map<String, dynamic>) {
            source = rawStatuses;
          } else if (rawStatuses is Map) {
            source = Map<String, dynamic>.from(rawStatuses);
          } else {
            source = <String, dynamic>{};
          }
        }

        final Map<String, String> loaded = {};
        for (final v in _vaccines) {
          final value = source[v.key];
          if (value is bool) {
            loaded[v.key] = value ? v.possibleDoses.last : 'Pending';
          } else if (value is String) {
            loaded[v.key] = (value == 'Completed' && !v.possibleDoses.contains('Completed'))
                ? v.possibleDoses.last
                : value;
          } else {
            loaded[v.key] = 'Pending';
          }
        }
        final Timestamp? ts = widget.useSharedStorage
            ? data['lastReviewDate'] as Timestamp?
            : data['updatedAt'] as Timestamp?;
        setState(() {
          _statuses           = loaded;
          _lastReviewDate     = ts?.toDate();
          _lastModifiedByName = data['lastModifiedByName'] as String?;
          _loading            = false;
        });
      } else {
        setState(() {
          _statuses = {for (final v in _vaccines) v.key: 'Pending'};
          _loading  = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching vaccination: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _saveVaccination(Map<String, String> updated) async {
    try {
      final now         = DateTime.now();
      final currentUser = FirebaseAuth.instance.currentUser;
      String userName   = 'Unknown';
      if (currentUser != null) {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
        userName = userDoc.data()?['fullName'] ?? userDoc.data()?['username'] ?? currentUser.email ?? 'Unknown';
      }
      // Build the same document reference logic as in _fetchVaccination
      DocumentReference? ref;
      if (widget.useSharedStorage) {
        final pid = widget.patientId;
        final bid = widget.barangayId;
        if (pid == null || pid.isEmpty || bid == null || bid.isEmpty) {
          // No valid shared document to write to.
          return;
        }
        ref = FirebaseFirestore.instance
            .collection('barangays')
            .doc(bid)
            .collection('patients')
            .doc(pid)
            .collection('vaccination')
            .doc('record');
      } else {
        final uid = currentUser?.uid;
        if (uid == null || uid.isEmpty) {
          // Cannot save without a logged-in user.
          return;
        }
        ref = FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('vaccinationStatus')
            .doc(_patientKey);
      }

      await ref.set({
        'firstName': widget.firstName,
        'lastName':  widget.lastName,
        'lastReviewDate':     Timestamp.fromDate(now),
        'lastModifiedBy':     currentUser?.uid ?? '',
        'lastModifiedByName': userName,
        'updatedAt':          Timestamp.fromDate(now),
        ...updated,
      }, SetOptions(merge: true));
      setState(() {
        _statuses           = Map.from(updated);
        _lastReviewDate     = now;
        _lastModifiedByName = userName;
      });
    } catch (e) {
      debugPrint('Error saving vaccination: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  // ─── Computed ───────────────────────────────────────────────────────────────

  bool _isCompleted(String dose) => dose != 'Pending' && dose.isNotEmpty;
  int  get _completedCount => _statuses.values.where(_isCompleted).length;
  bool get _allCompleted   => _statuses.values.every(_isCompleted);

  String _formatDate(DateTime? d) {
    if (d == null) return 'N/A';
    const m = ['January','February','March','April','May','June','July','August','September','October','November','December'];
    return '${m[d.month - 1]} ${d.day.toString().padLeft(2, '0')}, ${d.year}';
  }

  // ─── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(_r),
        border: Border.all(color: _border, width: 1),
        boxShadow: _shadow,
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Accent bar
          Container(
            height: 5,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_orangeLight, _orange]),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(_r)),
            ),
          ),
          _buildHeader(),
          const Divider(height: 1, color: _border),
          _loading ? _buildLoading() : _buildBody(),
        ],
      ),
    );
  }

  // ─── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            _iconBox(Icons.health_and_safety_rounded),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Vaccination Status',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: _ink,
                  letterSpacing: -0.3,
                ),
              ),
            ),
            if (widget.useSharedStorage) _sharedBadge(),
          ],
        ),
      );

  Widget _iconBox(IconData icon) => Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _orange.withOpacity(0.10),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: _orange, size: 20),
      );

  Widget _sharedBadge() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [_orangeLight, _orange]),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_rounded, size: 12, color: Colors.white),
            SizedBox(width: 4),
            Text('Shared', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
      );

  Widget _buildLoading() => const Padding(
        padding: EdgeInsets.all(36),
        child: Center(child: CircularProgressIndicator(color: _orange)),
      );

  // ─── Body ───────────────────────────────────────────────────────────────────

  Widget _buildBody() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date pill
          _datePill('Last Review: ${_formatDate(_lastReviewDate)}'),
          if (_lastModifiedByName != null && widget.useSharedStorage) ...[
            const SizedBox(height: 6),
            Text(
              'Updated by: $_lastModifiedByName',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: _inkMid, fontStyle: FontStyle.italic),
            ),
          ],
          const SizedBox(height: 14),

          // Progress card
          _buildProgressCard(),
          const SizedBox(height: 16),

          // Vaccine list
          const Divider(height: 1, color: _border),
          const SizedBox(height: 12),
          const Text(
            'IMMUNIZATION RECORD',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _inkMid, letterSpacing: 1.2),
          ),
          const SizedBox(height: 10),
          ..._vaccines.map((v) {
            final dose      = _statuses[v.key] ?? 'Pending';
            final completed = _isCompleted(dose);
            return _vaccineRow(v.displayName, dose, completed);
          }),
          const SizedBox(height: 16),

          // Update button
          Center(
            child: GestureDetector(
              onTap: () => _showUpdateSheet(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 11),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [_orangeLight, _orange]),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(color: _orange.withOpacity(0.28), blurRadius: 12, offset: const Offset(0, 4)),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.edit_rounded, size: 16, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'Update Record',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.3),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _datePill(String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: _orange.withOpacity(0.08),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: _orange.withOpacity(0.20), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.calendar_today_rounded, size: 13, color: _orange),
            const SizedBox(width: 7),
            Text(
              label,
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: _orange, letterSpacing: 0.1),
            ),
          ],
        ),
      );

  Widget _buildProgressCard() {
    final total     = _vaccines.length;
    final completed = _completedCount;
    final progress  = total == 0 ? 0.0 : completed / total;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surfaceDim,
        borderRadius: BorderRadius.circular(_ri),
        border: Border.all(color: _border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: _allCompleted ? _greenBg : _amberBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _allCompleted ? Icons.check_circle_rounded : Icons.timelapse_rounded,
                      size: 14,
                      color: _allCompleted ? _greenText : _amber,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _allCompleted ? 'All vaccinations complete' : '$completed of $total completed',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _allCompleted ? _greenText : _ink,
                    ),
                  ),
                ],
              ),
              Text(
                '${(progress * 100).round()}%',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: _allCompleted ? _greenText : _orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              backgroundColor: _border,
              valueColor: AlwaysStoppedAnimation<Color>(
                _allCompleted ? _green : _orange,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _vaccineRow(String name, String dose, bool completed) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: _surfaceDim,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _border, width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: completed ? _greenBg : _amberBg,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                completed ? Icons.check_rounded : Icons.schedule_rounded,
                size: 12,
                color: completed ? _greenText : _amber,
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 100,
              child: Text(
                name,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _ink),
              ),
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: completed ? _greenBg : _amberBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  dose,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: completed ? _greenText : _amber,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Bottom sheet ───────────────────────────────────────────────────────────

  void _showUpdateSheet(BuildContext context) {
    final draft = Map<String, String>.from(_statuses);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.85),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(top: 14, bottom: 20),
                decoration: BoxDecoration(color: _border, borderRadius: BorderRadius.circular(2)),
              ),

              // Sheet header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: _orange.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.edit_rounded, color: _orange, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Update Vaccination Record',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _ink),
                        ),
                        Text(
                          '${widget.firstName} ${widget.lastName}',
                          style: const TextStyle(fontSize: 13, color: _inkMid),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              if (widget.useSharedStorage) ...[
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: _amberBg,
                      borderRadius: BorderRadius.circular(_ri),
                      border: Border.all(color: _orange.withOpacity(0.25)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.people_rounded, size: 14, color: _orange),
                        SizedBox(width: 6),
                        Text(
                          'Changes will be shared with barangay team',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _orange),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 16),
              const Divider(height: 1, color: _border),

              // Vaccine rows
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  children: _vaccines.map((v) {
                    final current     = draft[v.key] ?? 'Pending';
                    final dropVal     = (current == 'Completed' && !v.possibleDoses.contains('Completed'))
                        ? v.possibleDoses.last
                        : (v.possibleDoses.contains(current) ? current : v.possibleDoses.first);
                    final isCompleted = _isCompleted(current);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                        decoration: BoxDecoration(
                          color: isCompleted ? _greenBg : _amberBg,
                          borderRadius: BorderRadius.circular(_ri),
                          border: Border.all(
                            color: isCompleted ? _green.withOpacity(0.35) : _amber.withOpacity(0.35),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isCompleted ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                              color: isCompleted ? _greenText : _amber,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: Text(
                                v.displayName,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _ink),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: DropdownButtonFormField<String>(
                                value: dropVal,
                                isExpanded: true,
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(color: isCompleted ? _green : _amber),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                      color: isCompleted ? _green.withOpacity(0.5) : _amber.withOpacity(0.5),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(color: _orange, width: 2),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                                items: v.possibleDoses.map((dose) => DropdownMenuItem(
                                  value: dose,
                                  child: Text(
                                    dose,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: dose == 'Pending' ? FontWeight.w500 : FontWeight.w700,
                                      color: dose == 'Pending' ? _amber : _ink,
                                    ),
                                  ),
                                )).toList(),
                                onChanged: (val) {
                                  if (val != null) setSheet(() => draft[v.key] = val);
                                },
                                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _orange),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              // Save button
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      await _saveVaccination(draft);
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Vaccination record updated.'),
                            backgroundColor: _orange,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Save Changes',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}