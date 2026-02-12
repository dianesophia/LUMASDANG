import 'package:flutter/material.dart';
import '../../patient_list.dart';

/// Patient information card with avatar and details
class ProfileInfoCard extends StatelessWidget {
  final Patient patient;

  const ProfileInfoCard({
    super.key,
    required this.patient,
  });

  Widget _buildInfoRow(String label, String value) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A3C34),
            ),
          ),
          TextSpan(
            text: value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF2A4F47),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
          // ── Name header pill ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              '${patient.firstName.toUpperCase()} ${patient.lastName.toUpperCase()}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A3C34),
                letterSpacing: 1.2,
              ),
            ),
          ),

          // ── Avatar + Info ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(
                      color: const Color(0xFF7FBFB3),
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.network(
                      'https://ui-avatars.com/api/?name=${patient.firstName}+${patient.lastName}&background=7FBFB3&color=1A3C34&size=200',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.person,
                          size: 50,
                          color: Color(0xFF7FBFB3),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Info column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow(
                        'Address',
                        patient.address.isNotEmpty ? patient.address : 'N/A',
                      ),
                      const SizedBox(height: 10),
                      _buildInfoRow(
                        'Birthdate',
                        patient.dateOfBirth.isNotEmpty ? patient.dateOfBirth : 'N/A',
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _buildInfoRow('Age', '${patient.age}'),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildInfoRow(
                              'Sex',
                              patient.sex.isNotEmpty ? patient.sex : 'N/A',
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
        ],
      ),
    );
  }
}
