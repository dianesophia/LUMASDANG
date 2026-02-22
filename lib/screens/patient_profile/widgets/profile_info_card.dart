import 'package:flutter/material.dart';
import '../../patient_list.dart';

/// Patient information card with modern UI styling.
class ProfileInfoCard extends StatelessWidget {
  final Patient patient;

  const ProfileInfoCard({
    super.key,
    required this.patient,
  });

  // ─── Design Tokens ─────────────────────────────────────────────
  static const Color _cardBg     = Color(0xFFB8E6D5);
  static const Color _headerBg   = Color(0xFFD4F1E3);
  static const Color _accentTeal = Color(0xFF2E8B7B);
  static const Color _darkText   = Color(0xFF1A3C34);
  static const Color _bodyText   = Color(0xFF2A4F47);

  static const double _cardRadius = 20;

  static List<BoxShadow> get _cardShadow => [
        BoxShadow(
          color: _accentTeal.withOpacity(0.18),
          blurRadius: 18,
          spreadRadius: 1,
          offset: const Offset(0, 6),
        ),
        BoxShadow(
          color: Colors.white.withOpacity(0.6),
          blurRadius: 1,
          offset: const Offset(0, -1),
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_cardBg, _headerBg],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(_cardRadius),
        boxShadow: _cardShadow,
      ),
      child: Column(
        children: [
          // ───────── HEADER ─────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: const BoxDecoration(
              color: _headerBg,
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(_cardRadius)),
            ),
            child: Row(
              children: [
                const Icon(Icons.person, color: _accentTeal),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${patient.firstName} ${patient.lastName}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: _darkText,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, thickness: 1),

          // ───────── BODY ─────────
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Avatar with Glow ──
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [_accentTeal, _cardBg],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _accentTeal.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(3),
                  child: ClipOval(
                    child: Image.network(
                      'https://ui-avatars.com/api/?name=${patient.firstName}+${patient.lastName}'
                      '&background=D4F1E3&color=2E8B7B&size=200&bold=true',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.person_rounded,
                        size: 40,
                        color: _accentTeal,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 20),

                // ── Info Chips Section ──
                Expanded(
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _infoChip(Icons.location_on, patient.address),
                      _infoChip(Icons.cake, patient.dateOfBirth),
                      _infoChip(Icons.calendar_today, '${patient.age} yrs'),
                      _infoChip(Icons.wc, patient.sex),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ───────── INFO CHIP WIDGET ─────────
  Widget _infoChip(IconData icon, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.75),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _accentTeal.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: _accentTeal),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              value.isNotEmpty ? value : "N/A",
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: _bodyText,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}