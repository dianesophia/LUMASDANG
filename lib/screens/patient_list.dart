import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'patient_profile/patient_profile_overview.dart';

// ==================== PATIENT LIST TAB ====================
class PatientListTab extends StatefulWidget {
  const PatientListTab({super.key});

  @override
  State<PatientListTab> createState() => _PatientListTabState();
}

class _PatientListTabState extends State<PatientListTab> {
  final TextEditingController _searchController = TextEditingController();
  bool _sortAscending = true;
  String _searchQuery = '';
  bool _loading = true;
  List<Patient> _patients = [];

  /// Extract the interpretation text from a z-score string like "-1.50 (Underweight)"
  String _extractInterpretation(String? zScoreStr) {
    if (zScoreStr == null || zScoreStr.isEmpty) return '';
    final match = RegExp(r'\(([^)]+)\)').firstMatch(zScoreStr);
    return match?.group(1) ?? '';
  }

  /// Build a simple nutritional status summary from the latest assessment.
  ///
  /// Examples:
  /// - "Underweight"
  /// - "Stunted"
  /// - "Overweight/Obese"
  /// - "At risk"
  /// If no clear issue is found but assessments exist, returns "Normal".
  /// If there are no assessments, returns "No assessments".
  String _buildAssessmentRemarks(Map<String, dynamic> data, int assessmentCount) {
    final anthropometric = (data['anthropometric'] ?? {}) as Map<String, dynamic>;

    final weightForAge = anthropometric['weightForAge']?.toString() ?? '';
    final heightForAge = anthropometric['heightForAge']?.toString() ?? '';
    final weightForHeight = anthropometric['weightForHeight']?.toString() ?? '';
    final bmi = anthropometric['bmi']?.toString() ?? '';

    final interpretations = <String>[];
    for (final raw in [weightForAge, heightForAge, weightForHeight, bmi]) {
      final interp = _extractInterpretation(raw);
      if (interp.isNotEmpty) {
        interpretations.add(interp.toLowerCase());
      }
    }

    if (assessmentCount == 0) {
      return 'No assessments';
    }

    // Collect high-level tags based on the interpretations
    final tags = <String>{};
    for (final interp in interpretations) {
      if (interp.contains('underweight')) {
        tags.add('Underweight');
      }
      if (interp.contains('stunted')) {
        tags.add('Stunted');
      }
      if (interp.contains('overweight') || interp.contains('obese')) {
        tags.add('Overweight/Obese');
      }
      if (interp.contains('at risk')) {
        tags.add('At risk');
      }
    }

    if (tags.isNotEmpty) {
      return tags.join(', ');
    }

    if (interpretations.isEmpty) {
      // There is at least one assessment, but no anthropometric interpretation stored.
      return 'Assessment done';
    }

    // If all interpretations are normal, label as Normal.
    final allNormal =
        interpretations.isNotEmpty && interpretations.every((i) => i == 'normal');
    if (allNormal) {
      return 'Normal';
    }

    // Fallback: use the first interpretation capitalized.
    final first = interpretations.first;
    return first.isEmpty
        ? 'Assessment done'
        : '${first[0].toUpperCase()}${first.substring(1)}';
  }

  @override
  void initState() {
    super.initState();
    _fetchPatients();
  }

  Future<void> _fetchPatients() async {
    setState(() => _loading = true);
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('No logged in user');
        setState(() => _loading = false);
        return;
      }

      // ✅ STEP 1: Get user's barangay
      print('Fetching user barangay...');
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final barangayId = userDoc.data()?['barangayId'] as String?;
      
      if (barangayId == null) {
        print('User has no barangay assigned');
        setState(() => _loading = false);
        return;
      }

      print('User barangay: $barangayId');

      // ✅ STEP 2: Fetch all patients from barangay's shared patient list
      final snapshot = await FirebaseFirestore.instance
          .collection('barangays')
          .doc(barangayId)
          .collection('patients')
          .orderBy('createdAt', descending: true)
          .get();

      print('Found ${snapshot.docs.length} patient records');

      // ✅ STEP 3: Group by patient name
      final Map<String, List<QueryDocumentSnapshot>> patientGroups = {};
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final demographic = data['demographic'] ?? {};
        
