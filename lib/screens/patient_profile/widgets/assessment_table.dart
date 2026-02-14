import 'package:flutter/material.dart';
import '../../../services/assessment_service.dart';

/// Assessment table widget displaying patient assessments
class AssessmentTable extends StatelessWidget {
  final List<Map<String, dynamic>> assessments;
  final String patientId;
  final bool loading;
  final VoidCallback onAddAssessment;
   final Future<void> Function(Map<String, dynamic>, String patientId)? saveNewAssessment;

  const AssessmentTable({
    super.key,
    required this.patientId, // new
    required this.assessments,
    required this.loading,
    required this.onAddAssessment,
    this.saveNewAssessment, 
  });

  String _getClassification(Map<String, dynamic> assessment) {
    final wfa = assessment['weightForAge']?.toString().toLowerCase() ?? '';
    final hfa = assessment['heightForAge']?.toString().toLowerCase() ?? '';
    final wfh = assessment['weightForHeight']?.toString().toLowerCase() ?? '';

    if (wfa.contains('severely') ||
        hfa.contains('severely') ||
        wfh.contains('severely')) {
      return 'Severely Underweight';
    }
    if (wfa.contains('underweight') ||
        hfa.contains('stunted') ||
        wfh.contains('wasted')) {
      return 'At risk';
    }
    if (wfa.contains('overweight') || wfh.contains('overweight')) {
      return 'Overweight';
    }
    if (wfa.contains('normal') || wfa.isEmpty) {
      return 'Normal';
    }
    return 'Normal';
  }

  Color _getClassificationColor(String classification) {
    switch (classification.toLowerCase()) {
      case 'at risk':
        return const Color(0xFFFF9800);
      case 'severely underweight':
        return const Color(0xFFE53935);
      case 'overweight':
        return const Color(0xFFFF9800);
      case 'normal':
        return const Color(0xFF4CAF50);
      default:
        return const Color(0xFF333333);
    }
  }

  Color _getRowColor(String classification) {
    switch (classification.toLowerCase()) {
      case 'at risk':
        return const Color(0xFFFFE0B2); // light orange
      case 'severely underweight':
        return const Color(0xFFFFCDD2); // light red
      case 'overweight':
        return const Color(0xFFFFF9C4); // light yellow
      case 'normal':
        return const Color(0xFFC8E6C9); // light green
      default:
        return const Color(0xFFF5F5F5);
    }
  }

  String _formatDateShort(DateTime? date) {
    if (date == null) return '--';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: loading
          ? const Padding(
              padding: EdgeInsets.all(48),
              child: Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF2E8B7B),
                    strokeWidth: 3,
                  )),
            )
          : Column(
              children: [
                // Table header
                _buildTableHeader(),
                // Table rows
                if (assessments.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(
                          Icons.assessment_outlined,
                          size: 48,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No assessments found',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                else ...[
                  const SizedBox(height: 8),
                  ...assessments.map((a) => _buildTableRow(a)),
                  const SizedBox(height: 8),
                ],
                
                // Add New Assessment Button
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onAddAssessment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E8B7B),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        elevation: 2,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.add_circle_outline, size: 22),
                          SizedBox(width: 8),
                          Text(
                            'Add New Assessment',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFFF5A962),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: const Row(
        children: [
          Expanded(
            flex: 2,
            child: Text('Date',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center),
          ),
          Expanded(
            flex: 2,
            child: Text('Height',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center),
          ),
          Expanded(
            flex: 2,
            child: Text('Weight',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center),
          ),
          Expanded(
            flex: 2,
            child: Text('MUAC',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center),
          ),
          Expanded(
            flex: 3,
            child: Text('Classification',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center),
          ),
        ],
      ),
    );
  }

  Widget _buildTableRow(Map<String, dynamic> assessment) {
    final classification = _getClassification(assessment);
    final rowColor = _getRowColor(classification);
    final date = assessment['date'] as DateTime?;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      decoration: BoxDecoration(
        color: rowColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              _formatDateShort(date),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              assessment['height']?.toString() ?? '--',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              assessment['weight']?.toString() ?? '--',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              assessment['muac']?.toString() ?? '--',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              classification,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: _getClassificationColor(classification),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}


