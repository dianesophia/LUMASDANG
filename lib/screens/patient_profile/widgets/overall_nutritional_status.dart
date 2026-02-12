import 'package:flutter/material.dart';

/// Widget displaying an Overall Nutritional Status summary card
/// based on the latest assessment data (Weight-for-Age, Height-for-Age, MUAC, Risk Classification).
class OverallNutritionalStatusSection extends StatelessWidget {
  final List<Map<String, dynamic>> assessments;
  final VoidCallback? onReturnToDashboard;

  const OverallNutritionalStatusSection({
    super.key,
    required this.assessments,
    this.onReturnToDashboard,
  });

  /// Get the most recent assessment that has anthropometric data
  Map<String, dynamic>? _getLatestAssessment() {
    if (assessments.isEmpty) return null;
    // Assessments are sorted ascending by date, so last one is most recent
    for (var i = assessments.length - 1; i >= 0; i--) {
      final a = assessments[i];
      if ((a['weightForAge'] ?? '').toString().isNotEmpty ||
          (a['heightForAge'] ?? '').toString().isNotEmpty ||
          (a['muac'] ?? '').toString().isNotEmpty) {
        return a;
      }
    }
    return null;
  }

  /// Format a DateTime for display
  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day.toString().padLeft(2, '0')}, ${date.year}';
  }

  /// Extract the interpretation text from a z-score string like "-1.50 (Underweight)"
  String _extractInterpretation(String? zScoreStr) {
    if (zScoreStr == null || zScoreStr.isEmpty) return '';
    final match = RegExp(r'\(([^)]+)\)').firstMatch(zScoreStr);
    return match?.group(1) ?? '';
  }

  /// Extract the z-score value from a z-score string like "-1.50 (Underweight)"
  double? _extractZScore(String? zScoreStr) {
    if (zScoreStr == null || zScoreStr.isEmpty) return null;
    final match = RegExp(r'^-?[\d.]+').firstMatch(zScoreStr.trim());
    if (match != null) {
      return double.tryParse(match.group(0)!);
    }
    return null;
  }

  /// Get a friendly Weight-for-Age description
  String _getWeightForAgeStatus(String? wfa) {
    final interp = _extractInterpretation(wfa);
    if (interp.isEmpty) return '';
    return '$interp (Weight-for-Age)';
  }

  /// Get a friendly Height-for-Age description
  String _getHeightForAgeStatus(String? hfa) {
    final interp = _extractInterpretation(hfa);
    if (interp.isEmpty) return '';

    // Map interpretation to friendly text matching the design
    switch (interp.toLowerCase()) {
      case 'severely stunted':
        return 'Severely Stunted (Height-for-Age)';
      case 'stunted':
        return 'Stunted (Height-for-Age)';
      case 'normal':
        return 'Normal Height (Height-for-Age)';
      default:
        return '$interp (Height-for-Age)';
    }
  }

  /// Get MUAC classification based on the value
  /// WHO guidelines for children 6-59 months:
  /// < 11.5 cm = Severe Acute Malnutrition (SAM)
  /// 11.5–12.4 cm = Moderate Acute Malnutrition (MAM)
  /// 12.5–13.4 cm = At Risk
  /// >= 13.5 cm = Normal
  String _getMuacStatus(String? muacStr) {
    if (muacStr == null || muacStr.isEmpty) return '';
    final muac = double.tryParse(muacStr.trim());
    if (muac == null) return '';

    String classification;
    if (muac < 11.5) {
      classification = 'SAM';
    } else if (muac < 12.5) {
      classification = 'MAM';
    } else if (muac < 13.5) {
      classification = 'At Risk';
    } else {
      classification = 'Normal';
    }

    return 'MUAC $classification ($muac cm)';
  }

  /// Determine overall nutritional risk classification
  /// Based on the combination of all indicators
  _RiskLevel _calculateRiskClassification(Map<String, dynamic> assessment) {
    final wfaInterp = _extractInterpretation(assessment['weightForAge']?.toString());
    final hfaInterp = _extractInterpretation(assessment['heightForAge']?.toString());
    final wfhInterp = _extractInterpretation(assessment['weightForHeight']?.toString());
    final muacStr = assessment['muac']?.toString() ?? '';
    final muac = double.tryParse(muacStr.trim());

    bool hasSevere = false;
    bool hasModerate = false;

    // Check for severe conditions
    final severeTerms = ['severely underweight', 'severely stunted', 'severe wasting', 'obese'];
    final moderateTerms = ['underweight', 'stunted', 'wasted', 'overweight', 'at risk of overweight'];

    for (final interp in [wfaInterp, hfaInterp, wfhInterp]) {
      final lower = interp.toLowerCase();
      if (severeTerms.any((t) => lower.contains(t))) {
        hasSevere = true;
      } else if (moderateTerms.any((t) => lower == t)) {
        hasModerate = true;
      }
    }

    // Check MUAC
    if (muac != null) {
      if (muac < 11.5) {
        hasSevere = true;
      } else if (muac < 13.5) {
        hasModerate = true;
      }
    }

    if (hasSevere) {
      return _RiskLevel.high;
    } else if (hasModerate) {
      return _RiskLevel.moderate;
    } else {
      return _RiskLevel.low;
    }
  }

  @override
  Widget build(BuildContext context) {
    final latest = _getLatestAssessment();

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
              'No assessment data available yet.',
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

    final date = latest['date'] as DateTime?;
    final wfaStatus = _getWeightForAgeStatus(latest['weightForAge']?.toString());
    final hfaStatus = _getHeightForAgeStatus(latest['heightForAge']?.toString());
    final muacStatus = _getMuacStatus(latest['muac']?.toString());
    final riskLevel = _calculateRiskClassification(latest);

    // Collect all non-empty status items
    final statusItems = <_StatusItem>[];

    if (wfaStatus.isNotEmpty) {
      final wfaInterp = _extractInterpretation(latest['weightForAge']?.toString()).toLowerCase();
      statusItems.add(_StatusItem(
        text: wfaStatus,
        severity: wfaInterp.contains('severe')
            ? _Severity.severe
            : (wfaInterp == 'normal' ? _Severity.normal : _Severity.warning),
      ));
    }

    if (hfaStatus.isNotEmpty) {
      final hfaInterp = _extractInterpretation(latest['heightForAge']?.toString()).toLowerCase();
      statusItems.add(_StatusItem(
        text: hfaStatus,
        severity: hfaInterp.contains('severe')
            ? _Severity.severe
            : (hfaInterp == 'normal' ? _Severity.normal : _Severity.warning),
      ));
    }

    if (muacStatus.isNotEmpty) {
      final muac = double.tryParse(latest['muac']?.toString().trim() ?? '');
      _Severity muacSeverity = _Severity.normal;
      if (muac != null) {
        if (muac < 11.5) {
          muacSeverity = _Severity.severe;
        } else if (muac < 13.5) {
          muacSeverity = _Severity.warning;
        }
      }
      statusItems.add(_StatusItem(
        text: muacStatus,
        severity: muacSeverity,
      ));
    }

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
          // Title bar
          _buildTitleBar(),
          const SizedBox(height: 6),

          // Last Assessment date
          Center(
            child: Text(
              'Last Assessment: ${_formatDate(date)}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF2E8B7B),
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Status items with checkmarks
          ...statusItems.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 12, left: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.check,
                      size: 20,
                      color: _getSeverityColor(item.severity),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item.text,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black.withOpacity(0.8),
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              )),

          // Risk Classification
          Padding(
            padding: const EdgeInsets.only(bottom: 4, left: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.check,
                  size: 20,
                  color: _getRiskColor(riskLevel),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'Risk Classification:\n',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black.withOpacity(0.8),
                            height: 1.4,
                          ),
                        ),
                        TextSpan(
                          text: _getRiskLabel(riskLevel),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: _getRiskColor(riskLevel),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Return to Dashboard button
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

  Widget _buildTitleBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFD4F1E3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Text(
          'Overall Nutritional Status',
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

  Color _getSeverityColor(_Severity severity) {
    switch (severity) {
      case _Severity.normal:
        return const Color(0xFF4CAF50);
      case _Severity.warning:
        return const Color(0xFFFF9800);
      case _Severity.severe:
        return const Color(0xFFE53935);
    }
  }

  Color _getRiskColor(_RiskLevel risk) {
    switch (risk) {
      case _RiskLevel.low:
        return const Color(0xFF4CAF50);
      case _RiskLevel.moderate:
        return const Color(0xFFFF9800);
      case _RiskLevel.high:
        return const Color(0xFFE53935);
    }
  }

  String _getRiskLabel(_RiskLevel risk) {
    switch (risk) {
      case _RiskLevel.low:
        return 'Low Nutritional Risk';
      case _RiskLevel.moderate:
        return 'Moderate Nutritional Risk';
      case _RiskLevel.high:
        return 'High Nutritional Risk';
    }
  }
}

enum _RiskLevel { low, moderate, high }

enum _Severity { normal, warning, severe }

class _StatusItem {
  final String text;
  final _Severity severity;

  _StatusItem({required this.text, required this.severity});
}
