import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// National Immunization Program vaccines (Philippines)
class _Vaccine {
  final String key;
  final String displayName;

  const _Vaccine({required this.key, required this.displayName});
}

const _vaccines = [
  _Vaccine(key: 'bcg', displayName: 'BCG'),
  _Vaccine(key: 'opvIpv', displayName: 'OPV / IPV'),
  _Vaccine(key: 'dptPentavalent', displayName: 'DPT / Pentavalent'),
  _Vaccine(key: 'measlesMmr', displayName: 'Measles / MMR'),
  _Vaccine(key: 'hepatitisB', displayName: 'Hepatitis B'),
];

/// Widget displaying the Vaccination Status card in the patient profile.
/// 
/// Supports two storage modes:
/// 1. Personal mode: Stores under `users/{uid}/vaccinations/{patientKey}`
/// 2. Shared mode: Stores under `barangays/{barangayId}/patients/{patientId}/vaccination`
///    (Use this when patient data is shared across barangay)
class VaccinationStatusSection extends StatefulWidget {
  final String firstName;
  final String lastName;
  
  /// Optional: If provided, vaccination will be stored in barangay-shared patient record
  final String? patientId;
  final String? barangayId;
  
  /// If true, stores vaccination in barangay-shared location
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
  Map<String, bool> _statuses = {};
  DateTime? _lastReviewDate;
  String? _lastModifiedByName;
  bool _loading = true;

  /// Firestore document key for this patient's vaccination record (personal mode)
  String get _patientKey =>
      '${widget.firstName.trim().toLowerCase()}_${widget.lastName.trim().toLowerCase()}';

