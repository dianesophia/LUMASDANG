import 'package:flutter/material.dart';

const Map<String, Color> kStatusColors = {
  'Underweight':      Color(0xFFE57373), // red
  'Stunted':          Color(0xFFE57373), // red
  'Overweight/Obese': Color(0xFFFFB74D), // orange
  'At Risk':          Color(0xFFFFD54F), // amber
  'Normal':           Color(0xFF66BB6A), // green
  'No assessments':   Colors.grey,
  'Assessment done':  Color(0xFF4DB6AC), // teal
};

Color getStatusColor(String remarks) {
  final r = remarks.trim().toLowerCase();
  if (r.contains('underweight') || r.contains('stunted')) {
    return kStatusColors['Underweight']!;
  }
  if (r.contains('overweight') || r.contains('obese')) {
    return kStatusColors['Overweight/Obese']!;
  }
  if (r.contains('at risk')) {
    return kStatusColors['At Risk']!;
  }
  if (r == 'normal') return kStatusColors['Normal']!;
  if (r == 'no assessments') return kStatusColors['No assessments']!;
  return kStatusColors['Assessment done']!;
}