        String firstName = demographic['firstName']?.toString() ?? '';
        String lastName = demographic['lastName']?.toString() ?? '';
        
        // Create a key for grouping (case-insensitive)
        final key = '${firstName.toLowerCase().trim()}_${lastName.toLowerCase().trim()}';
        
        if (key.isNotEmpty && key != '_') {
          patientGroups.putIfAbsent(key, () => []);
          patientGroups[key]!.add(doc);
        }
      }
      
      print('Grouped into ${patientGroups.length} unique patients');

      // ✅ STEP 4: Create one Patient entry per unique patient
      setState(() {
        _patients = patientGroups.entries.map((entry) {
          final docs = entry.value;
          final assessmentCount = docs.length;
          docs.sort((a, b) {
            final dataA = a.data() as Map<String, dynamic>;
            final dataB = b.data() as Map<String, dynamic>;
            final timeA = (dataA['createdAt'] as Timestamp?)?.toDate() ?? DateTime(1970);
            final timeB = (dataB['createdAt'] as Timestamp?)?.toDate() ?? DateTime(1970);
            return timeB.compareTo(timeA); // Most recent first
          });
          
          // Sort by createdAt and get the most recent document
          docs.sort((a, b) {
              final dataA = a.data() as Map<String, dynamic>?; 
              final dataB = b.data() as Map<String, dynamic>?;

              final timeA = (dataA?['createdAt'] as Timestamp?)
                      ?.toDate() ??
                  DateTime(1970);

              final timeB = (dataB?['createdAt'] as Timestamp?)
                      ?.toDate() ??
                  DateTime(1970);

              return timeB.compareTo(timeA);
            });
            

          final mostRecentDoc = docs.first;
          final data = mostRecentDoc.data() as Map<String, dynamic>;
          final demographic = data['demographic'] ?? {};
          final createdAt = data['createdAt'] as Timestamp?;
          final assessmentRemarks =
              _buildAssessmentRemarks(data, assessmentCount);

          return Patient(
            firstName: demographic['firstName'] ?? (parts.isNotEmpty ? parts.first : ''),
            lastName: demographic['lastName'] ?? (parts.length > 1 ? parts.sublist(1).join(' ') : ''),
            age: int.tryParse(demographic['age'] ?? '0') ?? 0,
            assessmentRemarks: assessmentRemarks,
            lastVisit: createdAt?.toDate() ?? DateTime.now(),
            guardianContact: demographic['fatherContact'] ?? demographic['motherContact'] ?? '',
            avatarColor: const Color(0xFF2E8B7B),
            address: demographic['address'] ?? '',
            dateOfBirth: demographic['dateOfBirth'] ?? '',
            sex: demographic['sex'] ?? '',
            docId: mostRecentDoc.id,
            motherName: demographic['mother'] ?? '',
            motherContact: demographic['motherContact'] ?? '',
            fatherName: demographic['father'] ?? '',
            fatherContact: demographic['fatherContact'] ?? '',
            createdBy: data?['createdByName'] ?? 'Unknown',
            barangayId: barangayId,
          );
        }).toList();

        _loading = false;
      });
    } catch (e) {
      print('Error fetching patients: $e');
      setState(() => _loading = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading patients: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<Patient> get _filteredPatients {
    final filtered = _patients.where((patient) {
      final query = _searchQuery.toLowerCase();
      return patient.lastName.toLowerCase().contains(query) ||
          patient.firstName.toLowerCase().contains(query) ||
          patient.assessmentRemarks.toLowerCase().contains(query);
    }).toList();

    filtered.sort((a, b) {
      final comparison = a.lastName.compareTo(b.lastName);
      return _sortAscending ? comparison : -comparison;
    });

    return filtered;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Colors.white,
        ),
      );
    }

    if (_patients.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_off_outlined,
              size: 64,
              color: Colors.white.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'No patients found in your barangay',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add a patient assessment to get started',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSearchBar(),
          const SizedBox(height: 12),
          _buildTotalPatientsCount(),
          const SizedBox(height: 8),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF4A9B8C),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildTableHeader(),
                  Expanded(
                    child: _buildPatientList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          _buildSortButton(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        decoration: InputDecoration(
          hintText: 'Search patients...',
          hintStyle: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: Colors.grey[400],
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildTotalPatientsCount() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          'Total Patients: ${_filteredPatients.length}',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 40),
          _buildHeaderCell('Last name', flex: 2),
          _buildHeaderCell('First name', flex: 2),
          _buildHeaderCell('Age (months)', flex: 1),
          _buildHeaderCell('Assessment\nRemarks', flex: 2),
          _buildHeaderCell('Last visit', flex: 2),
          _buildHeaderCell('Guardian\nContact', flex: 2),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String text, {required int flex}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildPatientList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: _filteredPatients.length,
      itemBuilder: (context, index) {
        return _buildPatientRow(_filteredPatients[index], index);
      },
    );
  }

  Widget _buildPatientRow(Patient patient, int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            _showPatientDetails(patient);
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E8B7B),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: patient.avatarColor.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: ClipOval(
                    child: Image.network(
                      'https://ui-avatars.com/api/?name=${patient.firstName}+${patient.lastName}&background=8BC88A&color=fff&size=56',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.person,
                          size: 16,
                          color: patient.avatarColor,
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  flex: 2,
                  child: Text(
                    patient.lastName,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF333333),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    patient.firstName,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF333333),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    '${patient.age} mos',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF333333),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    patient.assessmentRemarks,
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                      color: Colors.green,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    '${patient.lastVisit.month.toString().padLeft(2,'0')}/${patient.lastVisit.day.toString().padLeft(2,'0')}/${patient.lastVisit.year}',
                    style: const TextStyle(
                      fontSize: 9,
                      color: Color(0xFF333333),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildContactIcon(
                          Icons.phone,
                          const Color(0xFF2E8B7B),
                          () => _handleCall(patient),
                        ),
                        const SizedBox(width: 2),
                        _buildContactIcon(
                          Icons.message,
                          const Color(0xFFF5A962),
                          () => _handleMessage(patient),
                        ),
                        const SizedBox(width: 2),
                        _buildContactIcon(
                          Icons.more_horiz,
                          Colors.grey,
                          () => _showMoreOptions(patient),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContactIcon(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 10,
          color: color,
        ),
      ),
    );
  }

  Widget _buildSortButton() {
    return Align(
      alignment: Alignment.centerRight,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _sortAscending = !_sortAscending;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _sortAscending ? 'A-Z' : 'Z-A',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF333333),
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                _sortAscending ? Icons.arrow_downward : Icons.arrow_upward,
                size: 14,
                color: const Color(0xFF333333),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleCall(Patient patient) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Calling ${patient.guardianContact}...'),
        backgroundColor: const Color(0xFF2E8B7B),
      ),
    );
  }

  void _handleMessage(Patient patient) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Messaging ${patient.guardianContact}...'),
        backgroundColor: const Color(0xFFF5A962),
      ),
    );
  }

  void _showMoreOptions(Patient patient) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.visibility, color: Color(0xFF2E8B7B)),
              title: const Text('View Details'),
              onTap: () {
                Navigator.pop(context);
                _showPatientDetails(patient);
              },
            ),
            ListTile(
              leading: const Icon(Icons.assessment, color: Color(0xFF2E8B7B)),
              title: const Text('New Assessment'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showPatientDetails(Patient patient) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: patient.avatarColor.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.person, color: patient.avatarColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${patient.firstName} ${patient.lastName}',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Age', '${patient.age} months old'),
            _buildDetailRow('Assessment', patient.assessmentRemarks),
            _buildDetailRow('Last Visit',
                '${patient.lastVisit.month}/${patient.lastVisit.day}/${patient.lastVisit.year}'),
            _buildDetailRow('Guardian Contact', patient.guardianContact),
            _buildDetailRow('Added by', patient.createdBy),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Close',
              style: TextStyle(color: Color(0xFF2E8B7B)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PatientProfileOverview(
                    patient: patient,
                    //isSharedPatient: true,           // ← Mark as shared
                    //sharedPatientId: patient.docId,  // ← Pass the Firestore document ID
                   //barangayId: patient.barangayId,  // ← Pass the barangay ID
                  
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E8B7B),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text(
              'View Profile',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF666666),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF333333),
              ),
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