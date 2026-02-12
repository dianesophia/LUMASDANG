import 'package:flutter/material.dart';

/// Widget displaying Health Status, Dietary Status, and Oral Status sections
class StatusSections extends StatelessWidget {
  final List<Map<String, dynamic>> assessments;

  const StatusSections({
    super.key,
    required this.assessments,
  });

  /// Get the most recent health status summary
  String _getHealthStatusSummary() {
    if (assessments.isEmpty) return 'No health data available';

    // Get the most recent assessment with health status
    for (var i = assessments.length - 1; i >= 0; i--) {
      final assessment = assessments[i];
      final healthStatus = assessment['healthStatus'] as Map<String, dynamic>?;
      if (healthStatus != null) {
        final diarrhea = healthStatus['diarrhea'] == true;
        final fever = healthStatus['fever'] == true;
        final cough = healthStatus['cough'] == true;
        final other = healthStatus['other'] == true;
        final medications = healthStatus['medications'] == true;

        final issues = <String>[];
        if (diarrhea) issues.add('diarrhea');
        if (fever) issues.add('fever');
        if (cough) issues.add('cough');
        if (other) issues.add('other illness');
        if (medications) issues.add('on medications');

        if (issues.isEmpty) {
          return 'No current illness';
        } else if (issues.length == 1) {
          return 'Current: ${issues[0]}';
        } else {
          return 'Current: ${issues.join(', ')}';
        }
      }
    }

    return 'No health data available';
  }

  /// Get the most recent dietary status summary
  String _getDietaryStatusSummary() {
    if (assessments.isEmpty) return 'No dietary data available';

    // Get the most recent assessment with dietary data
    for (var i = assessments.length - 1; i >= 0; i--) {
      final assessment = assessments[i];
      final dietary = assessment['dietary'] as Map<String, dynamic>?;
      if (dietary != null) {
        final purelyBreastfed = dietary['purelyBreastfed'];
        final cfAge = dietary['cfAge']?.toString() ?? '';
        final mealFreq = dietary['mealFrequency']?.toString() ?? '';

        if (purelyBreastfed == true) {
          return 'Purely breastfed';
        } else if (purelyBreastfed == false) {
          final parts = <String>[];
          if (cfAge.isNotEmpty) parts.add('CF started at $cfAge months');
          if (mealFreq.isNotEmpty) parts.add('$mealFreq meals/day');
          
          if (parts.isEmpty) {
            return 'Complementary feeding';
          }
          return parts.join(', ');
        }
      }
    }

    return 'No dietary data available';
  }

  /// Get the most recent oral status summary
  String _getOralStatusSummary() {
    if (assessments.isEmpty) return 'No oral assessment data';

    // Get the most recent assessment with oral data
    for (var i = assessments.length - 1; i >= 0; i--) {
      final assessment = assessments[i];
      final oral = assessment['oral'] as Map<String, dynamic>?;
      if (oral != null) {
        final overallRisk = oral['overallRisk']?.toString() ?? '';
        if (overallRisk.isNotEmpty) {
          return '${overallRisk} risk for caries';
        }
      }
    }

    return 'No oral assessment data';
  }

  /// Count how many assessments have health status data
  int _getHealthHistoryCount() {
    return assessments.where((a) => a['healthStatus'] != null).length;
  }

  /// Count how many assessments have dietary data
  int _getDietaryDataCount() {
    return assessments.where((a) => a['dietary'] != null).length;
  }

