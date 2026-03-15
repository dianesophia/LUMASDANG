import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'vaccine_dose_selector.dart';

// ── Column definition ─────────────────────────────────────────────────────────
class _AgeCol {
  final String key;   // unique key used in data map
  final String label; // display label
  const _AgeCol(this.key, this.label);
}

// ── Age-group section for the spanning header ─────────────────────────────────
class _AgeGroup {
  final String label;
  final Color  color;
  final int    colCount;
  const _AgeGroup(this.label, this.color, this.colCount);
}

class VaccinationForm extends StatefulWidget {
  final Function(Map<String, dynamic>)? onDataChanged;
  const VaccinationForm({super.key, this.onDataChanged});

  @override
  State<VaccinationForm> createState() => _VaccinationFormState();
}

class _VaccinationFormState extends State<VaccinationForm> {
  // ── Theme ─────────────────────────────────────────────────────────────────
  static const Color _primary    = Color(0xFFF5A962);
  static const Color _surface    = Colors.white;
  static const Color _surfaceAlt = Color(0xFFFAFAFA);
  static const Color _border     = Color(0xFFEEEEEE);
  static const Color _textColor  = Color(0xFF1A1A1A);

  // ── Age columns (matches the image columns) ───────────────────────────────
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

  // ── Age-group spanning headers ────────────────────────────────────────────
  static const _ageGroups = <_AgeGroup>[
    _AgeGroup('INFANCY',         Color(0xFFADD8E6), 10), // cols 0-9
    _AgeGroup('EARLY CHILDHOOD', Color(0xFFFFB6C1),  4), // cols 10-13
  ];

  // ── All vaccines ──────────────────────────────────────────────────────────
  static const _vaccineNames = [
    'BCG',
    'Hepatitis B',
    'OPV',
    'IPV',
    'DTwP/DTaP-Hib-IPV',
    'PCV',
    'RV',
    'Influenza',
    'MMR/MR',
    'Measles/MMR',
    'JEV',
    'Varicella',
    'Hepatitis A',
    'Rabies',
    'Meningococcal',
    'Cholera',
    'Typhoid',
  ];

  // ── Next-dose intervals (days between consecutive doses) ─────────────────
  static const Map<String, List<int>> _intervals = {
    'BCG':               [],            // single dose
    'Hepatitis B':       [28, 56],      // birth → 1mo → 6mo
    'OPV':               [28, 56, 91],  // 6wks → 10wks → 14wks → 9mo
    'IPV':               [28, 56],      // 6wks → 10wks → 14wks
    'DTwP/DTaP-Hib-IPV': [28, 56, 365],// 6wks → 10wks → 14wks → booster
    'PCV':               [28, 56, 91],
    'RV':                [28, 56],
    'Influenza':         [28],          // 2 doses then yearly
    'MMR/MR':            [168],         // 9mo → 15-18mo
    'Measles/MMR':       [168],
    'JEV':               [168],
    'Varicella':         [84],
    'Hepatitis A':       [180],
    'Rabies':            [7, 21],
    'Meningococcal':     [],
    'Cholera':           [],
    'Typhoid':           [],
  };

  // ── Which columns are valid for each vaccine ──────────────────────────────
  // Map<vaccineName, Map<colKey, possibleDoses>>
  static const Map<String, Map<String, List<String>>> _schedule = {
    'BCG': {
      'BIRTH': ['1st dose'],
    },
    'Hepatitis B': {
      'BIRTH': ['1st dose'],
      '1MO':   ['2nd dose'],
      '6MO':   ['3rd dose'],
    },
    'OPV': {
      '6WKS':  ['1st dose'],
      '10WKS': ['2nd dose'],
      '14WKS': ['3rd dose'],
      '9MO':   ['Booster'],
    },
    'IPV': {
      '6WKS':  ['1st dose'],
      '10WKS': ['2nd dose'],
      '14WKS': ['3rd dose'],
    },
    'DTwP/DTaP-Hib-IPV': {
      '6WKS':  ['1st dose'],
      '10WKS': ['2nd dose'],
      '14WKS': ['3rd dose'],
      '15MO':  ['1st booster'],
    },
    'PCV': {
      '6WKS':  ['1st dose'],
      '10WKS': ['2nd dose'],
      '14WKS': ['3rd dose'],
      '9MO':   ['Booster'],
    },
    'RV': {
      '6WKS':  ['1st dose'],
      '10WKS': ['2nd dose'],
      '14WKS': ['3rd dose'],
    },
    'Influenza': {
      '6MO':    ['1st dose'],
    },
    'MMR/MR': {
      '9MO':    ['1st dose MMR'],
      '12MO':   ['2nd dose MMR'],
    },
    'Measles/MMR': {
      '6MO':    ['Measles'],
      '9MO':    ['1st dose MMR'],
      '15MO':   ['2nd dose MMR'],
    },
    'JEV': {
      '9MO':    ['1st dose'],
      '19-23MO':['2nd dose'],
    },
    'Varicella': {
      '12MO':   ['1st dose'],
      '15MO':   ['2nd dose'],
    },
    'Hepatitis A': {
      '12MO':   ['1st dose'],
      '18MO':   ['2nd dose'],
    },
    'Rabies': {
      '2-5YR':  ['Rabies series'],
    },
    'Meningococcal': {
      '9MO':    ['See annotations'],
      '12MO':   ['See annotations'],
      '2-5YR':  ['See annotations'],
    },
    'Cholera': {
      '2-5YR':  ['See annotations'],
    },
    'Typhoid': {
      '2-5YR':  ['See annotations'],
    },
  };

