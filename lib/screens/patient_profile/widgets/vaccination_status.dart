import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// National Immunization Program vaccines (Philippines)
class _Vaccine {
  final String key;
  final String displayName;
  final List<String> possibleDoses;

  const _Vaccine({
    required this.key,
    required this.displayName,
    required this.possibleDoses,
  });
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

/// Widget displaying the Vaccination Status card in the patient profile.
///
/// Supports two storage modes:
/// 1. Personal  – `users/{uid}/vaccinations/{patientKey}`
/// 2. Shared    – `barangays/{barangayId}/patients/{patientId}/vaccination/record`
class VaccinationStatusSection extends StatefulWidget {
  final String firstName;
  final String lastName;
  final String? patientId;
  final String? barangayId;
  final bool useSharedStorage;

  const VaccinationStatusSection({
    super.key,
    required this.firstName,
    required this.lastName,
    this.patientId,
    this.barangayId,
    this.useSharedStorage = false,
  });

  @override
  State<VaccinationStatusSection> createState() =>
      _VaccinationStatusSectionState();
}

class _VaccinationStatusSectionState extends State<VaccinationStatusSection> {
  // ─── Design tokens ──────────────────────────────────────────────────────────
  static const Color _cardBg        = Color(0xFFB8E6D5);
  static const Color _headerBg      = Color(0xFFD4F1E3);
  static const Color _accentTeal    = Color(0xFF2E8B7B);
  static const Color _positiveGreen = Color(0xFF27AE60);
  static const Color _pendingAmber  = Color(0xFFFF9800);
  static const Color _dividerColor  = Color(0xFFA0D8C5);

  static const double _cardRadius  = 20;
  static const double _innerRadius = 12;
  static const double _pillRadius  = 30;
  static const double _iconRadius  = 10;
  static const double _bodyPadH    = 16;
  static const double _bodyPadV    = 20;
  static const double _sectionGap  = 16;

  static List<BoxShadow> get _cardShadow => [
    BoxShadow(
      color: _accentTeal.withOpacity(0.18),
      blurRadius: 16,
      spreadRadius: 1,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: Colors.white.withOpacity(0.6),
      blurRadius: 1,
      offset: const Offset(0, -1),
    ),
  ];

  static const TextStyle _headerTitleStyle = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w800,
    color: Colors.black87,
    letterSpacing: 0.3,
  );

