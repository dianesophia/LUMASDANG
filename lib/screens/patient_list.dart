import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'patient_profile/patient_profile_overview.dart';
import 'opt_plus/opt_plus_screen.dart';
import 'shared/status_color.dart';

// ==================== PATIENT LIST TAB ====================
class PatientListTab extends StatefulWidget {
  final ValueNotifier<int>? refreshTrigger;
  const PatientListTab({super.key, this.refreshTrigger});

  @override
  State<PatientListTab> createState() => _PatientListTabState();
}

class _PatientListTabState extends State<PatientListTab> {
  final TextEditingController _searchController = TextEditingController();
  bool _sortAscending = true;
  String _searchQuery = '';
  bool _loading = true;
  List<Patient> _patients = [];
  bool _selectionMode = false;
  final Set<String> _selectedDocIds = {};
  bool _deleting = false;

  // Extracts leading z-score number from strings like "-2.5 (Stunted)" or "-2.5"
  double? _extractZScore(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final match = RegExp(r'^-?\d+(\.\d+)?').firstMatch(raw.trim());
    if (match == null) return null;
    return double.tryParse(match.group(0)!);
  }

  String _buildAssessmentRemarks(Map<String, dynamic> data, int assessmentCount) {
    if (assessmentCount == 0) return 'No assessments';

    final anthropometric = (data['anthropometric'] ?? {}) as Map<String, dynamic>;

    final double? weightForAge    = _extractZScore(anthropometric['weightForAge']?.toString());
    final double? heightForAge    = _extractZScore(anthropometric['heightForAge']?.toString());
    final double? weightForHeight = _extractZScore(anthropometric['weightForHeight']?.toString());
    final double? bmi             = _extractZScore(anthropometric['bmi']?.toString());

    if (weightForAge == null && heightForAge == null &&
        weightForHeight == null && bmi == null) {
      return 'Assessment done';
    }

    // Priority 1: Underweight (Weight-for-Age < -2 SD)
    if (weightForAge != null && weightForAge < -2) return 'Underweight';

    // Priority 2: Stunted (Height-for-Age < -2 SD)
    if (heightForAge != null && heightForAge < -2) return 'Stunted';

    // Priority 3: Overweight/Obese (Weight-for-Height > +1 SD or BMI > +2 SD)
    if ((weightForHeight != null && weightForHeight > 1) ||
        (bmi != null && bmi > 2)) return 'Overweight/Obese';

    // Priority 4: At Risk (any indicator -2 to -1 SD)
    final atRisk = (weightForAge != null && weightForAge >= -2 && weightForAge < -1) ||
        (heightForAge != null && heightForAge >= -2 && heightForAge < -1) ||
        (weightForHeight != null && weightForHeight >= -2 && weightForHeight < -1) ||
        (bmi != null && bmi >= -2 && bmi < -1);
    if (atRisk) return 'At Risk';

    // Priority 5: Normal
    return 'Normal';
  }

  @override
  void initState() {
    super.initState();
    _fetchPatients();
    widget.refreshTrigger?.addListener(_onRefreshTriggered);
  }

  void _onRefreshTriggered() {
    if (mounted) _fetchPatients();
  }

  void _exitSelectionMode() {
    setState(() {
      _selectionMode = false;
      _selectedDocIds.clear();
    });
  }

  void _toggleSelection(Patient patient) {
    setState(() {
      if (_selectedDocIds.contains(patient.docId)) {
        _selectedDocIds.remove(patient.docId);
      } else {
        _selectedDocIds.add(patient.docId);
      }
    });
  }

  // ── SELECT ALL / DESELECT ALL ──────────────────────────────────────────────
  void _toggleSelectAll() {
    setState(() {
      final allVisibleIds = _filteredPatients.map((p) => p.docId).toSet();
      final allSelected = allVisibleIds.every((id) => _selectedDocIds.contains(id));
      if (allSelected) {
        _selectedDocIds.removeAll(allVisibleIds);
      } else {
        _selectedDocIds.addAll(allVisibleIds);
      }
    });
  }

