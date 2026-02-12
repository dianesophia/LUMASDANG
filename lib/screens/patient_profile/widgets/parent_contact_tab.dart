import 'package:flutter/material.dart';
import '../../patient_list.dart';
import 'profile_info_card.dart';

/// Parent / Guardian Contact Information tab.
/// Displays the parent/guardian details for a given patient,
/// matching the rounded-card design shown in the mockup.
///
/// Preferred contact method state is owned by the parent widget
/// so it survives tab switches and is persisted to Firestore.
class ParentContactTab extends StatelessWidget {
  final Patient patient;
  final bool preferPhoneCall;
  final bool preferSMS;
  final ValueChanged<bool?> onPhoneCallChanged;
  final ValueChanged<bool?> onSMSChanged;

  const ParentContactTab({
    super.key,
    required this.patient,
    required this.preferPhoneCall,
    required this.preferSMS,
    required this.onPhoneCallChanged,
    required this.onSMSChanged,
  });

  /// Determine the primary guardian name and relationship.
  /// Prefers mother data if available, falls back to father.
  String get _guardianName {
    if (patient.motherName.isNotEmpty) return patient.motherName;
    if (patient.fatherName.isNotEmpty) return patient.fatherName;
    return 'N/A';
  }

  String get _relationship {
    if (patient.motherName.isNotEmpty) return 'Mother';
    if (patient.fatherName.isNotEmpty) return 'Father';
    return 'N/A';
  }

  String get _primaryPhone {
    if (patient.motherContact.isNotEmpty) return patient.motherContact;
    if (patient.fatherContact.isNotEmpty) return patient.fatherContact;
    return 'N/A';
  }

  String get _secondaryPhone {
    if (patient.motherContact.isNotEmpty &&
        patient.fatherContact.isNotEmpty) {
      return patient.fatherContact;
    }
    return 'N/A';
  }

  String get _guardianAddress {
    return patient.address.isNotEmpty ? patient.address : 'N/A';
  }

  /// Emergency contact: the *other* parent (father if mother is primary, etc.)
  String get _emergencyName {
    if (patient.fatherName.isNotEmpty) {
      return '${patient.fatherName} - Father';
    }
    if (patient.motherName.isNotEmpty) {
      return '${patient.motherName} - Mother';
    }
    return 'N/A';
  }

  String get _emergencyPhone {
    if (patient.fatherContact.isNotEmpty) return patient.fatherContact;
    if (patient.motherContact.isNotEmpty) return patient.motherContact;
    return 'N/A';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 16),

          // ===== AVATAR + INFO CARD (same as profile) =====
          ProfileInfoCard(patient: patient),
          const SizedBox(height: 24),

          // ===== CONTACT INFO CARDS =====
          _ContactInfoCard(
            label: 'Parent / Guardian Name',
            value: _guardianName,
          ),
          const SizedBox(height: 14),

          _ContactInfoCard(
            label: 'Relationship to Child:',
            value: _relationship,
          ),
          const SizedBox(height: 14),

          _ContactInfoCard(
            label: 'Primary Phone Number',
            value: _primaryPhone,
          ),
          const SizedBox(height: 14),

          _ContactInfoCard(
            label: 'Secondary Phone Number',
            value: _secondaryPhone,
          ),
          const SizedBox(height: 14),

          _ContactInfoCard(
            label: 'Address',
            value: _guardianAddress,
          ),
          const SizedBox(height: 20),

          // ===== EMERGENCY CONTACT =====
          _EmergencyContactCard(
            name: _emergencyName,
            phone: _emergencyPhone,
          ),
          const SizedBox(height: 20),

          // ===== PREFERRED CONTACT METHOD =====
          _PreferredContactMethodCard(
            phoneCall: preferPhoneCall,
            sms: preferSMS,
            onPhoneCallChanged: onPhoneCallChanged,
            onSMSChanged: onSMSChanged,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

/// A rounded card with a header pill and bullet-point value,
/// using the same light-teal style as Emergency Contact / Preferred Contact.
class _ContactInfoCard extends StatelessWidget {
  final String label;
  final String value;

  const _ContactInfoCard({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFB5DDD4),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Header pill ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF7FBFB3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                fontStyle: FontStyle.italic,
                color: Color(0xFF1A3C34),
              ),
            ),
          ),

          // ── Bullet value ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 3),
                  child: Icon(Icons.circle, size: 8, color: Color(0xFF1A3C34)),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A3C34),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Emergency Contact card with a light teal background,
/// showing the emergency contact name + relationship and phone number.
class _EmergencyContactCard extends StatelessWidget {
  final String name;
  final String phone;

  const _EmergencyContactCard({
    required this.name,
    required this.phone,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFB5DDD4),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Header pill ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF7FBFB3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Emergency Contact',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                fontStyle: FontStyle.italic,
                color: Color(0xFF1A3C34),
              ),
            ),
          ),

          // ── Content ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name + relationship
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 3),
                      child: Icon(Icons.circle, size: 8, color: Color(0xFF1A3C34)),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A3C34),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Phone
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Text(
                    'Phone: $phone',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF2A4F47),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Preferred Contact Method card with checkboxes for Phone call and SMS.
class _PreferredContactMethodCard extends StatelessWidget {
  final bool phoneCall;
  final bool sms;
  final ValueChanged<bool?> onPhoneCallChanged;
  final ValueChanged<bool?> onSMSChanged;

  const _PreferredContactMethodCard({
    required this.phoneCall,
    required this.sms,
    required this.onPhoneCallChanged,
    required this.onSMSChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFB5DDD4),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Header pill ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF7FBFB3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Preferred Contact Method',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                fontStyle: FontStyle.italic,
                color: Color(0xFF1A3C34),
              ),
            ),
          ),

          // ── Checkboxes ──
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Phone call
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Checkbox(
                      value: phoneCall,
                      onChanged: onPhoneCallChanged,
                      activeColor: const Color(0xFF2E8B7B),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      side: const BorderSide(
                        color: Color(0xFF2A4F47),
                        width: 2,
                      ),
                    ),
                    const Text(
                      'Phone call',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A3C34),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                // SMS
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Checkbox(
                      value: sms,
                      onChanged: onSMSChanged,
                      activeColor: const Color(0xFF2E8B7B),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      side: const BorderSide(
                        color: Color(0xFF2A4F47),
                        width: 2,
                      ),
                    ),
                    const Text(
                      'SMS',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A3C34),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
