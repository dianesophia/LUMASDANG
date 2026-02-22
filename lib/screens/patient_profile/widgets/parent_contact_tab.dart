import 'package:flutter/material.dart';
import '../../patient_list.dart';
import 'profile_info_card.dart';

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

  // ── Derived fields ────────────────────────────────────────────────────────
  String get _guardianName =>
      patient.motherName.isNotEmpty ? patient.motherName :
      patient.fatherName.isNotEmpty ? patient.fatherName : 'N/A';

  String get _relationship =>
      patient.motherName.isNotEmpty ? 'Mother' :
      patient.fatherName.isNotEmpty ? 'Father' : 'N/A';

  String get _primaryPhone =>
      patient.motherContact.isNotEmpty ? patient.motherContact :
      patient.fatherContact.isNotEmpty ? patient.fatherContact : 'N/A';

  String get _secondaryPhone =>
      (patient.motherContact.isNotEmpty && patient.fatherContact.isNotEmpty)
          ? patient.fatherContact : 'N/A';

  String get _guardianAddress =>
      patient.address.isNotEmpty ? patient.address : 'N/A';

  String get _emergencyName =>
      patient.fatherName.isNotEmpty ? '${patient.fatherName} (Father)' :
      patient.motherName.isNotEmpty ? '${patient.motherName} (Mother)' : 'N/A';

  String get _emergencyPhone =>
      patient.fatherContact.isNotEmpty ? patient.fatherContact :
      patient.motherContact.isNotEmpty ? patient.motherContact : 'N/A';

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProfileInfoCard(patient: patient),
          const SizedBox(height: 20),

          // ── Section label ─────────────────────────────────────────────
          _sectionLabel('GUARDIAN INFORMATION'),
          const SizedBox(height: 10),

          // ── Guardian details card ─────────────────────────────────────
          _frostedCard(
            children: [
              _infoRow(Icons.person_outline_rounded, 'Name', _guardianName),
              _divider(),
              _infoRow(Icons.family_restroom_outlined, 'Relationship', _relationship),
              _divider(),
              _infoRow(Icons.phone_outlined, 'Primary Phone', _primaryPhone),
              _divider(),
              _infoRow(Icons.phone_in_talk_outlined, 'Secondary Phone', _secondaryPhone),
              _divider(),
              _infoRow(Icons.location_on_outlined, 'Address', _guardianAddress),
            ],
          ),

          const SizedBox(height: 20),

          // ── Section label ─────────────────────────────────────────────
          _sectionLabel('EMERGENCY CONTACT'),
          const SizedBox(height: 10),

          _frostedCard(
            children: [
              _infoRow(Icons.emergency_outlined, 'Name', _emergencyName),
              _divider(),
              _infoRow(Icons.phone_outlined, 'Phone', _emergencyPhone),
            ],
          ),

          const SizedBox(height: 20),

          // ── Section label ─────────────────────────────────────────────
          _sectionLabel('PREFERRED CONTACT METHOD'),
          const SizedBox(height: 10),

          // ── Preferred contact toggle ──────────────────────────────────
          _frostedCard(
            children: [
              _contactToggle(
                icon: Icons.phone_outlined,
                label: 'Phone Call',
                value: preferPhoneCall,
                onChanged: onPhoneCallChanged,
              ),
              _divider(),
              _contactToggle(
                icon: Icons.sms_outlined,
                label: 'SMS / Text Message',
                value: preferSMS,
                onChanged: onSMSChanged,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Colors.white.withOpacity(0.65),
            letterSpacing: 1.4,
          ),
        ),
      );

  Widget _frostedCard({required List<Widget> children}) => Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.18),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.28), width: 1),
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(children: children),
      );

  Widget _divider() => Container(
        height: 1,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        color: Colors.white.withOpacity(0.15),
      );

  Widget _infoRow(IconData icon, String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon badge
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.white, size: 17),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withOpacity(0.55),
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            // Chevron hint
            Icon(Icons.chevron_right_rounded,
                color: Colors.white.withOpacity(0.25), size: 20),
          ],
        ),
      );

  Widget _contactToggle({
    required IconData icon,
    required String label,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) =>
      GestureDetector(
        onTap: () => onChanged(!value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          color: value ? Colors.white.withOpacity(0.1) : Colors.transparent,
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: value
                      ? Colors.white.withOpacity(0.3)
                      : Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon,
                    color: value ? Colors.white : Colors.white.withOpacity(0.5),
                    size: 17),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: value ? FontWeight.w700 : FontWeight.w400,
                    color: value ? Colors.white : Colors.white.withOpacity(0.6),
                  ),
                ),
              ),
              // Toggle pill
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 44,
                height: 24,
                decoration: BoxDecoration(
                  color: value ? Colors.white : Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: value
                        ? Colors.white
                        : Colors.white.withOpacity(0.35),
                    width: 1,
                  ),
                ),
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 180),
                  alignment:
                      value ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    width: 18,
                    height: 18,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: value
                          ? const Color(0xFF2E8B7B)
                          : Colors.white.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}