  Future<void> _confirmAndSoftDelete() async {
    if (_selectedDocIds.isEmpty) return;
    final count = _selectedDocIds.length;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Selected?',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text(
          'Soft-delete $count patient record(s)? '
          'They will be hidden from the list but can be restored later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFF2E8B7B))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _deleting = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      final deletedBy = user?.email ?? user?.uid ?? 'unknown';
      final batch = FirebaseFirestore.instance.batch();

      // ✅ FIX: iterate _patients (not _filteredPatients) so selected records
      // that are currently filtered out are still soft-deleted.
      for (final patient in _patients) {
        if (!_selectedDocIds.contains(patient.docId)) continue;
        final ref = FirebaseFirestore.instance
            .collection('barangays')
            .doc(patient.barangayId)
            .collection('patients')
            .doc(patient.docId);
        batch.update(ref, {
          'isDeleted': true,
          'deletedAt': FieldValue.serverTimestamp(),
          'deletedBy': deletedBy,
        });
      }
      await batch.commit();
      if (mounted) {
        _exitSelectionMode();
        await _fetchPatients();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$count record(s) deleted.'),
            backgroundColor: const Color(0xFF2E8B7B),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Delete failed: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  Future<void> _fetchPatients() async {
    setState(() => _loading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() => _loading = false);
        return;
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final barangayId = userDoc.data()?['barangayId'] as String?;
      if (barangayId == null) {
        setState(() => _loading = false);
        return;
      }

      final snapshot = await FirebaseFirestore.instance
          .collection('barangays')
          .doc(barangayId)
          .collection('patients')
          .where('isDeleted', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .get();

      final Map<String, List<QueryDocumentSnapshot>> patientGroups = {};
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final demographic = data['demographic'] ?? {};
        final key =
            '${(demographic['firstName'] ?? '').toString().toLowerCase().trim()}_'
            '${(demographic['lastName'] ?? '').toString().toLowerCase().trim()}';
        if (key.isNotEmpty && key != '_') {
          patientGroups.putIfAbsent(key, () => []);
          patientGroups[key]!.add(doc);
        }
      }

      setState(() {
        _patients = patientGroups.entries.map((entry) {
          final docs = entry.value;
          final assessmentCount = docs.length;
          docs.sort((a, b) {
            final dataA = a.data() as Map<String, dynamic>;
            final dataB = b.data() as Map<String, dynamic>;
            final timeA = (dataA['createdAt'] as Timestamp?)?.toDate()
                ?? DateTime(1970);
            final timeB = (dataB['createdAt'] as Timestamp?)?.toDate()
                ?? DateTime(1970);
            return timeB.compareTo(timeA);
          });

          final mostRecentDoc = docs.first;
          final data = mostRecentDoc.data() as Map<String, dynamic>;
          final demographic = data['demographic'] ?? {};
          final createdAt = data['createdAt'] as Timestamp?;
          final assessmentRemarks =
              _buildAssessmentRemarks(data, assessmentCount);

          return Patient(
            firstName: demographic['firstName'] ?? '',
            lastName: demographic['lastName'] ?? '',
            age: int.tryParse(demographic['age'] ?? '0') ?? 0,
            assessmentRemarks: assessmentRemarks,
            lastVisit: createdAt?.toDate() ?? DateTime.now(),
            guardianContact: demographic['fatherContact'] ??
                demographic['motherContact'] ?? '',
            avatarColor: const Color(0xFF2E8B7B),
            address: demographic['address'] ?? '',
            dateOfBirth: demographic['dateOfBirth'] ?? '',
            sex: demographic['sex'] ?? '',
            docId: mostRecentDoc.id,
            motherName: demographic['mother'] ?? '',
            motherContact: demographic['motherContact'] ?? '',
            fatherName: demographic['father'] ?? '',
            fatherContact: demographic['fatherContact'] ?? '',
            createdBy: data['createdByName'] ?? 'Unknown',
            barangayId: barangayId,
          );
        }).toList();
        _loading = false;
      });
    } catch (e) {
      debugPrint('Error fetching patients: $e');
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading patients: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  List<Patient> get _filteredPatients {
    final filtered = _patients.where((p) {
      final q = _searchQuery.toLowerCase();
      return p.lastName.toLowerCase().contains(q) ||
          p.firstName.toLowerCase().contains(q) ||
          p.assessmentRemarks.toLowerCase().contains(q);
    }).toList();

    filtered.sort((a, b) {
      final cmp = a.lastName.compareTo(b.lastName);
      return _sortAscending ? cmp : -cmp;
    });
    return filtered;
  }

  @override
  void dispose() {
    widget.refreshTrigger?.removeListener(_onRefreshTriggered);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: Colors.white));
    }

    if (_patients.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person_off_outlined,
                size: 40,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No patients found',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Add a patient assessment to get started',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        children: [
          _buildSearchBar(),
          const SizedBox(height: 12),
          _buildTopRow(),
          if (_selectionMode) ...[
            const SizedBox(height: 8),
            _buildSelectionBar(),
          ],
          const SizedBox(height: 10),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                    color: Colors.white.withOpacity(0.25), width: 1),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Column(
                  children: [
                    _buildTableHeader(),
                    Expanded(child: _buildPatientList()),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          _buildSortButton(),
        ],
      ),
    );
  }

