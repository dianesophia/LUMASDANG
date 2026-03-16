import 'package:flutter/material.dart';
import '../../patient_list.dart';

/// Patient information card — clean clinical dark-accent style.
class ProfileInfoCard extends StatelessWidget {
  final Patient patient;
  final Map<String, dynamic>? latestDemographic;

  const ProfileInfoCard({
    super.key,
    required this.patient,
    this.latestDemographic,
  });

  // ─── Design Tokens ─────────────────────────────────────────────
  static const Color _orange      = Color(0xFFF08030);
  static const Color _orangeLight = Color(0xFFF5A962);
  static const Color _surface     = Color(0xFFFFFFFF);
  static const Color _border      = Color(0xFFE8E8ED);

  static const double _r = 18;

  @override
  Widget build(BuildContext context) {
    final int ageMonths = patient.age; // age displayed in months

    final demo = latestDemographic ?? const <String, dynamic>{};

    String _stringField(String key) =>
        (demo[key] ?? '').toString().trim();

    String _boolLabel(String key) {
      final v = demo[key];
      if (v is bool) return v ? 'Yes' : 'No';
      if (v is String && v.isNotEmpty) return v;
      return '';
    }

    final bloodType     = _stringField('bloodType');
    final birthWeight   = _stringField('birthWeight');
    final birthOrder    = _stringField('birthOrder');
    final religion      = _stringField('religion');
    final ipGroup       = _boolLabel('belongsToIpGroup');
    final disability    = _boolLabel('hasDisability');
    final residence     = _stringField('residenceStatus');
    final lengthOfStay  = _stringField('lengthOfStay');

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(_r),
        border: Border.all(color: _border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top accent bar ──
          Container(
            height: 5,
            decoration: BoxDecoration(
              //gradient: const LinearGradient(
                //colors: [_orangeLight, _orange],
              //),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(_r),
              ),
            ),
          ),

          // ── Header row ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar
                _Avatar(patient: patient),

                const SizedBox(width: 16),

                // Name + tags
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${patient.firstName} ${patient.lastName}',
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1C1C1E),
                          letterSpacing: -0.4,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _Tag(label: patient.sex, color: _orange),
                          const SizedBox(width: 6),
                          _Tag(label: '$ageMonths mo', color: _orangeLight),
                        ],
                      ),
                    ],
                  ),
                ),

                // Active pill
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDF7F1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFF34C759),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Text(
                        'Active',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A7A3C),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Divider ──
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Divider(height: 1, color: _border),
          ),

          // ── Info Grid ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _InfoTile(
                        icon: Icons.cake_outlined,
                        label: 'Date of Birth',
                        value: patient.dateOfBirth,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _InfoTile(
                        icon: Icons.child_care_outlined,
                        label: 'Age',
                        value: '$ageMonths months',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _InfoTile(
                  icon: Icons.location_on_outlined,
                  label: 'Address',
                  value: patient.address,
                  fullWidth: true,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _InfoTile(
                        icon: Icons.bloodtype_outlined,
                        label: 'Blood Type',
                        value: bloodType,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _InfoTile(
                        icon: Icons.scale_outlined,
                        label: 'Birth Weight (kg)',
                        value: birthWeight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _InfoTile(
                        icon: Icons.format_list_numbered_rounded,
                        label: 'Birth Order',
                        value: birthOrder,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _InfoTile(
                        icon: Icons.self_improvement_outlined,
                        label: 'Religion',
                        value: religion,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _InfoTile(
                        icon: Icons.groups_2_outlined,
                        label: 'Belongs to IP Group',
                        value: ipGroup,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _InfoTile(
                        icon: Icons.accessible_outlined,
                        label: 'Has Disability',
                        value: disability,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _InfoTile(
                        icon: Icons.home_work_outlined,
                        label: 'Status of Residence',
                        value: residence,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _InfoTile(
                        icon: Icons.schedule_outlined,
                        label: 'Length of Stay (yrs)',
                        value: lengthOfStay,
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

// ─── Avatar ────────────────────────────────────────────────────────────────
class _Avatar extends StatelessWidget {
  final Patient patient;
  const _Avatar({required this.patient});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFFF5A962), Color(0xFFF08030)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF08030).withOpacity(0.28),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(2.5),
      child: ClipOval(
        child: Image.network(
          'https://ui-avatars.com/api/?name=${patient.firstName}+${patient.lastName}'
          '&background=F5A962&color=ffffff&size=200&bold=true',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Icon(
            Icons.person_rounded,
            size: 32,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

// ─── Tag Badge ─────────────────────────────────────────────────────────────
class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  const _Tag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

// ─── Info Tile ─────────────────────────────────────────────────────────────
class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool fullWidth;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8E8ED), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFF08030).withOpacity(0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 15, color: const Color(0xFFF08030)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF6C6C70),
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value.isNotEmpty ? value : 'N/A',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1C1C1E),
                    letterSpacing: -0.1,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}