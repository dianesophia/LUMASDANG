import 'package:flutter/material.dart';

/// Widget displaying the Deworming Status card in the patient profile.
/// Shows medication given, dosage, deworming recency, and health outcomes.
class DewormingStatusSection extends StatelessWidget {
  final List<Map<String, dynamic>> assessments;
  final VoidCallback? onReturnToDashboard;

  const DewormingStatusSection({
    super.key,
    required this.assessments,
    this.onReturnToDashboard,
  });

  /// Get the most recent assessment with deworming data
  Map<String, dynamic>? _getLatestDeworming() {
    if (assessments.isEmpty) return null;
    for (var i = assessments.length - 1; i >= 0; i--) {
      final a = assessments[i];
      final deworming = a['deworming'] as Map<String, dynamic>?;
      if (deworming != null) return a;
    }
    return null;
  }

  /// Parse a date string (MM/DD/YYYY or YYYY-MM-DD) into a DateTime
  DateTime? _parseDate(String? dateStr) {
    if (dateStr == null || dateStr.trim().isEmpty) return null;
    try {
      final slashParts = dateStr.split('/');
      if (slashParts.length == 3) {
        final month = int.tryParse(slashParts[0]);
        final day = int.tryParse(slashParts[1]);
        final year = int.tryParse(slashParts[2]);
        if (month != null && day != null && year != null) {
          return DateTime(year, month, day);
        }
      }
      return DateTime.tryParse(dateStr);
    } catch (_) {
      return null;
    }
  }

  /// Format a DateTime for display (e.g. "December 15, 2025")
  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${months[date.month - 1]} ${date.day.toString().padLeft(2, '0')}, ${date.year}';
  }

  /// Check if last deworming was within the last 6 months
  bool _isDewormingRecent(DateTime? dewormDate) {
    if (dewormDate == null) return false;
    final sixMonthsAgo = DateTime.now().subtract(const Duration(days: 183));
    return dewormDate.isAfter(sixMonthsAgo);
  }

  /// Determine dosage description based on drug given
  String _getDosageDescription(String? drugGiven) {
    if (drugGiven == null || drugGiven.isEmpty) return '';
    // Standard DOH/WHO dosage for children:
    // Albendazole 400mg single dose (≥2 yrs), 200mg (<2 yrs)
    // Mebendazole 500mg single dose
    return 'Age-appropriate single dose';
  }

  @override
  Widget build(BuildContext context) {
    final latest = _getLatestDeworming();

    if (latest == null) {
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
        child: Column(
          children: [
            _buildTitleBar(),
            const SizedBox(height: 16),
            const Text(
              'No deworming data available yet.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    }

    final deworming = latest['deworming'] as Map<String, dynamic>;
    final isNA = deworming['isNA'] == true;
    final drugGiven = deworming['drugGiven']?.toString() ?? '';
    final dateOfLastDeworming = deworming['dateOfLastDeworming']?.toString() ?? '';
    final adverseReactions = deworming['adverseReactions']?.toString() ?? '';
    final dewormDate = _parseDate(dateOfLastDeworming);
    final isRecent = _isDewormingRecent(dewormDate);
    final dosage = _getDosageDescription(drugGiven);

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Title bar ──
          _buildTitleBar(),
          const SizedBox(height: 6),

          // ── Last Deworming Date ──
          Center(
            child: Text(
              'Last Deworming Date: ${_formatDate(dewormDate)}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF2E8B7B),
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          const SizedBox(height: 18),

          // ── Medication Given ──
          if (!isNA && drugGiven.isNotEmpty) ...[
            _buildCheckItem(
              text: 'Medication Given:\n$drugGiven',
              severity: _Severity.normal,
            ),
            const SizedBox(height: 12),
          ],

          // ── Dosage ──
          if (!isNA && dosage.isNotEmpty) ...[
            _buildCheckItem(
              text: 'Dosage: $dosage',
              severity: _Severity.normal,
            ),
            const SizedBox(height: 10),
          ],

          // ── N/A indicator ──
          if (isNA) ...[
            _buildCheckItem(
              text: 'Deworming: Not Applicable',
              severity: _Severity.info,
            ),
            const SizedBox(height: 10),
          ],

          // ── Health outcome bullets ──
          if (!isNA) ...[
            // Deworming recency
            _buildBulletItem(
              text: isRecent
                  ? 'Dewormed within last 6 months'
                  : 'Last deworming was more than 6 months ago',
              isPositive: isRecent,
            ),
            const SizedBox(height: 6),

            // Adverse reactions / symptoms
            _buildBulletItem(
              text: adverseReactions.isEmpty
                  ? 'No symptoms of intestinal worms'
                  : 'Adverse reactions: $adverseReactions',
              isPositive: adverseReactions.isEmpty,
            ),
            const SizedBox(height: 6),

            // Appetite / weight outcome
            _buildBulletItem(
              text: _getWeightOutcome(),
              isPositive: true,
            ),
          ],

          const SizedBox(height: 20),

          // ── Return to Dashboard ──
          Center(
            child: ElevatedButton(
              onPressed: onReturnToDashboard,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF5A962),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                elevation: 3,
              ),
              child: const Text(
                'Return to Dashboard',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Derive a weight / appetite outcome from weight trend in assessments
  String _getWeightOutcome() {
    if (assessments.length < 2) return 'Good appetite and weight maintenance';
    // Compare latest two weights
    final latestWeight = double.tryParse(
        assessments.last['weight']?.toString().trim() ?? '');
    final prevWeight = double.tryParse(
        assessments[assessments.length - 2]['weight']?.toString().trim() ?? '');
    if (latestWeight != null && prevWeight != null) {
      if (latestWeight >= prevWeight) {
        return 'Good appetite and weight maintenance';
      } else {
        return 'Slight weight decrease – monitor appetite';
      }
    }
    return 'Good appetite and weight maintenance';
  }

  Widget _buildTitleBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFD4F1E3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Text(
          'Deworming Status',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildCheckItem({
    required String text,
    required _Severity severity,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check,
            size: 20,
            color: _getSeverityColor(severity),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              _buildBoldFirstLine(text),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black.withOpacity(0.8),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Makes the first segment before '\n' bold and the rest regular weight
  TextSpan _buildBoldFirstLine(String text) {
    final parts = text.split('\n');
    if (parts.length <= 1) {
      return TextSpan(text: text);
    }
    return TextSpan(
      children: [
        TextSpan(
          text: '${parts[0]}\n',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        TextSpan(
          text: parts.sublist(1).join('\n'),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildBulletItem({required String text, required bool isPositive}) {
    return Padding(
      padding: const EdgeInsets.only(left: 34),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '•  ',
            style: TextStyle(
              fontSize: 14,
              color: Colors.black.withOpacity(0.7),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isPositive
                    ? Colors.black.withOpacity(0.75)
                    : const Color(0xFFE65100),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getSeverityColor(_Severity severity) {
    switch (severity) {
      case _Severity.normal:
        return const Color(0xFF4CAF50);
      case _Severity.warning:
        return const Color(0xFFFF9800);
      case _Severity.info:
        return const Color(0xFF2E8B7B);
    }
  }
}

enum _Severity { normal, warning, info }