  // ── SEARCH BAR ─────────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() => _searchQuery = v),
        style: const TextStyle(fontSize: 14, color: Colors.black87),
        decoration: InputDecoration(
          hintText: 'Search by name or status…',
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          prefixIcon: Icon(Icons.search_rounded,
              color: Colors.grey.shade400, size: 20),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.close_rounded,
                      color: Colors.grey.shade400, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  // ── TOP ROW ────────────────────────────────────────────────────────────────
  Widget _buildTopRow() {
    return Row(
      children: [
        ElevatedButton.icon(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const OptPlusScreen()),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF2E8B7B),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            elevation: 2,
          ),
          icon: const Icon(Icons.post_add_rounded, size: 16),
          label: const Text(
            'OPT Plus',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
        ),
        const Spacer(),
        // ── Select All button (only in selection mode) ──────────────────────
        if (_selectionMode) ...[
          GestureDetector(
            onTap: _toggleSelectAll,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: Colors.white.withOpacity(0.3), width: 1),
              ),
              child: Row(
                children: [
                  Icon(
                    _filteredPatients.every(
                            (p) => _selectedDocIds.contains(p.docId))
                        ? Icons.check_box_rounded
                        : Icons.check_box_outline_blank_rounded,
                    color: Colors.white,
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Select All',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: Colors.white.withOpacity(0.3), width: 1),
          ),
          child: Row(
            children: [
              const Icon(Icons.people_outline_rounded,
                  color: Colors.white, size: 14),
              const SizedBox(width: 6),
              Text(
                '${_filteredPatients.length} Patients',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── SELECTION BAR ──────────────────────────────────────────────────────────
  Widget _buildSelectionBar() {
    final count = _selectedDocIds.length;
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            count > 0
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked,
            size: 18,
            color: count > 0 ? const Color(0xFF2E8B7B) : Colors.grey,
          ),
          const SizedBox(width: 8),
          Text(
            count == 0 ? 'Long-press a row to select' : '$count selected',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: count > 0 ? const Color(0xFF333333) : Colors.grey,
            ),
          ),
          const Spacer(),
          if (count > 0)
            TextButton.icon(
              onPressed: _deleting ? null : _confirmAndSoftDelete,
              icon: _deleting
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.red),
                    )
                  : const Icon(Icons.delete_outline_rounded, size: 16),
              label: Text(_deleting ? 'Deleting…' : 'Delete'),
              style:
                  TextButton.styleFrom(foregroundColor: Colors.redAccent),
            ),
          TextButton(
            onPressed: _deleting ? null : _exitSelectionMode,
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFF2E8B7B))),
          ),
        ],
      ),
    );
  }

  // ── TABLE HEADER ───────────────────────────────────────────────────────────
  Widget _buildTableHeader() {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
      ),
      child: Row(
        children: [
          const SizedBox(width: 46),
          _headerCell('Last Name', flex: 2),
          _headerCell('First Name', flex: 2),
          _headerCell('Age', flex: 1),
          _headerCell('Status', flex: 2),
          _headerCell('Last Visit', flex: 2),
          _headerCell('Contact', flex: 2),
        ],
      ),
    );
  }

  Widget _headerCell(String text, {required int flex}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Colors.white.withOpacity(0.85),
          letterSpacing: 0.4,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  // ── PATIENT LIST ───────────────────────────────────────────────────────────
  Widget _buildPatientList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 6),
      itemCount: _filteredPatients.length,
      itemBuilder: (context, index) =>
          _buildPatientRow(_filteredPatients[index], index),
    );
  }

  Widget _buildPatientRow(Patient patient, int index) {
    final isSelected = _selectedDocIds.contains(patient.docId);
    final statusColor = getStatusColor(patient.assessmentRemarks);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFF2E8B7B).withOpacity(0.15)
            : Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(12),
        border: isSelected
            ? Border.all(
                color: const Color(0xFF2E8B7B).withOpacity(0.4),
                width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onLongPress: () {
            setState(() {
              _selectionMode = true;
              _selectedDocIds.add(patient.docId);
            });
          },
          onTap: () => _selectionMode
              ? _toggleSelection(patient)
              : _showPatientDetails(patient),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
            child: Row(
              children: [
                // Checkbox / avatar
                if (_selectionMode)
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: Checkbox(
                      value: isSelected,
                      onChanged: (_) => _toggleSelection(patient),
                      activeColor: const Color(0xFF2E8B7B),
                      materialTapTargetSize:
                          MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4)),
                    ),
                  )
                else
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color:
                          const Color(0xFF2E8B7B).withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: ClipOval(
                      child: Image.network(
                        'https://ui-avatars.com/api/?name=${patient.firstName}+${patient.lastName}'
                        '&background=8BC88A&color=fff&size=56',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.person_rounded,
                          size: 16,
                          color: const Color(0xFF2E8B7B),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(width: 8),

                // Last name
                Expanded(
                  flex: 2,
                  child: Text(
                    patient.lastName,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // First name
                Expanded(
                  flex: 2,
                  child: Text(
                    patient.firstName,
                    style: const TextStyle(
                        fontSize: 10, color: Color(0xFF444444)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // Age
                Expanded(
                  flex: 1,
                  child: Text(
                    '${patient.age}m',
                    style: const TextStyle(
                        fontSize: 10, color: Color(0xFF444444)),
                    textAlign: TextAlign.center,
                  ),
                ),

                // Status badge
                Expanded(
                  flex: 2,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: statusColor.withOpacity(0.3),
                            width: 0.8),
                      ),
                      child: Text(
                        patient.assessmentRemarks,
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ),
                  ),
                ),

                // Last visit
                Expanded(
                  flex: 2,
                  child: Text(
                    '${patient.lastVisit.month.toString().padLeft(2, '0')}/'
                    '${patient.lastVisit.day.toString().padLeft(2, '0')}/'
                    '${patient.lastVisit.year}',
                    style: const TextStyle(
                        fontSize: 9, color: Color(0xFF666666)),
                    textAlign: TextAlign.center,
                  ),
                ),

                // Contact icons
                Expanded(
                  flex: 2,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _contactIcon(
                        Icons.phone_rounded,
                        const Color(0xFF2E8B7B),
                        _selectionMode
                            ? () {}
                            : () => _handleCall(patient),
                      ),
                      const SizedBox(width: 4),
                      _contactIcon(
                        Icons.sms_rounded,
                        const Color(0xFFF5A962),
                        _selectionMode
                            ? () {}
                            : () => _handleMessage(patient),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _contactIcon(
      IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 12, color: color),
      ),
    );
  }

  // ── SORT BUTTON ────────────────────────────────────────────────────────────
  Widget _buildSortButton() {
    return Align(
      alignment: Alignment.centerRight,
      child: GestureDetector(
        onTap: () => setState(() => _sortAscending = !_sortAscending),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _sortAscending
                    ? Icons.arrow_downward_rounded
                    : Icons.arrow_upward_rounded,
                size: 14,
                color: const Color(0xFF2E8B7B),
              ),
              const SizedBox(width: 6),
              Text(
                _sortAscending ? 'A → Z' : 'Z → A',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2E8B7B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── CONTACT HANDLERS ───────────────────────────────────────────────────────
  String _sanitizePhone(String raw) =>
      raw.replaceAll(RegExp(r'[^\d+]'), '');

  Future<void> _handleCall(Patient patient) async {
    final number = _sanitizePhone(patient.guardianContact);
    if (number.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No guardian contact number to call'),
          backgroundColor: Colors.orange.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }
    final uri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cannot open dialer for $number'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  Future<void> _handleMessage(Patient patient) async {
    final number = _sanitizePhone(patient.guardianContact);
    if (number.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              const Text('No guardian contact number to message'),
          backgroundColor: Colors.orange.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }
    final uri = Uri(scheme: 'sms', path: number);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cannot open messaging app for $number'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  // ── PATIENT DETAIL DIALOG ──────────────────────────────────────────────────
  void _showPatientDetails(Patient patient) {
    final statusColor = getStatusColor(patient.assessmentRemarks);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: EdgeInsets.zero,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header strip
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF2E8B7B), Color(0xFF5CAA7F)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      shape: BoxShape.circle,
                    ),
                    child: ClipOval(
                      child: Image.network(
                        'https://ui-avatars.com/api/?name=${patient.firstName}+${patient.lastName}'
                        '&background=ffffff&color=2E8B7B&size=96',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                            Icons.person_rounded,
                            color: Colors.white,
                            size: 28),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${patient.firstName} ${patient.lastName}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 0.8),
                          ),
                          child: Text(
                            patient.assessmentRemarks,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Details
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _detailRow(Icons.cake_outlined, 'Age',
                      '${patient.age} months old'),
                  _detailRow(
                      Icons.calendar_today_outlined,
                      'Last Visit',
                      '${patient.lastVisit.month}/${patient.lastVisit.day}/${patient.lastVisit.year}'),
                  _detailRow(
                      Icons.phone_outlined,
                      'Contact',
                      patient.guardianContact.isEmpty
                          ? '—'
                          : patient.guardianContact),
                  _detailRow(Icons.person_outline_rounded, 'Added by',
                      patient.createdBy),
                ],
              ),
            ),

            // Actions
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF2E8B7B),
                        side: const BorderSide(
                            color: Color(0xFF2E8B7B)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(
                            vertical: 12),
                      ),
                      child: const Text('Close',
                          style:
                              TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PatientProfileOverview(
                                patient: patient),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E8B7B),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(
                            vertical: 12),
                        elevation: 0,
                      ),
                      child: const Text('View Profile',
                          style: TextStyle(
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF2E8B7B)),
          const SizedBox(width: 10),
          Text(
            '$label:',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF666666),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                  fontSize: 13, color: Color(0xFF1A1A1A)),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== PATIENT MODEL ====================
class Patient {
  final String lastName;
  final String firstName;
  final int age;
  final String assessmentRemarks;
  final DateTime lastVisit;
  final String guardianContact;
  final Color avatarColor;
  final String address;
  final String dateOfBirth;
  final String sex;
  final String docId;
  final String motherName;
  final String motherContact;
  final String fatherName;
  final String fatherContact;
  final String createdBy;
  final String barangayId;

  Patient({
    required this.lastName,
    required this.firstName,
    required this.age,
    required this.assessmentRemarks,
    required this.lastVisit,
    required this.guardianContact,
    required this.avatarColor,
    this.address = '',
    this.dateOfBirth = '',
    this.sex = '',
    this.docId = '',
    this.motherName = '',
    this.motherContact = '',
    this.fatherName = '',
    this.fatherContact = '',
    this.createdBy = 'Unknown',
    this.barangayId = '',
  });
}