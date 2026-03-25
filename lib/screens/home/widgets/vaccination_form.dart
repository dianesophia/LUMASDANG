import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'vaccine_dose_selector.dart';

// ── Column definition ─────────────────────────────────────────────────────────
class _AgeCol {
  final String key;
  final String label;
  const _AgeCol(this.key, this.label);
}

// ── Age-group section for the spanning header ─────────────────────────────────
class _AgeGroup {
  final String label;
  final Color color;
  final int colCount;
  const _AgeGroup(this.label, this.color, this.colCount);
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared mapping: vaccine display name → camelCase Firestore key
// Must match the keys used in VaccinationStatusSection._vaccines
// ─────────────────────────────────────────────────────────────────────────────
const Map<String, String> kVaccineNameToKey = {
  'BCG':            'bcg',
  'Hepatitis B':    'hepatitisB',
  'Pentavalent':    'pentavalent',
  'Oral Polio':     'oralPolio',
  'IPV':            'ipv',
  'Phenumococcal':  'phenumococcal',
  'Rotavirus':      'rotavirus',
  'Measles':        'measles',
  'MMR':            'mmr',
  'Hepatitis A':    'hepatitisA',
  'Chickenpox':     'chickenpox',
  'Typhoid':        'typhoid',
  'Pneumo 23':      'pneumo23',
  'FLU':            'flu',
  'OPV':            'opv',
  'DTwP/DTaP-Hib':  'dtapHib',
  'PCV':            'pcv',
  'Influenza':      'influenza',
  'MMR/MR':         'mmrMr',
  'Measles/MMR':    'measlesMmr',
  'JEV':            'jev',
  'Varicella':      'varicella',
  'Rabies':         'rabies',
  'Meningococcal':  'meningococcal',
  'Cholera':        'cholera',
};

// ─────────────────────────────────────────────────────────────────────────────
// Ordered dose labels per vaccine — the LAST administered dose label is what
// VaccinationStatusSection displays. Order matters: last in list = "most done".
// These must match VaccinationStatusSection._vaccines[*].possibleDoses.
// ─────────────────────────────────────────────────────────────────────────────
const Map<String, List<String>> kVaccineDoseLabels = {
  'BCG':           ['1st dose'],
  'Hepatitis B':   ['1st dose', '2nd dose', '3rd dose'],
  'Pentavalent':   ['1st dose', '2nd dose', '3rd dose'],
  'Oral Polio':    ['1st dose', '2nd dose', '3rd dose', 'Booster'],
  'IPV':           ['1st dose', '2nd dose', '3rd dose'],
  'Phenumococcal': ['1st dose', '2nd dose', '3rd dose', 'Booster'],
  'Rotavirus':     ['1st dose', '2nd dose', '3rd dose'],
  'Measles':       ['1st dose'],
  'MMR':           ['1st dose', '2nd dose'],
  'Hepatitis A':   ['1st dose', '2nd dose'],
  'Chickenpox':    ['1st dose', '2nd dose'],
  'Typhoid':       ['See annotations'],
  'Pneumo 23':     ['See annotations'],
  'FLU':           ['1st dose', '2nd dose'],
  'OPV':           ['1st dose', '2nd dose', '3rd dose', 'Booster'],
  'DTwP/DTaP-Hib': ['1st dose', '2nd dose', '3rd dose', '1st booster'],
  'PCV':           ['1st dose', '2nd dose', '3rd dose', 'Booster'],
  'Influenza':     ['1st dose', '2nd dose'],
  'MMR/MR':        ['1st dose MMR', '2nd dose MMR'],
  'Measles/MMR':   ['Measles', '1st dose MMR', '2nd dose MMR'],
  'JEV':           ['1st dose', '2nd dose'],
  'Varicella':     ['1st dose', '2nd dose'],
  'Rabies':        ['Rabies series'],
  'Meningococcal': ['See annotations'],
  'Cholera':       ['See annotations'],
};

// ─────────────────────────────────────────────────────────────────────────────
// Computes the dose label to store in Firestore for a given vaccine.
// We look at all columns that have a recorded dose, count how many are ticked,
// and return the corresponding label from kVaccineDoseLabels.
// ─────────────────────────────────────────────────────────────────────────────
String _computeDoseLabel(String vaccineName, Map<String, String?> doses) {
  final labels = kVaccineDoseLabels[vaccineName] ?? [];
  if (labels.isEmpty) return 'Pending';

  // Count how many column slots have a dose recorded
  final count = doses.values.where((d) => d != null).length;
  if (count == 0) return 'Pending';

  // Return the label matching the count (clamped to last label)
  final idx = (count - 1).clamp(0, labels.length - 1);
  return labels[idx];
}

class VaccinationForm extends StatefulWidget {
  final String? patientId;
  final String? barangayId;
  final String? firstName;
  final String? lastName;
  /// useSharedStorage=true  → barangays/{bid}/patients/{pid}/vaccination/record
  /// useSharedStorage=false → users/{uid}/vaccinationStatus/{patientKey}
  final bool useSharedStorage;
  final Function(Map<String, dynamic>)? onDataChanged;

  const VaccinationForm({
    super.key,
    this.patientId,
    this.barangayId,
    this.firstName,
    this.lastName,
    this.useSharedStorage = false,
    this.onDataChanged,
  });