  /// Count how many assessments have oral data
  int _getOralDataCount() {
    return assessments.where((a) => a['oral'] != null).length;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _StatusCard(
          title: 'Health Status',
          statusText: _getHealthStatusSummary(),
          primaryButtonText: 'History',
          dataCount: _getHealthHistoryCount(),
          onPrimaryPressed: () {
            _showHealthHistory(context);
          },
        ),
        const SizedBox(height: 16),
        _StatusCard(
          title: 'Dietary Status',
          statusText: _getDietaryStatusSummary(),
          primaryButtonText: 'Details',
          dataCount: _getDietaryDataCount(),
          onPrimaryPressed: () {
            _showDietaryDetails(context);
          },
        ),
        const SizedBox(height: 16),
        _StatusCard(
          title: 'Oral Status',
          statusText: _getOralStatusSummary(),
          primaryButtonText: 'Details',
          dataCount: _getOralDataCount(),
          onPrimaryPressed: () {
            _showOralDetails(context);
          },
        ),
      ],
    );
  }

  void _showHealthHistory(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _HealthHistorySheet(assessments: assessments),
    );
  }

  void _showDietaryDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _DietaryDetailsSheet(assessments: assessments),
    );
  }

  void _showOralDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _OralDetailsSheet(assessments: assessments),
    );
  }
}

/// Individual status card widget
class _StatusCard extends StatelessWidget {
  final String title;
  final String statusText;
  final String primaryButtonText;
  final int dataCount;
  final VoidCallback onPrimaryPressed;

