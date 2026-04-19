import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// EXAMPLE PARENT — shows how to wire up the callbacks so delete/edit work
// ─────────────────────────────────────────────────────────────────────────────

class AssessmentPage extends StatefulWidget {
  const AssessmentPage({super.key});

  @override
  State<AssessmentPage> createState() => _AssessmentPageState();
}

class _AssessmentPageState extends State<AssessmentPage> {
  final String _patientId = 'patient_001';
  bool _loading = false;

  // Your assessments list — this is the source of truth
  List<Map<String, dynamic>> _assessments = [
    {
      'id': '1',
      'date': DateTime(2024, 1, 15),
      'height': '110',
      'weight': '18',
      'muac': '14',
      'weightForAge': '-1.2 SD',
      'heightForAge': '-0.8 SD',
      'weightForHeight': '0.5 SD',
      'bmi': '15.5 | -0.3 SD',
    },
    {
      'id': '2',
      'date': DateTime(2024, 3, 10),
      'height': '112',
      'weight': '17',
      'muac': '13',
      'weightForAge': '-2.5 SD',
      'heightForAge': '-1.0 SD',
      'weightForHeight': '-0.8 SD',
      'bmi': '13.5 | -1.5 SD',
    },
  ];

  // ── Delete: remove from list after successful API call ──
  Future<void> _handleDeleteAssessment(
      String assessmentId, String patientId) async {
    // TODO: replace with your actual API/Firebase delete call
    // e.g. await FirebaseFirestore.instance
    //   .collection('patients').doc(patientId)
    //   .collection('assessments').doc(assessmentId).delete();

    await Future.delayed(const Duration(milliseconds: 300)); // simulate network

    setState(() {
      _assessments.removeWhere((a) => a['id']?.toString() == assessmentId);
    });
  }

  // ── Edit: replace old entry in-place, no duplicates ──
  Future<void> _handleEditAssessment(
      Map<String, dynamic> updated,
      String assessmentId,
      String patientId) async {
    // TODO: replace with your actual API/Firebase update call
    // e.g. await FirebaseFirestore.instance
    //   .collection('patients').doc(patientId)
    //   .collection('assessments').doc(assessmentId).update(updated);

    await Future.delayed(const Duration(milliseconds: 300)); // simulate network

    setState(() {
      final index = _assessments
          .indexWhere((a) => a['id']?.toString() == assessmentId);
      if (index != -1) {
        _assessments[index] = updated; // replace in-place — no duplicate
      }
    });
  }

