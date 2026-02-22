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

  // ─── Design Tokens (matches ProfileInfoCard) ────────────────────────────────
  static const Color _orange      = Color(0xFFF08030);
  static const Color _orangeLight = Color(0xFFF5A962);
  static const Color _surface     = Color(0xFFFFFFFF);
  static const Color _surfaceDim  = Color(0xFFFAFAFA);
  static const Color _border      = Color(0xFFE8E8ED);
  static const Color _ink         = Color(0xFF1C1C1E);
  static const Color _inkMid      = Color(0xFF6C6C70);
  static const Color _green       = Color(0xFF34C759);
  static const Color _greenBg     = Color(0xFFEDF7F1);
  static const Color _greenText   = Color(0xFF1A7A3C);

  static const double _r  = 18;
  static const double _ri = 12;

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

          _sectionLabel('GUARDIAN INFORMATION'),
          const SizedBox(height: 8),
          _card(children: [
            _infoTile(Icons.person_outline_rounded,       'Name',            _guardianName),
            _divider(),
            _infoTile(Icons.family_restroom_outlined,     'Relationship',    _relationship),
            _divider(),
            _infoTile(Icons.phone_outlined,               'Primary Phone',   _primaryPhone),
            _divider(),
            _infoTile(Icons.phone_in_talk_outlined,       'Secondary Phone', _secondaryPhone),
            _divider(),
            _infoTile(Icons.location_on_outlined,         'Address',         _guardianAddress),
          ]),

          const SizedBox(height: 20),

          _sectionLabel('EMERGENCY CONTACT'),
          const SizedBox(height: 8),
          _card(children: [
            _infoTile(Icons.emergency_outlined, 'Name',  _emergencyName),
            _divider(),
            _infoTile(Icons.phone_outlined,     'Phone', _emergencyPhone),
          ]),

          const SizedBox(height: 20),

          _sectionLabel('PREFERRED CONTACT METHOD'),
          const SizedBox(height: 8),
          _card(children: [
            _toggleTile(
              icon: Icons.phone_outlined,
              label: 'Phone Call',
              value: preferPhoneCall,
              onChanged: onPhoneCallChanged,
            ),
            _divider(),
            _toggleTile(
              icon: Icons.sms_outlined,
              label: 'SMS / Text Message',
              value: preferSMS,
              onChanged: onSMSChanged,
            ),
          ]),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(left: 2),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: _inkMid,
            letterSpacing: 1.2,
          ),
        ),
      );

  Widget _card({required List<Widget> children}) => Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(_r),
          border: Border.all(color: _border, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(children: children),
      );

  Widget _divider() => Container(
        height: 1,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        color: _border,
      );

  Widget _infoTile(IconData icon, String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: _orange.withOpacity(0.10),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, color: _orange, size: 16),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                      color: _inkMid,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: _ink,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _toggleTile({
    required IconData icon,
    required String label,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) =>
      GestureDetector(
        onTap: () => onChanged(!value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          color: value ? _orange.withOpacity(0.04) : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: value ? _orange.withOpacity(0.15) : _surfaceDim,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(
                    color: value ? _orange.withOpacity(0.30) : _border,
                    width: 1,
                  ),
                ),
                child: Icon(icon, color: value ? _orange : _inkMid, size: 16),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: value ? FontWeight.w700 : FontWeight.w500,
                    color: value ? _ink : _inkMid,
                  ),
                ),
              ),
              // Toggle pill
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 44,
                height: 26,
                decoration: BoxDecoration(
                  gradient: value
                      ? const LinearGradient(colors: [_orangeLight, _orange])
                      : null,
                  color: value ? null : _border,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 200),
                  alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    width: 20,
                    height: 20,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 1)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}