  static const TextStyle _sectionLabelStyle = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w800,
    color: _accentTeal,
    letterSpacing: 1.4,
  );

  static const TextStyle _pillTextStyle = TextStyle(
    fontSize: 12.5,
    fontWeight: FontWeight.w600,
    color: _accentTeal,
    letterSpacing: 0.2,
  );

  // ─── State ──────────────────────────────────────────────────────────────────

  Map<String, String> _statuses = {};
  DateTime? _lastReviewDate;
  String? _lastModifiedByName;
  bool _loading = true;

  // ─── Firestore ──────────────────────────────────────────────────────────────

  String get _patientKey =>
      '${widget.firstName.trim().toLowerCase()}_${widget.lastName.trim().toLowerCase()}';

  DocumentReference get _docRef {
    if (widget.useSharedStorage &&
        widget.patientId != null &&
        widget.barangayId != null) {
      return FirebaseFirestore.instance
          .collection('barangays')
          .doc(widget.barangayId)
          .collection('patients')
          .doc(widget.patientId)
          .collection('vaccination')
          .doc('record');
    }
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('vaccinations')
        .doc(_patientKey);
  }

  @override
  void initState() {
    super.initState();
    _fetchVaccination();
  }

  Future<void> _fetchVaccination() async {
    try {
      final snap = await _docRef.get();
      if (snap.exists) {
        final data = snap.data() as Map<String, dynamic>? ?? {};
        final Map<String, String> loaded = {};
        for (final v in _vaccines) {
          final value = data[v.key];
          if (value is bool) {
            loaded[v.key] = value ? v.possibleDoses.last : 'Pending';
          } else if (value is String) {
            if (value == 'Completed' && !v.possibleDoses.contains('Completed')) {
              loaded[v.key] = v.possibleDoses.last;
            } else {
              loaded[v.key] = value;
            }
          } else {
            loaded[v.key] = 'Pending';
          }
        }
        final ts = data['lastReviewDate'] as Timestamp?;
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

      String userName = 'Unknown';
      if (currentUser != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();
        userName = userDoc.data()?['fullName'] ??
            userDoc.data()?['username'] ??
            currentUser.email ??
            'Unknown';
      }

      final payload = <String, dynamic>{
        'firstName':          widget.firstName,
        'lastName':           widget.lastName,
        'lastReviewDate':     Timestamp.fromDate(now),
        'lastModifiedBy':     currentUser?.uid ?? '',
        'lastModifiedByName': userName,
        'updatedAt':          Timestamp.fromDate(now),
        ...updated,
      };

      await _docRef.set(payload, SetOptions(merge: true));

      setState(() {
        _statuses           = Map.from(updated);
        _lastReviewDate     = now;
        _lastModifiedByName = userName;
      });
    } catch (e) {
      debugPrint('Error saving vaccination: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save vaccination: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  // ─── Computed props ──────────────────────────────────────────────────────────

  bool _isCompleted(String dose) => dose != 'Pending' && dose.isNotEmpty;

  int get _completedCount => _statuses.values.where(_isCompleted).length;

  bool get _allCompleted => _statuses.values.every(_isCompleted);

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${months[date.month - 1]} ${date.day.toString().padLeft(2, '0')}, ${date.year}';
  }

  // ─── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(_cardRadius),
        boxShadow: _cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          _loading ? _buildLoading() : _buildBody(),
        ],
      ),
    );
  }

  // ─── Structural widgets ─────────────────────────────────────────────────────

  Widget _buildHeader() => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: const BoxDecoration(
          color: _headerBg,
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(_cardRadius)),
        ),
        child: Row(
          children: [
            _buildIconBox(Icons.health_and_safety_rounded),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Vaccination Status', style: _headerTitleStyle),
            ),
            if (widget.useSharedStorage) _buildSharedBadge(),
          ],
        ),
      );

  Widget _buildIconBox(IconData icon) => Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _accentTeal.withOpacity(0.15),
          borderRadius: BorderRadius.circular(_iconRadius),
        ),
        child: Icon(icon, color: _accentTeal, size: 22),
      );

  Widget _buildSharedBadge() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: _accentTeal,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_rounded, size: 12, color: Colors.white),
            SizedBox(width: 4),
            Text(
              'Shared',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      );

  Widget _buildLoading() => const Padding(
        padding: EdgeInsets.all(32),
        child: Center(
          child: CircularProgressIndicator(color: _accentTeal),
        ),
      );

  Widget _buildDatePill(String label) => Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: _accentTeal.withOpacity(0.12),
            borderRadius: BorderRadius.circular(_pillRadius),
            border: Border.all(color: _accentTeal.withOpacity(0.25), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.calendar_today_rounded,
                  size: 13, color: _accentTeal),
              const SizedBox(width: 6),
              Text(label, style: _pillTextStyle),
            ],
          ),
        ),
      );

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) =>
      Center(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 28, vertical: 11),
            decoration: BoxDecoration(
              color: _accentTeal,
              borderRadius: BorderRadius.circular(_pillRadius),
              boxShadow: [
                BoxShadow(
                  color: _accentTeal.withOpacity(0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  // ─── Body ───────────────────────────────────────────────────────────────────

  Widget _buildBody() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(_bodyPadH, 4, _bodyPadH, _bodyPadV),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDatePill('Last Review: ${_formatDate(_lastReviewDate)}'),
          if (_lastModifiedByName != null && widget.useSharedStorage) ...[
            const SizedBox(height: 6),
            Center(
              child: Text(
                'Updated by: $_lastModifiedByName',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.black.withOpacity(0.45),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
          const SizedBox(height: _sectionGap),

          // ── Progress card ──
          _buildProgressCard(),
          const SizedBox(height: _sectionGap),

          // ── Vaccine list ──
          const Divider(color: _dividerColor, thickness: 1.2),
          const SizedBox(height: 12),
          const Text('IMMUNIZATION RECORD', style: _sectionLabelStyle),
          const SizedBox(height: 10),
          ..._vaccines.map((v) {
            final dose      = _statuses[v.key] ?? 'Pending';
            final completed = _isCompleted(dose);
            return _buildVaccineRow(v.displayName, dose, completed);
          }),
          const SizedBox(height: _sectionGap),

          _buildActionButton(
            icon: Icons.edit_rounded,
            label: 'Update Record',
            onTap: () => _showUpdateSheet(context),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard() {
    final total    = _vaccines.length;
    final completed = _completedCount;
    final progress  = total == 0 ? 0.0 : completed / total;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.45),
        borderRadius: BorderRadius.circular(_innerRadius + 2),
        border: Border.all(color: Colors.white.withOpacity(0.7), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    _allCompleted
                        ? Icons.check_circle_rounded
                        : Icons.timelapse_rounded,
                    size: 18,
                    color: _allCompleted ? _positiveGreen : _accentTeal,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _allCompleted
                        ? 'All vaccinations complete'
                        : '$completed of $total vaccines completed',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _allCompleted ? _positiveGreen : Colors.black87,
                    ),
                  ),
                ],
              ),
              Text(
                '${(progress * 100).round()}%',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: _allCompleted ? _positiveGreen : _accentTeal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: _dividerColor.withOpacity(0.5),
              valueColor: AlwaysStoppedAnimation<Color>(
                _allCompleted ? _positiveGreen : _accentTeal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVaccineRow(String name, String dose, bool completed) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            completed
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            size: 18,
            color: completed
                ? _positiveGreen
                : _pendingAmber.withOpacity(0.8),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 110,
            child: Text(
              name,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: Colors.black.withOpacity(0.8),
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: completed
                    ? _positiveGreen.withOpacity(0.12)
                    : _pendingAmber.withOpacity(0.10),
                borderRadius: BorderRadius.circular(_pillRadius),
              ),
              child: Text(
                dose,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: completed ? _positiveGreen : _pendingAmber,
                ),
              ),
            ),
          ),
        ],
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
        builder: (ctx, setSheetState) => Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.85,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 14, bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: _accentTeal.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(_iconRadius),
                      ),
                      child: const Icon(Icons.edit_rounded,
                          color: _accentTeal, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Update Vaccination Record',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: _accentTeal,
                          ),
                        ),
                        Text(
                          '${widget.firstName} ${widget.lastName}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              if (widget.useSharedStorage) ...[
                const SizedBox(height: 10),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(_innerRadius),
                    border: Border.all(
                        color: _accentTeal.withOpacity(0.25)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.people_rounded,
                          size: 14, color: _accentTeal),
                      SizedBox(width: 6),
                      Text(
                        'Changes will be shared with barangay team',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _accentTeal,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),
              const Divider(height: 1, color: Color(0xFFEEEEEE)),

              // Vaccine rows
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  children: _vaccines.map((v) {
                    final currentDose = draft[v.key] ?? 'Pending';
                    final dropdownValue = (currentDose == 'Completed' &&
                            !v.possibleDoses.contains('Completed'))
                        ? v.possibleDoses.last
                        : (v.possibleDoses.contains(currentDose)
                            ? currentDose
                            : v.possibleDoses.first);
                    final isCompleted = _isCompleted(currentDose);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                        decoration: BoxDecoration(
                          color: isCompleted
                              ? _positiveGreen.withOpacity(0.07)
                              : _pendingAmber.withOpacity(0.07),
                          borderRadius:
                              BorderRadius.circular(_innerRadius + 2),
                          border: Border.all(
                            color: isCompleted
                                ? _positiveGreen.withOpacity(0.3)
                                : _pendingAmber.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isCompleted
                                  ? Icons.check_circle_rounded
                                  : Icons.radio_button_unchecked_rounded,
                              color: isCompleted
                                  ? _positiveGreen
                                  : _pendingAmber,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: Text(
                                v.displayName,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: DropdownButtonFormField<String>(
                                value: dropdownValue,
                                isExpanded: true,
                                decoration: InputDecoration(
                                  contentPadding:
                                      const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 8),
                                  border: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                      color: isCompleted
                                          ? _positiveGreen
                                          : _pendingAmber,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                      color: isCompleted
                                          ? _positiveGreen
                                              .withOpacity(0.5)
                                          : _pendingAmber.withOpacity(0.5),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                      color: _accentTeal,
                                      width: 2,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                                items: v.possibleDoses.map((dose) {
                                  return DropdownMenuItem<String>(
                                    value: dose,
                                    child: Text(
                                      dose,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: dose == 'Pending'
                                            ? FontWeight.w500
                                            : FontWeight.w700,
                                        color: dose == 'Pending'
                                            ? _pendingAmber
                                            : Colors.black87,
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setSheetState(
                                        () => draft[v.key] = value);
                                  }
                                },
                                icon: const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: _accentTeal,
                                ),
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
                          const SnackBar(
                            content: Text('Vaccination record updated.'),
                            backgroundColor: _accentTeal,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accentTeal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(_pillRadius),
                      ),
                      elevation: 4,
                      shadowColor: _accentTeal.withOpacity(0.4),
                    ),
                    child: const Text(
                      'Save Changes',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
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