  @override
  State<VaccinationForm> createState() => _VaccinationFormState();
}

class _VaccinationFormState extends State<VaccinationForm> {
  // ── Theme ──────────────────────────────────────────────────────────────────
  static const Color _primary    = Color(0xFFF5A962);
  static const Color _surface    = Colors.white;
  static const Color _surfaceAlt = Color(0xFFFAFAFA);
  static const Color _border     = Color(0xFFEEEEEE);
  static const Color _textColor  = Color(0xFF1A1A1A);

  // ── Age columns ────────────────────────────────────────────────────────────
  static const _cols = <_AgeCol>[
    _AgeCol('BIRTH',   'Birth'),
    _AgeCol('1MO',     '1 mo.'),
    _AgeCol('6WKS',    '6 wks.'),
    _AgeCol('2MO',     '2 mos.'),
    _AgeCol('10WKS',   '10 wks.'),
    _AgeCol('14WKS',   '14 wks.'),
    _AgeCol('4MO',     '4 mos.'),
    _AgeCol('6MO',     '6 mos.'),
    _AgeCol('9MO',     '9 mos.'),
    _AgeCol('12MO',    '12 mos.'),
    _AgeCol('15MO',    '15 mos.'),
    _AgeCol('18MO',    '18 mos.'),
    _AgeCol('19-23MO', '19-23 mos.'),
    _AgeCol('2-5YR',   '2-5 yrs.'),
  ];

  // ── Age-group spanning headers ─────────────────────────────────────────────
  static const _ageGroups = <_AgeGroup>[
    _AgeGroup('INFANCY',         Color(0xFFADD8E6), 10),
    _AgeGroup('EARLY CHILDHOOD', Color(0xFFFFB6C1),  4),
  ];

  // ── All vaccines ───────────────────────────────────────────────────────────
  static const _vaccineNames = [
    'BCG', 'Hepatitis B', 'Pentavalent', 'Oral Polio', 'IPV',
    'Phenumococcal', 'Rotavirus', 'Measles', 'MMR', 'Hepatitis A',
    'Chickenpox', 'Typhoid', 'Pneumo 23', 'FLU', 'OPV', 'DTwP/DTaP-Hib',
    'PCV', 'Influenza', 'MMR/MR', 'Measles/MMR', 'JEV', 'Varicella',
    'Rabies', 'Meningococcal', 'Cholera',
  ];

  // ── Next-dose intervals (days between consecutive doses) ──────────────────
  static const Map<String, List<int>> _intervals = {
    'BCG':            [],
    'Hepatitis B':    [28, 150],
    'Pentavalent':    [28, 28],
    'Oral Polio':     [28, 28, 105],
    'IPV':            [28, 28],
    'Phenumococcal':  [28, 28, 105],
    'Rotavirus':      [28, 28],
    'Measles':        [],
    'MMR':            [91],
    'Hepatitis A':    [180],
    'Chickenpox':     [91],
    'Typhoid':        [],
    'Pneumo 23':      [],
    'FLU':            [28],
    'OPV':            [28, 28, 105],
    'DTwP/DTaP-Hib':  [28, 28, 365],
    'PCV':            [28, 28, 105],
    'Influenza':      [28],
    'MMR/MR':         [91],
    'Measles/MMR':    [91, 182],
    'JEV':            [420],
    'Varicella':      [91],
    'Rabies':         [7, 21],
    'Meningococcal':  [],
    'Cholera':        [],
  };

  // ── Schedule (which columns are valid per vaccine) ─────────────────────────
  static const Map<String, Map<String, List<String>>> _schedule = {
    'BCG':           {'BIRTH':  ['1st dose']},
    'Hepatitis B':   {'BIRTH': ['1st dose'], '1MO': ['2nd dose'], '6MO': ['3rd dose']},
    'Pentavalent':   {'6WKS': ['1st dose'], '10WKS': ['2nd dose'], '14WKS': ['3rd dose']},
    'Oral Polio':    {'6WKS': ['1st dose'], '10WKS': ['2nd dose'], '14WKS': ['3rd dose'], '9MO': ['Booster']},
    'IPV':           {'6WKS': ['1st dose'], '10WKS': ['2nd dose'], '14WKS': ['3rd dose']},
    'Phenumococcal': {'6WKS': ['1st dose'], '10WKS': ['2nd dose'], '14WKS': ['3rd dose'], '9MO': ['Booster']},
    'Rotavirus':     {'6WKS': ['1st dose'], '10WKS': ['2nd dose'], '14WKS': ['3rd dose']},
    'Measles':       {'6MO':  ['1st dose']},
    'MMR':           {'12MO': ['1st dose'], '15MO': ['2nd dose']},
    'Hepatitis A':   {'12MO': ['1st dose'], '18MO': ['2nd dose']},
    'Chickenpox':    {'12MO': ['1st dose'], '15MO': ['2nd dose']},
    'Typhoid':       {'2-5YR': ['See annotations']},
    'Pneumo 23':     {'2-5YR': ['See annotations']},
    'FLU':           {'6MO': ['1st dose'], '9MO': ['2nd dose']},
    'OPV':           {'6WKS': ['1st dose'], '10WKS': ['2nd dose'], '14WKS': ['3rd dose'], '9MO': ['Booster']},
    'DTwP/DTaP-Hib': {'6WKS': ['1st dose'], '10WKS': ['2nd dose'], '14WKS': ['3rd dose'], '15MO': ['1st booster']},
    'PCV':           {'6WKS': ['1st dose'], '10WKS': ['2nd dose'], '14WKS': ['3rd dose'], '9MO': ['Booster']},
    'Influenza':     {'6MO': ['1st dose'], '9MO': ['2nd dose']},
    'MMR/MR':        {'9MO': ['1st dose MMR'], '12MO': ['2nd dose MMR']},
    'Measles/MMR':   {'6MO': ['Measles'], '9MO': ['1st dose MMR'], '15MO': ['2nd dose MMR']},
    'JEV':           {'9MO': ['1st dose'], '19-23MO': ['2nd dose']},
    'Varicella':     {'12MO': ['1st dose'], '15MO': ['2nd dose']},
    'Rabies':        {'2-5YR': ['Rabies series']},
    'Meningococcal': {'9MO': ['See annotations'], '12MO': ['See annotations'], '2-5YR': ['See annotations']},
    'Cholera':       {'2-5YR': ['See annotations']},
  };