  // ── Add: push a new entry ──
  void _handleAddAssessment() {
    // TODO: open your add assessment sheet/dialog here
    // After saving, do:
    // setState(() => _assessments.add(newAssessment));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Patient Assessments')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: AssessmentTable(
          patientId: _patientId,
          assessments: _assessments,
          loading: _loading,
          onAddAssessment: _handleAddAssessment,
          onDeleteAssessment: _handleDeleteAssessment,
          onEditAssessment: _handleEditAssessment,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ASSESSMENT TABLE WIDGET
// ─────────────────────────────────────────────────────────────────────────────

class AssessmentTable extends StatefulWidget {
  final List<Map<String, dynamic>> assessments;
  final String patientId;
  final bool loading;
  final VoidCallback onAddAssessment;
  final Future<void> Function(Map<String, dynamic>, String patientId)?
      saveNewAssessment;
  final Future<void> Function(String assessmentId, String patientId)?
      onDeleteAssessment;
  final Future<void> Function(
          Map<String, dynamic> updated, String assessmentId, String patientId)?
      onEditAssessment;

  const AssessmentTable({
    super.key,
    required this.patientId,
    required this.assessments,
    required this.loading,
    required this.onAddAssessment,
    this.saveNewAssessment,
    this.onDeleteAssessment,
    this.onEditAssessment,
  });

  @override
  State<AssessmentTable> createState() => _AssessmentTableState();
}

class _AssessmentTableState extends State<AssessmentTable> {
  static const Color _orange      = Color(0xFFF08030);
  static const Color _orangeLight = Color(0xFFF5A962);
  static const Color _surface     = Color(0xFFFFFFFF);
  static const Color _surfaceDim  = Color(0xFFFAFAFA);
  static const Color _border      = Color(0xFFE8E8ED);
  static const Color _ink         = Color(0xFF1C1C1E);
  static const Color _inkMid      = Color(0xFF6C6C70);
  static const Color _greenBg     = Color(0xFFEDF7F1);
  static const Color _greenText   = Color(0xFF1A7A3C);
  static const Color _red         = Color(0xFFDC2626);
  static const Color _redBg       = Color(0xFFFEF2F2);
  static const Color _warning     = Color(0xFFF08030);
  static const Color _warningBg   = Color(0xFFFFF6EE);

  static const double _r  = 18;
  static const double _ri = 12;

  static List<BoxShadow> get _shadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.07),
          blurRadius: 20,
          offset: const Offset(0, 6),
        ),
      ];

  // ─── Classification ───────────────────────────────────────────────────────

  double? _extractZScore(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final m = RegExp(r'^-?\d+(\.\d+)?').firstMatch(raw.trim());
    return m == null ? null : double.tryParse(m.group(0)!);
  }

  double? _extractBmiZScore(String? raw) {
    if (raw == null || raw.isEmpty || !raw.contains('|')) return null;
    final parts = raw.split('|');
    if (parts.length < 2) return null;
    final m = RegExp(r'-?\d+(\.\d+)?').firstMatch(parts[1].trim());
    return m == null ? null : double.tryParse(m.group(0)!);
  }

  String _getClassification(Map<String, dynamic> a) {
    final wfa = _extractZScore(a['weightForAge']?.toString());
    final hfa = _extractZScore(a['heightForAge']?.toString());
    final wfh = _extractZScore(a['weightForHeight']?.toString());
    final bmi = _extractBmiZScore(a['bmi']?.toString());

    if (wfa == null && hfa == null && wfh == null && bmi == null) {
      return 'Assessment done';
    }
    if (wfa != null && wfa < -2) return 'Underweight';
    if (hfa != null && hfa < -2) return 'Stunted';
    if ((wfh != null && wfh > 1) || (bmi != null && bmi > 2)) {
      return 'Overweight/Obese';
    }
    final atRisk = (wfa != null && wfa >= -2 && wfa < -1) ||
        (hfa != null && hfa >= -2 && hfa < -1) ||
        (wfh != null && wfh >= -2 && wfh < -1) ||
        (bmi != null && bmi >= -2 && bmi < -1);
    return atRisk ? 'At Risk' : 'Normal';
  }

  Color _badgeFg(String c) {
    switch (c) {
      case 'Underweight':
      case 'Stunted':
        return _red;
      case 'Overweight/Obese':
      case 'At Risk':
        return _warning;
      default:
        return _greenText;
    }
  }

  Color _badgeBg(String c) {
    switch (c) {
      case 'Underweight':
      case 'Stunted':
        return _redBg;
      case 'Overweight/Obese':
      case 'At Risk':
        return _warningBg;
      default:
        return _greenBg;
    }
  }

  String _formatDate(DateTime? d) {
    if (d == null) return '--';
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  String _formatDateShort(DateTime? d) {
    if (d == null) return '--';
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    return '${months[d.month - 1]} ${d.day}';
  }

  // ─── Detail Modal ─────────────────────────────────────────────────────────

  void _showDetailModal(BuildContext ctx, Map<String, dynamic> a) {
    final cls  = _getClassification(a);
    final date = a['date'] as DateTime?;

    showDialog(
      context: ctx,
      barrierColor: Colors.black.withOpacity(0.45),
      builder: (dialogCtx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Container(
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 40,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            clipBehavior: Clip.hardEdge,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── 1. Gradient header ──
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_orangeLight, _orange],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.bar_chart_rounded,
                                color: Colors.white, size: 18),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Assessment Details',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () => Navigator.pop(dialogCtx),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.20),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.close_rounded,
                                  color: Colors.white, size: 18),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded,
                              size: 13, color: Colors.white70),
                          const SizedBox(width: 6),
                          Text(
                            _formatDate(date),
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              cls,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: _badgeFg(cls),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── 2. Scrollable measurements + z-scores ──
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(dialogCtx).size.height * 0.40,
                  ),
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'MEASUREMENTS',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: _inkMid,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _measureTile(Icons.straighten_rounded,
                                  'Height', '${a['height'] ?? '--'} cm'),
                              const SizedBox(width: 10),
                              _measureTile(Icons.monitor_weight_outlined,
                                  'Weight', '${a['weight'] ?? '--'} kg'),
                              const SizedBox(width: 10),
                              _measureTile(Icons.social_distance_rounded,
                                  'MUAC', '${a['muac'] ?? '--'} cm'),
                            ],
                          ),
                          if (_hasZScores(a)) ...[
                            const SizedBox(height: 16),
                            const Text(
                              'Z-SCORES',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: _inkMid,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 10),
                            _zScoreRow('Weight-for-Age',
                                a['weightForAge']?.toString()),
                            _zScoreRow('Height-for-Age',
                                a['heightForAge']?.toString()),
                            _zScoreRow('Weight-for-Height',
                                a['weightForHeight']?.toString()),
                            _zScoreRow('BMI', a['bmi']?.toString()),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),

                // ── 3. Divider ──
                const Divider(height: 1, color: _border),

                // ── 4. Delete + Edit buttons ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Row(
                    children: [
                      // Delete
                      Expanded(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: widget.onDeleteAssessment == null
                                ? null
                                : () {
                                    Navigator.pop(dialogCtx);
                                    _confirmDelete(a);
                                  },
                            child: Opacity(
                              opacity: widget.onDeleteAssessment == null
                                  ? 0.4
                                  : 1.0,
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 13),
                                decoration: BoxDecoration(
                                  color: _redBg,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: _red.withOpacity(0.20),
                                    width: 1,
                                  ),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.delete_outline_rounded,
                                        size: 16, color: _red),
                                    SizedBox(width: 6),
                                    Text(
                                      'Delete',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: _red,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Edit
                      Expanded(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: widget.onEditAssessment == null
                                ? null
                                : () {
                                    Navigator.pop(dialogCtx);
                                    _openEditSheet(a);
                                  },
                            child: Opacity(
                              opacity: widget.onEditAssessment == null
                                  ? 0.4
                                  : 1.0,
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 13),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                      colors: [_orangeLight, _orange]),
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _orange.withOpacity(0.28),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.edit_rounded,
                                        size: 16, color: Colors.white),
                                    SizedBox(width: 6),
                                    Text(
                                      'Edit',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  bool _hasZScores(Map<String, dynamic> a) =>
      (a['weightForAge']?.toString().isNotEmpty ?? false) ||
      (a['heightForAge']?.toString().isNotEmpty ?? false) ||
      (a['weightForHeight']?.toString().isNotEmpty ?? false) ||
      (a['bmi']?.toString().isNotEmpty ?? false);

  Widget _measureTile(IconData icon, String label, String value) =>
      Expanded(
        child: Container(
          padding:
              const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: _surfaceDim,
            borderRadius: BorderRadius.circular(_ri),
            border: Border.all(color: _border),
          ),
          child: Column(
            children: [
              Icon(icon, size: 18, color: _orange),
              const SizedBox(height: 6),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(label,
                  style:
                      const TextStyle(fontSize: 10, color: _inkMid)),
            ],
          ),
        ),
      );

  Widget _zScoreRow(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(label,
                style:
                    const TextStyle(fontSize: 12, color: _inkMid)),
          ),
          Expanded(
            flex: 6,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _ink,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Delete ───────────────────────────────────────────────────────────────

  Future<void> _confirmDelete(Map<String, dynamic> a) async {
    final id = a['id']?.toString() ?? '';

    if (id.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot delete: assessment has no ID.'),
          backgroundColor: _red,
        ),
      );
      return;
    }

    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_ri)),
        title: const Text(
          'Delete Assessment',
          style: TextStyle(fontWeight: FontWeight.w700, color: _ink),
        ),
        content: Text(
          'Remove the assessment from ${_formatDate(a['date'] as DateTime?)}? This cannot be undone.',
          style: const TextStyle(color: _inkMid, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Cancel',
                style: TextStyle(color: _inkMid)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text(
              'Delete',
              style: TextStyle(
                  color: _red, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && widget.onDeleteAssessment != null) {
      if (!mounted) return;
      await widget.onDeleteAssessment!(id, widget.patientId);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Assessment deleted.'),
          backgroundColor: _red,
        ),
      );
    }
  }

  // ─── Edit ─────────────────────────────────────────────────────────────────

  Future<void> _openEditSheet(Map<String, dynamic> a) async {
    final id = a['id']?.toString() ?? '';

    if (id.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot edit: assessment has no ID.'),
          backgroundColor: _red,
        ),
      );
      return;
    }

    final heightCtrl =
        TextEditingController(text: a['height']?.toString() ?? '');
    final weightCtrl =
        TextEditingController(text: a['weight']?.toString() ?? '');
    final muacCtrl =
        TextEditingController(text: a['muac']?.toString() ?? '');
    DateTime? selectedDate = a['date'] as DateTime?;

    final formKey = GlobalKey<FormState>();
    bool saving = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (_, setSheetState) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(sheetCtx).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: _surface,
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: _border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      _iconBox(Icons.edit_rounded),
                      const SizedBox(width: 12),
                      const Text(
                        'Edit Assessment',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: _ink,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Date picker
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: sheetCtx,
                        initialDate: selectedDate ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                        builder: (_, child) => Theme(
                          data: ThemeData.light().copyWith(
                            colorScheme: const ColorScheme.light(
                                primary: _orange),
                          ),
                          child: child!,
                        ),
                      );
                      if (picked != null) {
                        setSheetState(() => selectedDate = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 13),
                      decoration: BoxDecoration(
                        color: _surfaceDim,
                        borderRadius: BorderRadius.circular(_ri),
                        border: Border.all(color: _border),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded,
                              size: 16, color: _orange),
                          const SizedBox(width: 10),
                          Text(
                            selectedDate != null
                                ? _formatDate(selectedDate)
                                : 'Select date',
                            style: TextStyle(
                              fontSize: 14,
                              color: selectedDate != null
                                  ? _ink
                                  : _inkMid,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                          child: _editField(heightCtrl, 'Height (cm)',
                              Icons.straighten_rounded)),
                      const SizedBox(width: 10),
                      Expanded(
                          child: _editField(weightCtrl, 'Weight (kg)',
                              Icons.monitor_weight_outlined)),
                      const SizedBox(width: 10),
                      Expanded(
                          child: _editField(muacCtrl, 'MUAC (cm)',
                              Icons.social_distance_rounded)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _orange,
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 0,
                      ),
                      onPressed: saving
                          ? null
                          : () async {
                              if (!formKey.currentState!.validate()) return;
                              setSheetState(() => saving = true);

                              final updated = {
                                ...a,
                                'height': heightCtrl.text.trim(),
                                'weight': weightCtrl.text.trim(),
                                'muac': muacCtrl.text.trim(),
                                'date': selectedDate,
                              };

                              try {
                                await widget.onEditAssessment?.call(
                                  updated,
                                  id, // pre-validated id — no duplicate risk
                                  widget.patientId,
                                );
                                if (sheetCtx.mounted) {
                                  Navigator.pop(sheetCtx);
                                }
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Assessment updated.'),
                                      backgroundColor: _greenText,
                                    ),
                                  );
                                }
                              } catch (e) {
                                setSheetState(() => saving = false);
                                if (sheetCtx.mounted) {
                                  ScaffoldMessenger.of(sheetCtx).showSnackBar(
                                    SnackBar(
                                      content: Text('Failed to save: $e'),
                                      backgroundColor: _red,
                                    ),
                                  );
                                }
                              }
                            },
                      child: saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Save Changes',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _editField(
          TextEditingController ctrl, String label, IconData icon) =>
      TextFormField(
        controller: ctrl,
        keyboardType:
            const TextInputType.numberWithOptions(decimal: true),
        style: const TextStyle(fontSize: 14, color: _ink),
        decoration: InputDecoration(
          labelText: label,
          labelStyle:
              const TextStyle(fontSize: 12, color: _inkMid),
          prefixIcon: Icon(icon, size: 16, color: _orange),
          filled: true,
          fillColor: _surfaceDim,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 12, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(_ri),
            borderSide: const BorderSide(color: _border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(_ri),
            borderSide: const BorderSide(color: _border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(_ri),
            borderSide:
                const BorderSide(color: _orange, width: 1.5),
          ),
        ),
        validator: (v) =>
            (v == null || v.trim().isEmpty) ? 'Required' : null,
      );

  // ─── Build ────────────────────────────────────────────────────────────────

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
        children: [
          Container(
            height: 5,
            decoration: const BoxDecoration(
              gradient:
                  LinearGradient(colors: [_orangeLight, _orange]),
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(_r)),
            ),
          ),
          if (widget.loading)
            _buildLoading()
          else ...[
            _buildHeader(),
            const Divider(height: 1, color: _border),
            if (widget.assessments.isEmpty)
              _buildEmptyState()
            else ...[
              _buildColumnHeaders(),
              const SizedBox(height: 4),
              ...widget.assessments.map(_buildTableRow),
              const SizedBox(height: 8),
            ],
            const Divider(height: 1, color: _border),
            _buildAddButton(),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() => Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: 20, vertical: 16),
        child: Row(
          children: [
            _iconBox(Icons.bar_chart_rounded),
            const SizedBox(width: 12),
            const Text(
              'Assessment Records',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: _ink,
                letterSpacing: -0.3,
              ),
            ),
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

  Widget _buildLoading() => const Padding(
        padding: EdgeInsets.all(36),
        child: Center(
            child: CircularProgressIndicator(color: _orange)),
      );

  Widget _buildEmptyState() => Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.assessment_outlined,
                size: 40, color: _orange.withOpacity(0.35)),
            const SizedBox(height: 12),
            const Text(
              'No assessments recorded yet.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: _inkMid),
            ),
          ],
        ),
      );

  Widget _buildColumnHeaders() => Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
        child: Row(
          children: [
            _colHeader('Date',   flex: 2),
            _colHeader('Height', flex: 2),
            _colHeader('Weight', flex: 2),
            _colHeader('MUAC',   flex: 2),
            _colHeader('Status', flex: 3),
          ],
        ),
      );

  Widget _colHeader(String text, {required int flex}) => Expanded(
        flex: flex,
        child: Text(
          text.toUpperCase(),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: _inkMid,
            letterSpacing: 1.2,
          ),
        ),
      );

  Widget _buildTableRow(Map<String, dynamic> a) {
    final cls  = _getClassification(a);
    final date = a['date'] as DateTime?;

    return GestureDetector(
      onTap: () => _showDetailModal(context, a),
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 4, 12, 4),
        padding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: _surfaceDim,
          borderRadius: BorderRadius.circular(_ri),
          border: Border.all(color: _border, width: 1),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                _formatDateShort(date),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _orange,
                ),
              ),
            ),
            _cell(a['height']?.toString() ?? '--', flex: 2),
            _cell(a['weight']?.toString() ?? '--', flex: 2),
            _cell(a['muac']?.toString()   ?? '--', flex: 2),
            Expanded(
              flex: 3,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _badgeBg(cls),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: _badgeFg(cls).withOpacity(0.30),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    cls,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: _badgeFg(cls),
                      letterSpacing: 0.1,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cell(String text, {required int flex}) => Expanded(
        flex: flex,
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: _ink,
          ),
        ),
      );

  Widget _buildAddButton() => Padding(
        padding: const EdgeInsets.all(14),
        child: Center(
          child: GestureDetector(
            onTap: widget.onAddAssessment,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 28, vertical: 11),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [_orangeLight, _orange]),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: _orange.withOpacity(0.28),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_circle_outline_rounded,
                      size: 16, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Add New Assessment',
                    style: TextStyle(
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
        ),
      );
}