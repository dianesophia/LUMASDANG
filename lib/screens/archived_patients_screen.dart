import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'patient_list.dart';
import 'patient_profile/patient_profile_overview.dart';
import '../services/firestore_service.dart';

/// Read-only list of archived patients (5+ years old).
class ArchivedPatientsScreen extends StatefulWidget {
  const ArchivedPatientsScreen({super.key});

  @override
  State<ArchivedPatientsScreen> createState() => _ArchivedPatientsScreenState();
}

class _ArchivedPatientsScreenState extends State<ArchivedPatientsScreen> {
  bool _loading = true;
  List<Patient> _patients = [];
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  String _extractInterpretation(String? zScoreStr) {
    if (zScoreStr == null || zScoreStr.isEmpty) return '';
    final match = RegExp(r'\(([^)]+)\)').firstMatch(zScoreStr);
    return match?.group(1) ?? '';
  }

  String _buildAssessmentRemarks(Map<String, dynamic> data, int assessmentCount) {
    final anthropometric = (data['anthropometric'] ?? {}) as Map<String, dynamic>;
    final weightForAge = anthropometric['weightForAge']?.toString() ?? '';
    final heightForAge = anthropometric['heightForAge']?.toString() ?? '';
    final weightForHeight = anthropometric['weightForHeight']?.toString() ?? '';
    final bmi = anthropometric['bmi']?.toString() ?? '';

    final interpretations = <String>[];
    for (final raw in [weightForAge, heightForAge, weightForHeight, bmi]) {
      final interp = _extractInterpretation(raw);
      if (interp.isNotEmpty) interpretations.add(interp.toLowerCase());
    }

    if (assessmentCount == 0) return 'No assessments';

    final tags = <String>{};
    for (final interp in interpretations) {
      if (interp.contains('underweight')) tags.add('Underweight');
      if (interp.contains('stunted')) tags.add('Stunted');
      if (interp.contains('overweight') || interp.contains('obese')) tags.add('Overweight/Obese');
      if (interp.contains('at risk')) tags.add('At risk');
    }

    if (tags.isNotEmpty) return tags.join(', ');
    if (interpretations.isEmpty) return 'Assessment done';

    final allNormal = interpretations.isNotEmpty &&
        interpretations.every((i) => i == 'normal');
    if (allNormal) return 'Normal';

    final first = interpretations.first;
    return first.isEmpty ? 'Assessment done' : '${first[0].toUpperCase()}${first.substring(1)}';
  }

  Color _statusColor(String remarks) {
    final r = remarks.toLowerCase();
    if (r.contains('underweight') || r.contains('stunted') || r.contains('wasted')) {
      return const Color(0xFFE57373);
    }
    if (r.contains('overweight') || r.contains('obese')) {
      return const Color(0xFFFFB74D);
    }
    if (r.contains('at risk')) return const Color(0xFFFFD54F);
    if (r == 'normal') return const Color(0xFF66BB6A);
    if (r == 'no assessments') return Colors.grey;
    return const Color(0xFF4DB6AC);
  }