  // ── State ──────────────────────────────────────────────────────────────────
  final Map<String, Map<String, String?>>               _doses           = {};
  final Map<String, Map<String, TextEditingController>> _dateControllers = {};
  final Map<String, String>                             _nextDoseDates   = {};
  final Set<String>                                     _expandedRows    = {};
  bool _saving = false;

  // ── Firestore helpers ──────────────────────────────────────────────────────
  String get _patientKey {
    final f = (widget.firstName ?? '').trim().toLowerCase();
    final l = (widget.lastName  ?? '').trim().toLowerCase();
    return '${f}_$l';
  }

  DocumentReference? get _firestoreRef {
    if (widget.useSharedStorage) {
      final pid = widget.patientId;
      final bid = widget.barangayId;
      if (pid == null || pid.isEmpty || bid == null || bid.isEmpty) return null;
      return FirebaseFirestore.instance
          .collection('barangays')
          .doc(bid)
          .collection('patients')
          .doc(pid)
          .collection('vaccination')
          .doc('record');
    } else {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null || uid.isEmpty) return null;
      return FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('vaccinationStatus')
          .doc(_patientKey);
    }
  }

  @override
  void initState() {
    super.initState();
    for (final name in _vaccineNames) {
      _doses[name]           = {};
      _dateControllers[name] = {};
      final validCols = _schedule[name]?.keys ?? <String>[];
      for (final colKey in validCols) {
        _doses[name]![colKey]           = null;
        _dateControllers[name]![colKey] = TextEditingController();
        _dateControllers[name]![colKey]!.addListener(() {
          _recalcNextDose(name);
          _notifyParent();
        });
      }
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _notifyParent());
  }

  @override
  void dispose() {
    for (final name in _vaccineNames) {
      for (final c in _dateControllers[name]!.values) {
        c.dispose();
      }
    }
    super.dispose();
  }

  // ── Next-dose calculation ──────────────────────────────────────────────────
  void _recalcNextDose(String vaccine) {
    final iv = _intervals[vaccine] ?? [];
    if (iv.isEmpty) {
      setState(() => _nextDoseDates.remove(vaccine));
      return;
    }
    String? lastDate;
    for (final colKey in _cols.map((c) => c.key).toList().reversed) {
      final dose = _doses[vaccine]?[colKey];
      final date = _dateControllers[vaccine]?[colKey]?.text.trim();
      if (dose != null && date != null && date.isNotEmpty) {
        lastDate = date;
        break;
      }
    }
    if (lastDate == null) {
      setState(() => _nextDoseDates.remove(vaccine));
      return;
    }
    final doseCount = _doses[vaccine]!.values.where((d) => d != null).length;
    final ivIdx = doseCount - 1;
    if (ivIdx >= iv.length) {
      setState(() => _nextDoseDates[vaccine] = 'All doses complete ✓');
      return;
    }
    try {
      final last = DateFormat('MM-dd-yyyy').parse(lastDate);
      final next = last.add(Duration(days: iv[ivIdx]));
      setState(() =>
          _nextDoseDates[vaccine] = DateFormat('MMM dd, yyyy').format(next));
    } catch (_) {
      setState(() => _nextDoseDates.remove(vaccine));
    }
  }

  // ── Dose changed ───────────────────────────────────────────────────────────
  void _onDoseChanged(String vaccine, String colKey, String? dose) {
    setState(() {
      _doses[vaccine]![colKey] = dose;
      if (dose == null) _dateControllers[vaccine]?[colKey]?.clear();
      final hasAny = _doses[vaccine]!.values.any((d) => d != null);
      if (hasAny) {
        _expandedRows.add(vaccine);
      } else {
        _expandedRows.remove(vaccine);
      }
    });
    _recalcNextDose(vaccine);
    _notifyParent();
  }

  // ── Notify parent (legacy callback, kept for compatibility) ────────────────
  void _notifyParent() {
    if (widget.onDataChanged == null) return;
    final data = <String, dynamic>{};
    for (final name in _vaccineNames) {
      final map = <String, dynamic>{};
      for (final colKey in (_schedule[name]?.keys ?? <String>[])) {
        map[colKey] = _doses[name]?[colKey] != null;
        if (_doses[name]?[colKey] != null) {
          map['${colKey}_date'] =
              _dateControllers[name]?[colKey]?.text.trim() ?? '';
        }
      }
      if (_nextDoseDates.containsKey(name)) {
        map['nextDoseDate'] = _nextDoseDates[name];
      }
      data[name] = map;
    }
    widget.onDataChanged!(data);
  }

