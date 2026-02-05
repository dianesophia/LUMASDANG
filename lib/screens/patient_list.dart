import 'package:flutter/material.dart';

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

  // Sample patient data
  final List<Patient> _patients = [
    Patient(
      lastName: 'Fajutagana',
      firstName: 'Aldric',
      age: 2,
      assessmentRemarks: 'Underweight',
      lastVisit: DateTime(2025, 12, 27),
      guardianContact: '09123456789',
      avatarColor: const Color(0xFF8BC88A),
    ),
    Patient(
      lastName: 'Aquino',
      firstName: 'Maria',
      age: 3,
      assessmentRemarks: 'Normal',
      lastVisit: DateTime(2025, 12, 20),
      guardianContact: '09234567890',
      avatarColor: const Color(0xFF5CAA7F),
    ),
    Patient(
      lastName: 'Bautista',
      firstName: 'Juan',
      age: 1,
      assessmentRemarks: 'Stunted',
      lastVisit: DateTime(2025, 12, 15),
      guardianContact: '09345678901',
      avatarColor: const Color(0xFF2E8B7B),
    ),
    Patient(
      lastName: 'Cruz',
      firstName: 'Ana',
      age: 4,
      assessmentRemarks: 'Overweight',
      lastVisit: DateTime(2025, 12, 10),
      guardianContact: '09456789012',
      avatarColor: const Color(0xFF8BC88A),
    ),
    Patient(
      lastName: 'Dela Cruz',
      firstName: 'Pedro',
      age: 2,
      assessmentRemarks: 'Normal',
      lastVisit: DateTime(2025, 12, 5),
      guardianContact: '09567890123',
      avatarColor: const Color(0xFF5CAA7F),
    ),
    Patient(
      lastName: 'Garcia',
      firstName: 'Sofia',
      age: 3,
      assessmentRemarks: 'At Risk',
      lastVisit: DateTime(2025, 11, 30),
      guardianContact: '09678901234',
      avatarColor: const Color(0xFF2E8B7B),
    ),
    Patient(
      lastName: 'Hernandez',
      firstName: 'Luis',
      age: 1,
      assessmentRemarks: 'Normal',
      lastVisit: DateTime(2025, 11, 25),
      guardianContact: '09789012345',
      avatarColor: const Color(0xFF8BC88A),
    ),
    Patient(
      lastName: 'Lopez',
      firstName: 'Isabella',
      age: 2,
      assessmentRemarks: 'Underweight',
      lastVisit: DateTime(2025, 11, 20),
      guardianContact: '09890123456',
      avatarColor: const Color(0xFF5CAA7F),
    ),
    Patient(
      lastName: 'Martinez',
      firstName: 'Carlos',
      age: 4,
      assessmentRemarks: 'Normal',
      lastVisit: DateTime(2025, 11, 15),
      guardianContact: '09901234567',
      avatarColor: const Color(0xFF2E8B7B),
    ),
    Patient(
      lastName: 'Reyes',
      firstName: 'Elena',
      age: 3,
      assessmentRemarks: 'Stunted',
      lastVisit: DateTime(2025, 11, 10),
      guardianContact: '09012345678',
      avatarColor: const Color(0xFF8BC88A),
    ),
  ];

  List<Patient> get _filteredPatients {
    List<Patient> filtered = _patients.where((patient) {
      final query = _searchQuery.toLowerCase();
      return patient.lastName.toLowerCase().contains(query) ||
          patient.firstName.toLowerCase().contains(query) ||
          patient.assessmentRemarks.toLowerCase().contains(query);
    }).toList();

    // Sort alphabetically by last name
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
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Search Bar
          _buildSearchBar(),
          const SizedBox(height: 12),
          // Total Patients Count
          _buildTotalPatientsCount(),
          const SizedBox(height: 8),
          // Patient List Container
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF4A9B8C),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Table Header
                  _buildTableHeader(),
                  // Patient List
                  Expanded(
                    child: _buildPatientList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          // A-Z Sort Button
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
            color: Colors.black.withValues(alpha: 0.1),
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
          hintText: 'Search',
          hintStyle: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: Colors.grey[400],
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
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
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 40), // Space for checkbox and avatar
          _buildHeaderCell('Last name', flex: 2),
          _buildHeaderCell('First name', flex: 2),
          _buildHeaderCell('Age', flex: 1),
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
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Handle patient selection
            _showPatientDetails(patient);
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: Row(
              children: [
                // Checkbox
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
                // Avatar
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: patient.avatarColor.withValues(alpha: 0.3),
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
                // Last Name
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
                // First Name
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
                // Age
                Expanded(
                  flex: 1,
                  child: Text(
                    '${patient.age}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF333333),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                // Assessment Remarks
                Expanded(
                  flex: 2,
                  child: Text(
                    patient.assessmentRemarks,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                      color: _getAssessmentColor(patient.assessmentRemarks),
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Last Visit
                Expanded(
                  flex: 2,
                  child: Text(
                    _formatDate(patient.lastVisit),
                    style: const TextStyle(
                      fontSize: 9,
                      color: Color(0xFF333333),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                // Guardian Contact Icons
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
          color: color.withValues(alpha: 0.15),
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
                color: Colors.black.withValues(alpha: 0.1),
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

  Color _getAssessmentColor(String assessment) {
    switch (assessment.toLowerCase()) {
      case 'underweight':
        return const Color(0xFFE53935);
      case 'overweight':
        return const Color(0xFFFF9800);
      case 'stunted':
        return const Color(0xFFE53935);
      case 'at risk':
        return const Color(0xFFFF9800);
      case 'normal':
        return const Color(0xFF4CAF50);
      default:
        return const Color(0xFF333333);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}';
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
              leading: const Icon(Icons.edit, color: Color(0xFFF5A962)),
              title: const Text('Edit Patient'),
              onTap: () {
                Navigator.pop(context);
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
                color: patient.avatarColor.withValues(alpha: 0.3),
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
            _buildDetailRow('Age', '${patient.age} years old'),
            _buildDetailRow('Assessment', patient.assessmentRemarks),
            _buildDetailRow('Last Visit', _formatDate(patient.lastVisit)),
            _buildDetailRow('Guardian Contact', patient.guardianContact),
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

  Patient({
    required this.lastName,
    required this.firstName,
    required this.age,
    required this.assessmentRemarks,
    required this.lastVisit,
    required this.guardianContact,
    required this.avatarColor,
  });
}