  @override
  void initState() {
    super.initState();
    _fetchArchivedPatients();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchArchivedPatients() async {
    setState(() => _loading = true);
    try {
      final firestore = FirestoreService();
      final archived = await firestore.getArchivedPatientsFromBarangay();

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.uid ?? '')
          .get();
      final barangayId = userDoc.data()?['barangayId'] as String? ?? '';

      final Map<String, List<Map<String, dynamic>>> groups = {};
      for (final doc in archived) {
        final demographic = (doc['demographic'] ?? {}) as Map<String, dynamic>;
        final key =
            '${(demographic['firstName'] ?? '').toString().toLowerCase().trim()}_${(demographic['lastName'] ?? '').toString().toLowerCase().trim()}';
        if (key.isNotEmpty && key != '_') {
          groups.putIfAbsent(key, () => []);
          groups[key]!.add(doc);
        }
      }

      final List<Patient> patients = [];
      for (final entry in groups.entries) {
        final list = entry.value;
        list.sort((a, b) {
          final timeA = _getCreatedAt(a);
          final timeB = _getCreatedAt(b);
          return timeB.compareTo(timeA);
        });
        final mostRecent = list.first;
        final data = mostRecent;
        final demographic = (data['demographic'] ?? {}) as Map<String, dynamic>;
        final createdAt = _getCreatedAt(data);

        patients.add(Patient(
          firstName: demographic['firstName'] ?? '',
          lastName: demographic['lastName'] ?? '',
          age: int.tryParse(demographic['age']?.toString() ?? '0') ?? 0,
          assessmentRemarks: _buildAssessmentRemarks(data, list.length),
          lastVisit: createdAt,
          guardianContact: demographic['fatherContact'] ?? demographic['motherContact'] ?? '',
          avatarColor: const Color(0xFF2E8B7B),
          address: demographic['address'] ?? '',
          dateOfBirth: demographic['dateOfBirth'] ?? '',
          sex: demographic['sex'] ?? '',
          docId: data['id'] ?? '',
          motherName: demographic['mother'] ?? '',
          motherContact: demographic['motherContact'] ?? '',
          fatherName: demographic['father'] ?? '',
          fatherContact: demographic['fatherContact'] ?? '',
          createdBy: data['createdByName'] ?? 'Unknown',
          barangayId: barangayId,
          isArchived: true,
        ));
      }

      patients.sort((a, b) => a.lastName.compareTo(b.lastName));

      setState(() {
        _patients = patients;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Error fetching archived patients: $e');
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading archived patients: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  DateTime _getCreatedAt(Map<String, dynamic> data) {
    final createdAt = data['createdAt'];
    if (createdAt is Timestamp) return createdAt.toDate();
    return DateTime.now();
  }

  List<Patient> get _filteredPatients {
    final q = _searchQuery.toLowerCase();
    if (q.isEmpty) return _patients;
    return _patients.where((p) {
      return p.lastName.toLowerCase().contains(q) ||
          p.firstName.toLowerCase().contains(q) ||
          p.assessmentRemarks.toLowerCase().contains(q);
    }).toList();
  }

  String _sanitizePhone(String raw) => raw.replaceAll(RegExp(r'[^\d+]'), '');

  Future<void> _handleCall(Patient patient) async {
    final number = _sanitizePhone(patient.guardianContact);
    if (number.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('No guardian contact number to call'),
            backgroundColor: Colors.orange.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
      return;
    }
    final uri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _handleMessage(Patient patient) async {
    final number = _sanitizePhone(patient.guardianContact);
    if (number.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('No guardian contact number to message'),
            backgroundColor: Colors.orange.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
      return;
    }
    final uri = Uri(scheme: 'sms', path: number);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  void _showPatientDetails(Patient patient) {
    final statusColor = _statusColor(patient.assessmentRemarks);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: EdgeInsets.zero,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
                        'https://ui-avatars.com/api/?name=${patient.firstName}+${patient.lastName}&background=ffffff&color=2E8B7B&size=96',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.person_rounded, color: Colors.white, size: 28),
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
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.amber.withOpacity(0.4),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Archived (5+ yrs)',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.25),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.white.withOpacity(0.3), width: 0.8),
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
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _detailRow(Icons.cake_outlined, 'Age', '${patient.age} months old'),
                  _detailRow(Icons.calendar_today_outlined, 'Last Visit',
                      '${patient.lastVisit.month}/${patient.lastVisit.day}/${patient.lastVisit.year}'),
                  _detailRow(Icons.phone_outlined, 'Contact',
                      patient.guardianContact.isEmpty ? '—' : patient.guardianContact),
                  _detailRow(Icons.person_outline_rounded, 'Added by', patient.createdBy),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF2E8B7B),
                        side: const BorderSide(color: Color(0xFF2E8B7B)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Close', style: TextStyle(fontWeight: FontWeight.w600)),
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
                            builder: (_) => PatientProfileOverview(patient: patient),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E8B7B),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                      ),
                      child: const Text('View Profile', style: TextStyle(fontWeight: FontWeight.w700)),
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
              style: const TextStyle(fontSize: 13, color: Color(0xFF1A1A1A)),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2E8B7B),
              Color(0xFF5CAA7F),
              Color(0xFF8BC88A),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              if (_loading)
                const Expanded(
                  child: Center(child: CircularProgressIndicator(color: Colors.white)),
                )
              else if (_patients.isEmpty)
                Expanded(
                  child: Center(
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
                            Icons.archive_outlined,
                            size: 40,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'No archived patients',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Children are archived when they reach 5 years old',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      children: [
                        _buildSearchBar(),
                        const SizedBox(height: 12),
                        _buildCountChip(),
                        const SizedBox(height: 10),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: Colors.white.withOpacity(0.25), width: 1),
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
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
            onPressed: () => Navigator.pop(context),
          ),
          const Expanded(
            child: Center(
              child: Text(
                'ARCHIVED (5+ YRS)',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

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
          prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.shade400, size: 20),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.close_rounded, color: Colors.grey.shade400, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildCountChip() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.archive_outlined, color: Colors.white, size: 14),
            const SizedBox(width: 6),
            Text(
              '${_filteredPatients.length} Archived',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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

  Widget _buildPatientList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 6),
      itemCount: _filteredPatients.length,
      itemBuilder: (context, index) => _buildPatientRow(_filteredPatients[index]),
    );
  }

  Widget _buildPatientRow(Patient patient) {
    final statusColor = _statusColor(patient.assessmentRemarks);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(12),
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
          onTap: () => _showPatientDetails(patient),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E8B7B).withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: ClipOval(
                    child: Image.network(
                      'https://ui-avatars.com/api/?name=${patient.firstName}+${patient.lastName}&background=8BC88A&color=fff&size=56',
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
                Expanded(
                  flex: 2,
                  child: Text(
                    patient.firstName,
                    style: const TextStyle(fontSize: 10, color: Color(0xFF444444)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    '${patient.age}m',
                    style: const TextStyle(fontSize: 10, color: Color(0xFF444444)),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: statusColor.withOpacity(0.3), width: 0.8),
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
                Expanded(
                  flex: 2,
                  child: Text(
                    '${patient.lastVisit.month.toString().padLeft(2, '0')}/${patient.lastVisit.day.toString().padLeft(2, '0')}/${patient.lastVisit.year}',
                    style: const TextStyle(fontSize: 9, color: Color(0xFF666666)),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _contactIcon(Icons.phone_rounded, const Color(0xFF2E8B7B), () => _handleCall(patient)),
                      const SizedBox(width: 4),
                      _contactIcon(Icons.sms_rounded, const Color(0xFFF5A962), () => _handleMessage(patient)),
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

  Widget _contactIcon(IconData icon, Color color, VoidCallback onTap) {
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
}