  // ── State ─────────────────────────────────────────────────────────────────
  // doses[vaccine][colKey] = dose label | null
  final Map<String, Map<String, String?>>            _doses           = {};
  // dateControllers[vaccine][colKey] = TextEditingController
  final Map<String, Map<String, TextEditingController>> _dateControllers = {};
  // computed next-dose per vaccine
  final Map<String, String>                          _nextDoseDates   = {};
  final Set<String>                                  _expandedRows    = {};

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

  // ── Next-dose calculation ─────────────────────────────────────────────────
  void _recalcNextDose(String vaccine) {
    final iv = _intervals[vaccine] ?? [];
    if (iv.isEmpty) {
      setState(() => _nextDoseDates.remove(vaccine));
      return;
    }

    // Find most recently administered dose that has a date
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

  // ── Dose changed ──────────────────────────────────────────────────────────
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

  // ── Notify parent ─────────────────────────────────────────────────────────
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

  // ── Date picker ───────────────────────────────────────────────────────────
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

  // ── Column width constants ────────────────────────────────────────────────
  static const double _nameColW = 110.0;
  static const double _cellW    = 64.0;

  // ── Build ─────────────────────────────────────────────────────────────────
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
          // ── Section header with info button ───────────────────────────
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

          // ── Info banner ───────────────────────────────────────────────
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

          // ── Scrollable table ──────────────────────────────────────────
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
                  // Age-group spanning header row
                  _buildGroupHeaderRow(),
                  Container(height: 1, color: _border),
                  // Age column labels row
                  _buildColLabelRow(),
                  Container(height: 1.5, color: _border),
                  // Vaccine rows
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

          // ── Upcoming / Scheduled Doses Summary ────────────────────────
          _buildUpcomingSummary(),
        ],
      ),
    );
  }

  // ── Upcoming / Scheduled Doses Summary panel ─────────────────────────────
  Widget _buildUpcomingSummary() {
    // Collect all vaccines that have a computed next dose date
    final pending = <Map<String, dynamic>>[];
    final complete = <String>[];

    for (final name in _vaccineNames) {
      final next = _nextDoseDates[name];
      if (next == null) continue;
      if (next == 'All doses complete ✓') {
        complete.add(name);
      } else {
        final overdue = _isOverdue(next);
        pending.add({
          'vaccine':  name,
          'date':     next,
          'overdue':  overdue,
        });
      }
    }

    // Sort: overdue first, then by date
    pending.sort((a, b) {
      if (a['overdue'] && !b['overdue']) return -1;
      if (!a['overdue'] && b['overdue']) return 1;
      try {
        final da = DateFormat('MMM dd, yyyy').parse(a['date'] as String);
        final db = DateFormat('MMM dd, yyyy').parse(b['date'] as String);
        return da.compareTo(db);
      } catch (_) { return 0; }
    });

    // Nothing to show
    if (pending.isEmpty && complete.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 14),

        // ── Section header ──────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF2E8B7B).withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: const Color(0xFF2E8B7B).withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
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
                      Text(
                        'Auto-calculated from administered dates',
                        style: TextStyle(
                          fontSize: 10, color: Colors.black45,
                        ),
                      ),
                    ],
                  ),
                ),
              ]),

              // Pending dose rows
              if (pending.isNotEmpty) ...[
                const SizedBox(height: 12),
                ...pending.map((item) {
                  final vaccine = item['vaccine'] as String;
                  final date    = item['date']    as String;
                  final overdue = item['overdue'] as bool;
                  final accentColor = overdue
                      ? const Color(0xFFEF4444)
                      : const Color(0xFFF5A962);

                  // Calculate how many days away
                  String daysLabel = '';
                  try {
                    final d = DateFormat('MMM dd, yyyy').parse(date);
                    final diff = d.difference(DateTime.now()).inDays;
                    if (overdue) {
                      daysLabel = '${diff.abs()} day(s) overdue';
                    } else if (diff == 0) {
                      daysLabel = 'Due today';
                    } else {
                      daysLabel = 'In $diff day(s)';
                    }
                  } catch (_) {}

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: accentColor.withValues(alpha: 0.4),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(children: [
                      // Status dot
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
                      // Vaccine + date
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(vaccine,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1A1A1A),
                                )),
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
                      // Days badge
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
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              )),
                        ),
                    ]),
                  );
                }),
              ],

              // Complete vaccines row
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
                      width: 1,
                    ),
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
                                  fontSize: 11, fontWeight: FontWeight.w700,
                                  color: Color(0xFF2E8B7B),
                                )),
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

  // ── Group header row (INFANCY / EARLY CHILDHOOD) ─────────────────────────
  Widget _buildGroupHeaderRow() {
    return Row(
      children: [
        // Vaccine name column header
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

  // ── Column label row ──────────────────────────────────────────────────────
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

  // ── Vaccine row ───────────────────────────────────────────────────────────
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
            // Vaccine name cell — min height matches data cell outerH (42)
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
                          // Next-dose compact hint (when collapsed)
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
            // Dose cells
            for (int ci = 0; ci < _cols.length; ci++) ...[
              _buildCell(name, _cols[ci].key, ci, rowIdx),
            ],
          ],
        ),
      ),
    );
  }

  // ── Individual dose cell ──────────────────────────────────────────────────
  Widget _buildCell(
      String vaccine, String colKey, int colIndex, int rowIdx) {
    final possibleDoses =
        _schedule[vaccine]?[colKey] ?? <String>[];
    final selectedDose  = _doses[vaccine]?[colKey];
    final groupColor    = _groupColorFor(colIndex);

    // Every cell occupies exactly the same fixed space
    // so rows always align perfectly regardless of content.
    const double outerH = 42.0; // row height for all cells

    // Empty cell — vaccine not applicable for this age/column
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
            // Handle
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
            // Title
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
            // Dose options
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
            color: isSelected
                ? _primary
                : const Color(0xFFEEEEEE),
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
                  fontWeight: isSelected
                      ? FontWeight.w700
                      : FontWeight.w500,
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

    final iv          = _intervals[vaccine] ?? [];
    final nextDate    = _nextDoseDates[vaccine];
    final isComplete  = nextDate == 'All doses complete ✓';

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      color: const Color(0xFFFFF8F3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section label
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

          // One card per administered dose
          Wrap(
            spacing: 10, runSpacing: 12,
            children: activeCols.asMap().entries.map((entry) {
              final doseIdx = entry.key; // 0-based index among active cols
              final col     = entry.value;
              final dose    = _doses[vaccine]![col.key]!;
              final ctrl    = _dateControllers[vaccine]![col.key]!;
              final dateEntered = ctrl.text.trim();

              // ── Calculate next dose for THIS specific dose ──────────
              // ivIdx = doseIdx (after the 1st recorded dose use interval[0], etc.)
              String? thisNextDate;
              bool    thisIsDue    = false;
              bool    thisComplete = false;

              if (iv.isEmpty) {
                // Single-dose vaccine — no next dose
                thisComplete = true;
              } else if (doseIdx >= iv.length) {
                // This is the last dose
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
                    // ── Dose badge ────────────────────────────────────
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

                    // ── Date administered picker ───────────────────────
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

                    // ── Next dose — shown directly below the date ─────
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        color: nextColor.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: nextColor.withValues(alpha: 0.3),
                          width: 1,
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
                                  thisComplete
                                      ? 'Last dose'
                                      : 'Next dose',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: nextColor,
                                    letterSpacing: 0.3,
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
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
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

          // ── Overall complete banner (only shown when all doses done) ─
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
                  width: 1.2,
                ),
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

  // ── Helper widgets ────────────────────────────────────────────────────────
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

  // ── Info dialog ───────────────────────────────────────────────────────────
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
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
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
                  child: const Icon(Icons.close,
                      size: 18, color: Colors.black38),
                ),
              ]),
              const SizedBox(height: 16),
              _infoStep('1', Icons.touch_app_outlined,
                  'Tap a cell in the table',
                  'Tap any coloured cell to record the dose given. '
                  'Grey cells are not applicable for that vaccine at that age.'),
              const SizedBox(height: 10),
              _infoStep('2', Icons.calendar_month_outlined,
                  'Enter the date given',
                  'After recording a dose, tap the vaccine name row to expand '
                  'and enter the date the dose was administered.'),
              const SizedBox(height: 10),
              _infoStep('3', Icons.auto_awesome_outlined,
                  'Next dose is auto-calculated',
                  'Once a date is entered, the next dose date is automatically '
                  'computed using the standard PH EPI schedule. A reminder '
                  'notification is sent to your barangay team on the due date.'),
              const SizedBox(height: 10),
              _infoStep('4', Icons.swap_horiz,
                  'Scroll the table sideways',
                  'The table spans from Birth to 13-18 years. '
                  'Scroll left/right to see all age columns.'),
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
              const Divider(),
              const SizedBox(height: 10),
              const Text('COLUMN COLOURS',
                  style: TextStyle(
                    fontSize: 10, fontWeight: FontWeight.w800,
                    color: Color(0xFFF5A962), letterSpacing: 0.8,
                  )),
              const SizedBox(height: 8),
              _colorLegendRow(const Color(0xFFADD8E6),
                  'Infancy', 'Birth to 12 months'),
              const SizedBox(height: 6),
              _colorLegendRow(const Color(0xFFFFB6C1),
                  'Early Childhood', '15 months to 2-5 years'),
              const SizedBox(height: 16),
              const Text('DOSE STATUS COLOURS',
                  style: TextStyle(
                    fontSize: 10, fontWeight: FontWeight.w800,
                    color: Color(0xFFF5A962), letterSpacing: 0.8,
                  )),
              const SizedBox(height: 8),
              _colorLegendRow(const Color(0xFFF5A962),
                  'Upcoming', 'Next dose scheduled in the future'),
              const SizedBox(height: 6),
              _colorLegendRow(const Color(0xFFEF4444),
                  'Overdue', 'Next dose date has already passed'),
              const SizedBox(height: 6),
              _colorLegendRow(const Color(0xFF2E8B7B),
                  'Complete', 'All doses done'),
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
                  fontSize: 12, fontWeight: FontWeight.w800,
                  color: Colors.white,
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
      ['BCG',               '1 dose',  'Birth'],
      ['Hepatitis B',       '3 doses', 'Birth, 1 mo, 6 mos'],
      ['OPV',               '3+1',     '6, 10, 14 wks + 9 mo booster'],
      ['IPV',               '3 doses', '6, 10, 14 wks'],
      ['DTwP/DTaP-Hib-IPV', '3+1',     '6, 10, 14 wks + 15 mo booster'],
      ['PCV',               '3+1',     '6, 10, 14 wks + 9 mo'],
      ['RV',                '3 doses', '6, 10, 14 wks'],
      ['Influenza',         '1 dose',  '6 mos'],
      ['MMR/MR',            '2 doses', '9 mo, 12 mo'],
      ['Measles/MMR',       '3 doses', '6 mo, 9 mo, 15 mo'],
      ['JEV',               '2 doses', '9 mo, 19-23 mos'],
      ['Varicella',         '2 doses', '12 mo, 15 mo'],
      ['Hepatitis A',       '2 doses', '12 mo, 18 mo'],
      ['Rabies',            'Series',  '2-5 yrs'],
      ['Meningococcal',     'Note',    'See annotations'],
      ['Cholera',           'Note',    'See annotations'],
      ['Typhoid',           'Note',    'See annotations'],
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
              padding: const EdgeInsets.symmetric(
                  horizontal: 7, vertical: 2),
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

  Widget _colorLegendRow(Color color, String label, String desc) {
    return Row(children: [
      Container(
        width: 12, height: 12,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 8),
      Text('$label — ',
          style: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w700, color: color,
          )),
      Expanded(
        child: Text(desc,
            style: const TextStyle(
                fontSize: 12, color: Color(0xFF666666))),
      ),
    ]);
  }
}