  const _StatusCard({
    required this.title,
    required this.statusText,
    required this.primaryButtonText,
    required this.dataCount,
    required this.onPrimaryPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFB8E6D5), // Light teal/mint color
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
          // Title
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFD4F1E3), // Slightly lighter background
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Status text with bullet point
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '• ',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
                Expanded(
                  child: Text(
                    statusText,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Button with data count badge
          Center(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                ElevatedButton(
                  onPressed: dataCount > 0 ? onPrimaryPressed : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[600],
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey[400],
                    disabledForegroundColor: Colors.white70,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 2,
                  ),
                  child: Text(
                    primaryButtonText,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (dataCount > 0)
                  Positioned(
                    right: -6,
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF5A962),
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 20,
                        minHeight: 20,
                      ),
                      child: Center(
                        child: Text(
                          '$dataCount',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
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

// ==================== HEALTH HISTORY SHEET ====================
class _HealthHistorySheet extends StatelessWidget {
  final List<Map<String, dynamic>> assessments;

  const _HealthHistorySheet({required this.assessments});

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown date';
    return '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    // Filter assessments with health status data and reverse for newest first
    final healthAssessments = assessments
        .where((a) => a['healthStatus'] != null)
        .toList()
        .reversed
        .toList();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
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
              'Health Status History',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E8B7B),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // List
          Flexible(
            child: healthAssessments.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(32),
                    child: Text(
                      'No health status data available',
                      style: TextStyle(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    itemCount: healthAssessments.length,
                    separatorBuilder: (_, __) => const Divider(height: 24),
                    itemBuilder: (ctx, index) {
                      final assessment = healthAssessments[index];
                      final date = assessment['date'] as DateTime?;
                      final healthStatus =
                          assessment['healthStatus'] as Map<String, dynamic>?;

                      if (healthStatus == null) return const SizedBox.shrink();

                      final diarrhea = healthStatus['diarrhea'] == true;
                      final fever = healthStatus['fever'] == true;
                      final cough = healthStatus['cough'] == true;
                      final other = healthStatus['other'] == true;
                      final medications = healthStatus['medications'] == true;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatDate(date),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2E8B7B),
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (!diarrhea && !fever && !cough && !other)
                            const Text(
                              '• No current illness',
                              style: TextStyle(fontSize: 13, color: Colors.black87),
                            )
                          else ...[
                            if (diarrhea)
                              const Text('• Diarrhea',
                                  style: TextStyle(fontSize: 13, color: Colors.black87)),
                            if (fever)
                              const Text('• Fever',
                                  style: TextStyle(fontSize: 13, color: Colors.black87)),
                            if (cough)
                              const Text('• Cough',
                                  style: TextStyle(fontSize: 13, color: Colors.black87)),
                            if (other)
                              const Text('• Other illness',
                                  style: TextStyle(fontSize: 13, color: Colors.black87)),
                          ],
                          if (medications)
                            const Text('• Currently on medications',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w600)),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ==================== DIETARY DETAILS SHEET ====================
class _DietaryDetailsSheet extends StatelessWidget {
  final List<Map<String, dynamic>> assessments;

  const _DietaryDetailsSheet({required this.assessments});

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown date';
    return '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    // Filter assessments with dietary data and reverse for newest first
    final dietaryAssessments = assessments
        .where((a) => a['dietary'] != null)
        .toList()
        .reversed
        .toList();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
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
              'Dietary Status Details',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E8B7B),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // List
          Flexible(
            child: dietaryAssessments.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(32),
                    child: Text(
                      'No dietary data available',
                      style: TextStyle(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    itemCount: dietaryAssessments.length,
                    separatorBuilder: (_, __) => const Divider(height: 24),
                    itemBuilder: (ctx, index) {
                      final assessment = dietaryAssessments[index];
                      final date = assessment['date'] as DateTime?;
                      final dietary =
                          assessment['dietary'] as Map<String, dynamic>?;

                      if (dietary == null) return const SizedBox.shrink();

                      final purelyBreastfed = dietary['purelyBreastfed'];
                      final cfAge = dietary['cfAge']?.toString() ?? '';
                      final cfFreq = dietary['cfFrequency']?.toString() ?? '';
                      final cfFoods = dietary['cfFoods']?.toString() ?? '';
                      final mealFreq = dietary['mealFrequency']?.toString() ?? '';

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatDate(date),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2E8B7B),
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (purelyBreastfed == true)
                            const Text('• Purely breastfed',
                                style: TextStyle(fontSize: 13, color: Colors.black87))
                          else if (purelyBreastfed == false) ...[
                            const Text('• Complementary feeding',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87)),
                            if (cfAge.isNotEmpty)
                              Text('  - Started at: $cfAge months',
                                  style: const TextStyle(fontSize: 13, color: Colors.black87)),
                            if (cfFreq.isNotEmpty)
                              Text('  - Frequency: $cfFreq times/day',
                                  style: const TextStyle(fontSize: 13, color: Colors.black87)),
                            if (cfFoods.isNotEmpty)
                              Text('  - Foods: $cfFoods',
                                  style: const TextStyle(fontSize: 13, color: Colors.black87)),
                            if (mealFreq.isNotEmpty)
                              Text('  - Meal frequency: $mealFreq times/day',
                                  style: const TextStyle(fontSize: 13, color: Colors.black87)),
                          ] else
                            const Text('• No breastfeeding information',
                                style: TextStyle(fontSize: 13, color: Colors.grey)),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ==================== ORAL DETAILS SHEET ====================
class _OralDetailsSheet extends StatelessWidget {
  final List<Map<String, dynamic>> assessments;

  const _OralDetailsSheet({required this.assessments});

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown date';
    return '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}';
  }

  Color _getRiskColor(String risk) {
    switch (risk.toLowerCase()) {
      case 'high':
        return const Color(0xFFE53935);
      case 'moderate':
        return const Color(0xFFFF9800);
      case 'low':
        return const Color(0xFFFFEB3B);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Filter assessments with oral data and reverse for newest first
    final oralAssessments = assessments
        .where((a) => a['oral'] != null)
        .toList()
        .reversed
        .toList();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
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
              'Oral Status Details',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E8B7B),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // List
          Flexible(
            child: oralAssessments.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(32),
                    child: Text(
                      'No oral assessment data available',
                      style: TextStyle(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    itemCount: oralAssessments.length,
                    separatorBuilder: (_, __) => const Divider(height: 24),
                    itemBuilder: (ctx, index) {
                      final assessment = oralAssessments[index];
                      final date = assessment['date'] as DateTime?;
                      final oral = assessment['oral'] as Map<String, dynamic>?;

                      if (oral == null) return const SizedBox.shrink();

                      final overallRisk = oral['overallRisk']?.toString() ?? '';

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatDate(date),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2E8B7B),
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (overallRisk.isNotEmpty)
                            Row(
                              children: [
                                const Text('• Overall Risk: ',
                                    style: TextStyle(fontSize: 13, color: Colors.black87)),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _getRiskColor(overallRisk),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    overallRisk,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          else
                            const Text('• No risk assessment available',
                                style: TextStyle(fontSize: 13, color: Colors.grey)),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