  // ── Save to Firestore ──────────────────────────────────────────────────────
  // Writes the same schema that VaccinationStatusSection reads:
  //   { 'hepatitisB': '2nd dose', 'bcg': '1st dose', … }
  // plus date fields and metadata.
  Future<void> _saveToFirestore() async {
    final ref = _firestoreRef;
    if (ref == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Cannot save: missing patient or user info.'),
        backgroundColor: Colors.redAccent,
      ));
      return;
    }

    setState(() => _saving = true);

    try {
      final now         = DateTime.now();
      final currentUser = FirebaseAuth.instance.currentUser;
      String userName   = 'Unknown';

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

      // Build the payload in the schema VaccinationStatusSection expects
      final payload = <String, dynamic>{
        'firstName':          widget.firstName ?? '',
        'lastName':           widget.lastName  ?? '',
        'lastReviewDate':     Timestamp.fromDate(now),
        'updatedAt':          Timestamp.fromDate(now),
        'lastModifiedBy':     currentUser?.uid ?? '',
        'lastModifiedByName': userName,
      };

      for (final name in _vaccineNames) {
        final firestoreKey = kVaccineNameToKey[name];
        if (firestoreKey == null) continue;

        // Derive the current dose label
        final doseLabel = _computeDoseLabel(name, _doses[name]!);
        payload[firestoreKey] = doseLabel;

        // Also persist per-column dates under a nested 'dates' map
        // (used for next-dose calculation when re-loading the form)
        final dateMap = <String, String>{};
        for (final colKey in (_schedule[name]?.keys ?? <String>[])) {
          final date = _dateControllers[name]?[colKey]?.text.trim();
          if (date != null && date.isNotEmpty) {
            dateMap[colKey] = date;
          }
        }
        if (dateMap.isNotEmpty) {
          payload['${firestoreKey}_dates'] = dateMap;
        }

        // Next dose date
        final nd = _nextDoseDates[name];
        if (nd != null) {
          payload['${firestoreKey}_nextDose'] = nd;
        }
      }

      await ref.set(payload, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Vaccination record saved.'),
          backgroundColor: const Color(0xFFF08030),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ));
      }
    } catch (e) {
      debugPrint('Error saving vaccination form: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to save: $e'),
          backgroundColor: Colors.redAccent,
        ));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ── Date picker ────────────────────────────────────────────────────────────
  Future<void> _pickDate(TextEditingController ctrl) async {
    FocusScope.of(context).requestFocus(FocusNode());
    DateTime init = DateTime.now();
    final txt = ctrl.text.trim();
    if (txt.isNotEmpty) {
      try { init = DateFormat('MM-dd-yyyy').parse(txt); } catch (_) {}
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: init,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFFF5A962),
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: Color(0xFF1A1A1A),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFF5A962)),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) ctrl.text = DateFormat('MM-dd-yyyy').format(picked);
  }

  bool _isOverdue(String dateStr) {
    try {
      return !DateFormat('MMM dd, yyyy').parse(dateStr).isAfter(DateTime.now());
    } catch (_) { return false; }
  }

  // ── Column width constants ─────────────────────────────────────────────────
  static const double _nameColW = 110.0;
  static const double _cellW    = 64.0;

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Section header ─────────────────────────────────────────────
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF5A962), Color(0xFFF08030)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF5A962).withValues(alpha: 0.35),
                      blurRadius: 8, offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(Icons.vaccines_outlined,
                    color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('VACCINATION',
                    style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w800,
                      color: Color(0xFFF5A962), letterSpacing: 1.1,
                    )),
              ),
              GestureDetector(
                onTap: () => _showInfoDialog(context),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5A962).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFFF5A962).withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.info_outline,
                          size: 13, color: Color(0xFFF5A962)),
                      SizedBox(width: 4),
                      Text('How to use',
                          style: TextStyle(
                            fontSize: 10, fontWeight: FontWeight.w600,
                            color: Color(0xFFF5A962),
                          )),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // ── Info banner ────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF5A962).withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFFF5A962).withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(children: [
                  Icon(Icons.lightbulb_outline,
                      size: 13, color: Color(0xFFF5A962)),
                  SizedBox(width: 5),
                  Text('HOW TO USE',
                      style: TextStyle(
                        fontSize: 10, fontWeight: FontWeight.w800,
                        color: Color(0xFFF5A962), letterSpacing: 0.6,
                      )),
                ]),
                const SizedBox(height: 6),
                _bannerStep(icon: Icons.touch_app_outlined,
                    text: 'Tap any cell to record a dose'),
                const SizedBox(height: 4),
                _bannerStep(icon: Icons.calendar_month_outlined,
                    text: 'Enter the date the dose was given'),
                const SizedBox(height: 4),
                _bannerStep(icon: Icons.auto_awesome_outlined,
                    text: 'Next dose date is auto-calculated & reminder saved'),
                const SizedBox(height: 4),
                _bannerStep(icon: Icons.swap_horiz,
                    text: 'Scroll the table left/right to see all age columns'),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () => _showInfoDialog(context),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.open_in_new,
                          size: 11, color: Color(0xFFF08030)),
                      SizedBox(width: 4),
                      Text('See full schedule & colour guide',
                          style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w600,
                            color: Color(0xFFF08030),
                            decoration: TextDecoration.underline,
                            decorationColor: Color(0xFFF08030),
                          )),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── Scrollable table ───────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _border, width: 1.5),
            ),
            clipBehavior: Clip.hardEdge,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildGroupHeaderRow(),
                  Container(height: 1, color: _border),
                  _buildColLabelRow(),
                  Container(height: 1.5, color: _border),
                  for (int vi = 0; vi < _vaccineNames.length; vi++) ...[
                    _buildVaccineRow(_vaccineNames[vi], vi),
                    if (_expandedRows.contains(_vaccineNames[vi]))
                      _buildDatePanel(_vaccineNames[vi]),
                    if (vi < _vaccineNames.length - 1)
                      Container(height: 1, color: _border),
                  ],
                ],
              ),
            ),
          ),

          // ── Upcoming / Scheduled Doses Summary ─────────────────────────
          _buildUpcomingSummary(),

          // NOTE: In this app flow the vaccination data is persisted by
          // `HomePage` when the user taps "Save Assessment".
          const SizedBox(height: 20),
          Text(
            'Vaccination record will be saved when you tap "Save Assessment".',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black.withOpacity(0.55),
            ),
          ),
        ],
      ),
    );
  }

  // ── Upcoming / Scheduled Doses Summary ────────────────────────────────────
  Widget _buildUpcomingSummary() {
    final pending  = <Map<String, dynamic>>[];
    final complete = <String>[];

    for (final name in _vaccineNames) {
      final next = _nextDoseDates[name];
      if (next == null) continue;
      if (next == 'All doses complete ✓') {
        complete.add(name);
      } else {
        pending.add({
          'vaccine': name,
          'date':    next,
          'overdue': _isOverdue(next),
        });
      }
    }

    pending.sort((a, b) {
      if (a['overdue'] && !b['overdue']) return -1;
      if (!a['overdue'] && b['overdue']) return 1;
      try {
        final da = DateFormat('MMM dd, yyyy').parse(a['date'] as String);
        final db = DateFormat('MMM dd, yyyy').parse(b['date'] as String);
        return da.compareTo(db);
      } catch (_) { return 0; }
    });

    if (pending.isEmpty && complete.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF2E8B7B).withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: const Color(0xFF2E8B7B).withValues(alpha: 0.2), width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E8B7B),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.event_note_outlined,
                      size: 14, color: Colors.white),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('NEXT SCHEDULED DOSES',
                          style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w800,
                            color: Color(0xFF2E8B7B), letterSpacing: 0.8,
                          )),
                      Text('Auto-calculated from administered dates',
                          style: TextStyle(fontSize: 10, color: Colors.black45)),
                    ],
                  ),
                ),
              ]),
              if (pending.isNotEmpty) ...[
                const SizedBox(height: 12),
                ...pending.map((item) {
                  final vaccine     = item['vaccine'] as String;
                  final date        = item['date']    as String;
                  final overdue     = item['overdue'] as bool;
                  final accentColor = overdue
                      ? const Color(0xFFEF4444)
                      : const Color(0xFFF5A962);
                  String daysLabel = '';
                  try {
                    final d    = DateFormat('MMM dd, yyyy').parse(date);
                    final diff = d.difference(DateTime.now()).inDays;
                    daysLabel  = overdue
                        ? '${diff.abs()} day(s) overdue'
                        : diff == 0 ? 'Due today' : 'In $diff day(s)';
                  } catch (_) {}

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: accentColor.withValues(alpha: 0.4), width: 1.2),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 4, offset: const Offset(0, 2)),
                      ],
                    ),
                    child: Row(children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Icon(
                            overdue
                                ? Icons.warning_amber_rounded
                                : Icons.vaccines_outlined,
                            size: 18, color: accentColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(vaccine,
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1A1A1A))),
                            const SizedBox(height: 2),
                            Row(children: [
                              Icon(Icons.calendar_today_outlined,
                                  size: 11, color: accentColor),
                              const SizedBox(width: 4),
                              Text(date,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: overdue
                                        ? const Color(0xFFEF4444)
                                        : const Color(0xFF1A1A1A),
                                  )),
                            ]),
                          ],
                        ),
                      ),
                      if (daysLabel.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: accentColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(daysLabel,
                              style: const TextStyle(
                                fontSize: 9, fontWeight: FontWeight.w700,
                                color: Colors.white,
                              )),
                        ),
                    ]),
                  );
                }),
              ],
              if (complete.isNotEmpty) ...[
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E8B7B).withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: const Color(0xFF2E8B7B).withValues(alpha: 0.25),
                        width: 1),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle_outline,
                          size: 16, color: Color(0xFF2E8B7B)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('All doses complete',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF2E8B7B))),
                            const SizedBox(height: 3),
                            Wrap(
                              spacing: 6, runSpacing: 4,
                              children: complete.map((v) => Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2E8B7B)
                                          .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(v,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF2E8B7B),
                                        )),
                                  )).toList(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ── Group header row ───────────────────────────────────────────────────────
  Widget _buildGroupHeaderRow() {
    return Row(
      children: [
        Container(
          width: _nameColW,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          color: const Color(0xFF2E8B7B),
          child: const Text('VACCINES',
              style: TextStyle(
                fontSize: 9, fontWeight: FontWeight.w800,
                color: Colors.white, letterSpacing: 0.5,
              )),
        ),
        for (final group in _ageGroups)
          Container(
            width: group.colCount * _cellW,
            padding: const EdgeInsets.symmetric(vertical: 8),
            color: group.color,
            child: Center(
              child: Text(group.label,
                  style: const TextStyle(
                    fontSize: 9, fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A1A), letterSpacing: 0.3,
                  )),
            ),
          ),
      ],
    );
  }

  // ── Column label row ───────────────────────────────────────────────────────
  Widget _buildColLabelRow() {
    return Row(
      children: [
        SizedBox(width: _nameColW),
        for (int ci = 0; ci < _cols.length; ci++)
          SizedBox(
            width: _cellW,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 7),
              color: _groupColorFor(ci).withValues(alpha: 0.35),
              child: Center(
                child: Text(_cols[ci].label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 8, fontWeight: FontWeight.w700,
                      color: Color(0xFF333333),
                    )),
              ),
            ),
          ),
      ],
    );
  }

  Color _groupColorFor(int colIndex) {
    if (colIndex < 10) return const Color(0xFFADD8E6);
    return const Color(0xFFFFB6C1);
  }

  // ── Vaccine row ────────────────────────────────────────────────────────────
  Widget _buildVaccineRow(String name, int rowIdx) {
    final hasAny     = _doses[name]!.values.any((d) => d != null);
    final isExpanded = _expandedRows.contains(name);
    final nextDate   = _nextDoseDates[name];
    final isComplete = nextDate == 'All doses complete ✓';
    final isDue      = nextDate != null && !isComplete && _isOverdue(nextDate);

    return GestureDetector(
      onTap: hasAny
          ? () => setState(() => isExpanded
              ? _expandedRows.remove(name)
              : _expandedRows.add(name))
          : null,
      child: Container(
        color: rowIdx.isEven ? _surface : _surfaceAlt,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(
                  minWidth: _nameColW, maxWidth: _nameColW, minHeight: 42),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(name,
                              style: const TextStyle(
                                fontSize: 9, fontWeight: FontWeight.w700,
                                color: _textColor,
                              ),
                              softWrap: true,
                              maxLines: 3),
                          if (nextDate != null && !isExpanded) ...[
                            const SizedBox(height: 3),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: isComplete
                                    ? const Color(0xFF2E8B7B).withValues(alpha: 0.1)
                                    : isDue
                                        ? const Color(0xFFEF4444).withValues(alpha: 0.1)
                                        : _primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(children: [
                                Icon(
                                  isComplete
                                      ? Icons.check_circle_outline
                                      : isDue
                                          ? Icons.warning_amber_rounded
                                          : Icons.event_outlined,
                                  size: 9,
                                  color: isComplete
                                      ? const Color(0xFF2E8B7B)
                                      : isDue
                                          ? const Color(0xFFEF4444)
                                          : _primary,
                                ),
                                const SizedBox(width: 3),
                                Flexible(
                                  child: Text(
                                    isComplete ? 'Done ✓' : nextDate,
                                    style: TextStyle(
                                      fontSize: 8,
                                      fontWeight: FontWeight.w700,
                                      color: isComplete
                                          ? const Color(0xFF2E8B7B)
                                          : isDue
                                              ? const Color(0xFFEF4444)
                                              : _primary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ]),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (hasAny)
                      Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        size: 12, color: _primary,
                      ),
                  ],
                ),
              ),
            ),
            for (int ci = 0; ci < _cols.length; ci++)
              _buildCell(name, _cols[ci].key, ci, rowIdx),
          ],
        ),
      ),
    );
  }

  // ── Individual dose cell ───────────────────────────────────────────────────
  Widget _buildCell(
      String vaccine, String colKey, int colIndex, int rowIdx) {
    final possibleDoses = _schedule[vaccine]?[colKey] ?? <String>[];
    final selectedDose  = _doses[vaccine]?[colKey];
    final groupColor    = _groupColorFor(colIndex);
    const double outerH = 42.0;

    if (possibleDoses.isEmpty) {
      return SizedBox(
        width: _cellW,
        height: outerH,
        child: Container(
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: groupColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(5),
          ),
        ),
      );
    }

    final isDone = selectedDose != null;

    return GestureDetector(
      onTap: () => _showCellMenu(vaccine, colKey, possibleDoses, selectedDose),
      child: SizedBox(
        width: _cellW,
        height: outerH,
        child: Container(
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: isDone
                ? _primary.withValues(alpha: 0.15)
                : groupColor.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(5),
            border: Border.all(
              color: isDone ? _primary : groupColor.withValues(alpha: 0.5),
              width: isDone ? 1.5 : 1,
            ),
          ),
          child: Center(
            child: isDone
                ? Text(selectedDose,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 7, fontWeight: FontWeight.w700,
                      color: Color(0xFFF08030),
                    ))
                : Icon(Icons.add, size: 12,
                    color: groupColor.withValues(alpha: 0.8)),
          ),
        ),
      ),
    );
  }

  // ── Cell tap → bottom sheet dose picker ───────────────────────────────────
  void _showCellMenu(String vaccine, String colKey,
      List<String> possibleDoses, String? selectedDose) {
    FocusScope.of(context).requestFocus(FocusNode());
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.vaccines_outlined,
                    size: 14, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(vaccine,
                        style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w800,
                          color: Color(0xFF1A1A1A),
                        )),
                    Text(
                      _cols.firstWhere((c) => c.key == colKey).label,
                      style: const TextStyle(
                          fontSize: 11, color: Colors.black45),
                    ),
                  ],
                ),
              ),
            ]),
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 12),
            if (selectedDose != null) ...[
              _sheetOption(
                ctx: ctx, label: 'Clear selection',
                icon: Icons.clear, color: const Color(0xFFEF4444),
                onTap: () {
                  Navigator.pop(ctx);
                  _onDoseChanged(vaccine, colKey, null);
                },
              ),
              const SizedBox(height: 6),
            ],
            ...possibleDoses.map((dose) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _sheetOption(
                    ctx: ctx, label: dose,
                    icon: selectedDose == dose
                        ? Icons.check_circle
                        : Icons.circle_outlined,
                    color: _primary,
                    isSelected: selectedDose == dose,
                    onTap: () {
                      Navigator.pop(ctx);
                      _onDoseChanged(vaccine, colKey, dose);
                    },
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _sheetOption({
    required BuildContext ctx,
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isSelected = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? _primary.withValues(alpha: 0.08)
              : const Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? _primary : const Color(0xFFEEEEEE),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: color,
                )),
          ),
          if (isSelected)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: _primary,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text('Given',
                  style: TextStyle(
                    fontSize: 9, fontWeight: FontWeight.w700,
                    color: Colors.white,
                  )),
            ),
        ]),
      ),
    );
  }

  // ── Date + next-dose expanded panel ───────────────────────────────────────
  Widget _buildDatePanel(String vaccine) {
    final activeCols = _cols
        .where((c) =>
            _doses[vaccine]?[c.key] != null &&
            _schedule[vaccine]?.containsKey(c.key) == true)
        .toList();
    if (activeCols.isEmpty) return const SizedBox.shrink();

    final iv         = _intervals[vaccine] ?? [];
    final nextDate   = _nextDoseDates[vaccine];
    final isComplete = nextDate == 'All doses complete ✓';

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      color: const Color(0xFFFFF8F3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.calendar_today_outlined,
                size: 12, color: Color(0xFFF5A962)),
            const SizedBox(width: 5),
            Text(
              '$vaccine — DATE OF ADMINISTRATION',
              style: const TextStyle(
                fontSize: 10, fontWeight: FontWeight.w700,
                color: Color(0xFFF5A962), letterSpacing: 0.6,
              ),
            ),
          ]),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10, runSpacing: 12,
            children: activeCols.asMap().entries.map((entry) {
              final doseIdx    = entry.key;
              final col        = entry.value;
              final dose       = _doses[vaccine]![col.key]!;
              final ctrl       = _dateControllers[vaccine]![col.key]!;
              final dateEntered = ctrl.text.trim();

              String? thisNextDate;
              bool    thisIsDue    = false;
              bool    thisComplete = false;

              if (iv.isEmpty) {
                thisComplete = true;
              } else if (doseIdx >= iv.length) {
                thisComplete = true;
              } else if (dateEntered.isNotEmpty) {
                try {
                  final last = DateFormat('MM-dd-yyyy').parse(dateEntered);
                  final next = last.add(Duration(days: iv[doseIdx]));
                  thisNextDate = DateFormat('MMM dd, yyyy').format(next);
                  thisIsDue    = _isOverdue(thisNextDate);
                } catch (_) {}
              }

              final nextColor = thisComplete
                  ? const Color(0xFF2E8B7B)
                  : thisIsDue
                      ? const Color(0xFFEF4444)
                      : _primary;

              return SizedBox(
                width: 160,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _primary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${col.label}  ·  $dose',
                        style: const TextStyle(
                          fontSize: 9, fontWeight: FontWeight.w700,
                          color: Colors.white, letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    GestureDetector(
                      onTap: () async {
                        await _pickDate(ctrl);
                        setState(() {});
                      },
                      child: AbsorbPointer(
                        child: TextFormField(
                          controller: ctrl,
                          readOnly: true,
                          style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w500,
                            color: Color(0xFF1A1A1A),
                          ),
                          decoration: InputDecoration(
                            hintText: 'Tap to set date',
                            hintStyle: const TextStyle(
                                fontSize: 11, color: Colors.black26),
                            prefixIcon: const Icon(
                                Icons.calendar_month_outlined,
                                size: 14, color: Color(0xFFF5A962)),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 9),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                  color: Color(0xFFEEEEEE), width: 1.5),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                  color: Color(0xFFF5A962), width: 2),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        color: nextColor.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: nextColor.withValues(alpha: 0.3), width: 1,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            thisComplete
                                ? Icons.check_circle_outline
                                : thisIsDue
                                    ? Icons.warning_amber_rounded
                                    : Icons.event_outlined,
                            size: 12, color: nextColor,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  thisComplete ? 'Last dose' : 'Next dose',
                                  style: TextStyle(
                                    fontSize: 9, fontWeight: FontWeight.w700,
                                    color: nextColor, letterSpacing: 0.3,
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  thisComplete
                                      ? 'Series complete ✓'
                                      : dateEntered.isEmpty
                                          ? 'Enter date above to calculate'
                                          : thisNextDate ?? '—',
                                  style: TextStyle(
                                    fontSize: 11, fontWeight: FontWeight.w700,
                                    color: thisComplete
                                        ? const Color(0xFF2E8B7B)
                                        : dateEntered.isEmpty
                                            ? Colors.black38
                                            : thisIsDue
                                                ? const Color(0xFFEF4444)
                                                : const Color(0xFF1A1A1A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          if (isComplete) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF2E8B7B).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: const Color(0xFF2E8B7B).withValues(alpha: 0.3),
                    width: 1.2),
              ),
              child: const Row(children: [
                Icon(Icons.check_circle_outline,
                    size: 16, color: Color(0xFF2E8B7B)),
                SizedBox(width: 8),
                Text('All doses complete',
                    style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700,
                      color: Color(0xFF2E8B7B),
                    )),
              ]),
            ),
          ],
        ],
      ),
    );
  }

  // ── Helper widgets ─────────────────────────────────────────────────────────
  Widget _bannerStep({required IconData icon, required String text}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 12, color: const Color(0xFFF08030)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text,
              style: const TextStyle(
                fontSize: 11, color: Color(0xFF555555), height: 1.3,
              )),
        ),
      ],
    );
  }

  // ── Info dialog ────────────────────────────────────────────────────────────
  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF5A962), Color(0xFFF08030)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.vaccines_outlined,
                      color: Colors.white, size: 16),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text('How Vaccination Works',
                      style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w800,
                        color: Color(0xFF1A1A1A),
                      )),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(ctx),
                  child: const Icon(Icons.close, size: 18, color: Colors.black38),
                ),
              ]),
              const SizedBox(height: 16),
              _infoStep('1', Icons.touch_app_outlined, 'Tap a cell in the table',
                  'Tap any coloured cell to record the dose given. '
                  'Grey cells are not applicable for that vaccine at that age.'),
              const SizedBox(height: 10),
              _infoStep('2', Icons.calendar_month_outlined, 'Enter the date given',
                  'After recording a dose, tap the vaccine name row to expand '
                  'and enter the date the dose was administered.'),
              const SizedBox(height: 10),
              _infoStep('3', Icons.auto_awesome_outlined, 'Next dose is auto-calculated',
                  'Once a date is entered, the next dose date is automatically '
                  'computed using the standard PH EPI schedule.'),
              const SizedBox(height: 10),
              _infoStep(
                '4',
                Icons.save_rounded,
                'Tap Save to update the status card',
                'Press "Save Assessment" at the bottom. The Vaccination '
                'Status card will reflect the new dose labels.',
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              const Text('VACCINE SCHEDULE REFERENCE',
                  style: TextStyle(
                    fontSize: 10, fontWeight: FontWeight.w800,
                    color: Color(0xFFF5A962), letterSpacing: 0.8,
                  )),
              const SizedBox(height: 10),
              ..._scheduleRows(),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF5A962),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Got it',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoStep(String num, IconData icon, String title, String body) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24, height: 24,
          decoration: const BoxDecoration(
            color: Color(0xFFF5A962), shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(num,
                style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white,
                )),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(icon, size: 13, color: const Color(0xFFF5A962)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(title,
                      style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A1A),
                      )),
                ),
              ]),
              const SizedBox(height: 3),
              Text(body,
                  style: const TextStyle(
                    fontSize: 12, color: Color(0xFF666666), height: 1.4,
                  )),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _scheduleRows() {
    const rows = [
      ['BCG',            '1 dose',      'Birth'],
      ['Hepatitis B',    '3 doses',     'Birth, 1 mo, 6 mos'],
      ['Pentavalent',    '3 doses',     '6, 10, 14 wks'],
      ['Oral Polio',     '3+Booster',   '6, 10, 14 wks + Booster'],
      ['IPV',            '3 doses',     '6, 10, 14 wks'],
      ['Phenumococcal',  '3+Booster',   '6, 10, 14 wks + Booster'],
      ['Rotavirus',      '3 doses',     '6, 10, 14 wks'],
      ['Measles',        '1 dose',      '9 mo'],
      ['MMR',            '2 doses',     '12 mo, 15 mo'],
      ['Hepatitis A',    '2 doses',     '12 mo, 18 mo'],
      ['Chickenpox',     '2 doses',     '12 mo, 15 mo'],
      ['Typhoid',        'Note',        'See annotations'],
      ['Pneumo 23',      'Note',        'See annotations'],
      ['FLU',            '2 doses',     'Yearly'],
      ['OPV',            '3+Booster',   '6, 10, 14 wks + Booster'],
      ['DTwP/DTaP-Hib',  '3+Booster',  '6, 10, 14 wks + 15 mo Booster'],
      ['PCV',            '3+Booster',   '6, 10, 14 wks + Booster'],
      ['Influenza',      '2 doses',     'Yearly'],
      ['MMR/MR',         '2 doses',     '9 mo, 12 mo'],
      ['Measles/MMR',    '3 doses',     '6 mo, 9 mo, 15 mo'],
      ['JEV',            '2 doses',     '9 mo, 19-23 mos'],
      ['Varicella',      '2 doses',     '12 mo, 15 mo'],
      ['Rabies',         'Series',      'See schedule'],
      ['Meningococcal',  'Note',        'See annotations'],
      ['Cholera',        'Note',        'See annotations'],
    ];

    return rows.map((r) => Container(
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xFFFAFAFA),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFEEEEEE), width: 1),
          ),
          child: Row(children: [
            SizedBox(
              width: 90,
              child: Text(r[0],
                  style: const TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                  )),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFF5A962).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(r[1],
                  style: const TextStyle(
                    fontSize: 9, fontWeight: FontWeight.w700,
                    color: Color(0xFFF08030),
                  )),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(r[2],
                  style: const TextStyle(
                    fontSize: 10, color: Color(0xFF666666),
                  )),
            ),
          ]),
        )).toList();
  }
}