  /// Get the appropriate document reference based on storage mode
  DocumentReference get _docRef {
    if (widget.useSharedStorage && widget.patientId != null && widget.barangayId != null) {
      // Shared storage: barangays/{barangayId}/patients/{patientId}/vaccination/record
      return FirebaseFirestore.instance
          .collection('barangays')
          .doc(widget.barangayId)
          .collection('patients')
          .doc(widget.patientId)
          .collection('vaccination')
          .doc('record');
    } else {
      // Personal storage: users/{uid}/vaccinations/{patientKey}
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      return FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('vaccinations')
          .doc(_patientKey);
    }
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
        final Map<String, bool> loaded = {};
        for (final v in _vaccines) {
          loaded[v.key] = data[v.key] == true;
        }
        final ts = data['lastReviewDate'] as Timestamp?;
        setState(() {
          _statuses = loaded;
          _lastReviewDate = ts?.toDate();
          _lastModifiedByName = data['lastModifiedByName'] as String?;
          _loading = false;
        });
      } else {
        // No record yet – initialize with all pending
        final Map<String, bool> defaults = {};
        for (final v in _vaccines) {
          defaults[v.key] = false;
        }
        setState(() {
          _statuses = defaults;
          _lastReviewDate = null;
          _lastModifiedByName = null;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching vaccination: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _saveVaccination(Map<String, bool> updated) async {
    try {
      final now = DateTime.now();
      final currentUser = FirebaseAuth.instance.currentUser;
      
      // Get current user's name for audit trail
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
        'firstName': widget.firstName,
        'lastName': widget.lastName,
        'lastReviewDate': Timestamp.fromDate(now),
        'lastModifiedBy': currentUser?.uid ?? '',
        'lastModifiedByName': userName,
        'updatedAt': Timestamp.fromDate(now),
      };
      
      for (final entry in updated.entries) {
        payload[entry.key] = entry.value;
      }
      
      await _docRef.set(payload, SetOptions(merge: true));
      
      setState(() {
        _statuses = Map.from(updated);
        _lastReviewDate = now;
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

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${months[date.month - 1]} ${date.day.toString().padLeft(2, '0')}, ${date.year}';
  }

  int get _completedCount =>
      _statuses.values.where((v) => v).length;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFB8E6D5),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: _loading
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(
                  color: Color(0xFF2E8B7B),
                ),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Title bar ──
                _buildTitleBar(),
                const SizedBox(height: 6),

                // ── Last review date ──
                Center(
                  child: Column(
                    children: [
                      Text(
                        'Last Vaccination Review: ${_formatDate(_lastReviewDate)}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF2E8B7B),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      if (_lastModifiedByName != null && widget.useSharedStorage)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            'Updated by: $_lastModifiedByName',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Colors.black.withOpacity(0.5),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // ── Immunization Record header ──
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check,
                        size: 20,
                        color: _completedCount == _vaccines.length
                            ? const Color(0xFF4CAF50)
                            : const Color(0xFF2E8B7B),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Immunization Record',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.black.withOpacity(0.85),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // ── Vaccine list ──
                ...(_vaccines.map((v) {
                  final completed = _statuses[v.key] ?? false;
                  return Padding(
                    padding: const EdgeInsets.only(left: 34, bottom: 6),
                    child: Row(
                      children: [
                        Text(
                          '•  ',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black.withOpacity(0.7),
                          ),
                        ),
                        Text(
                          '${v.displayName}: ',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black.withOpacity(0.8),
                            height: 1.4,
                          ),
                        ),
                        Text(
                          completed ? 'Completed' : 'Pending',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: completed
                                ? Colors.black.withOpacity(0.85)
                                : const Color(0xFFFF9800),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  );
                })),

                const SizedBox(height: 12),

                // ── Overall status checkmark ──
                if (_completedCount == _vaccines.length)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.check, size: 20, color: Color(0xFF4CAF50)),
                        const SizedBox(width: 10),
                        Text(
                          'All vaccinations complete',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF4CAF50).withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.check, size: 20, color: Color(0xFFFF9800)),
                        const SizedBox(width: 10),
                        Text(
                          '$_completedCount of ${_vaccines.length} vaccines completed',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 12),

                // ── Update button ──
                Center(
                  child: ElevatedButton(
                    onPressed: () => _showUpdateSheet(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 2,
                    ),
                    child: const Text(
                      'Update',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildTitleBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFD4F1E3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Vaccination Status',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
                letterSpacing: 0.5,
              ),
            ),
            if (widget.useSharedStorage) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E8B7B),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Shared',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─── Update vaccination bottom sheet ───
  void _showUpdateSheet(BuildContext context) {
    // Local copy for the sheet
    final draft = Map<String, bool>.from(_statuses);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.7,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(top: 12, bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Title
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'Update Vaccination Record',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E8B7B),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.firstName} ${widget.lastName}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black54,
                    ),
                  ),
                  if (widget.useSharedStorage)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF2E8B7B).withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.people,
                              size: 14,
                              color: const Color(0xFF2E8B7B),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Shared with barangay team',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF2E8B7B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),

                  // Vaccine toggles
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      children: _vaccines.map((v) {
                        final completed = draft[v.key] ?? false;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Container(
                            decoration: BoxDecoration(
                              color: completed
                                  ? const Color(0xFFE8F5E9)
                                  : const Color(0xFFFFF3E0),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: completed
                                    ? const Color(0xFF4CAF50).withOpacity(0.4)
                                    : const Color(0xFFFF9800).withOpacity(0.4),
                                width: 1,
                              ),
                            ),
                            child: CheckboxListTile(
                              value: completed,
                              onChanged: (val) {
                                setSheetState(() {
                                  draft[v.key] = val ?? false;
                                });
                              },
                              title: Text(
                                v.displayName,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              subtitle: Text(
                                completed ? 'Completed' : 'Pending',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: completed
                                      ? const Color(0xFF4CAF50)
                                      : const Color(0xFFFF9800),
                                ),
                              ),
                              activeColor: const Color(0xFF2E8B7B),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Save button
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          await _saveVaccination(draft);
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text('Vaccination record updated.'),
                                backgroundColor: Color(0xFF2E8B7B),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E8B7B),
                          foregroundColor: Colors.white,
                          padding:
                              const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          elevation: 3,
                        ),
                        child: const Text(
                          'Save',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}