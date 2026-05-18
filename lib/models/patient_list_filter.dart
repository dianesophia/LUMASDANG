import 'package:lumasdang/services/nutrition_status_classifier.dart';

/// External filter applied when navigating from the dashboard (or elsewhere).
class PatientListFilter {
  final String? malnutritionType;
  final String? screenedPeriod;
  final String? sex;
  final NutritionCategory? nutritionCategory;

  const PatientListFilter({
    this.malnutritionType,
    this.screenedPeriod,
    this.sex,
    this.nutritionCategory,
  });

  /// Maps dashboard analytics categories to patient-list remark labels when possible.
  static String? malnutritionLabelFor(NutritionCategory category) {
    switch (category) {
      case NutritionCategory.stunting:
        return 'Stunted';
      case NutritionCategory.underweight:
        return 'Underweight';
      case NutritionCategory.overweight:
      case NutritionCategory.obese:
        return 'Overweight/Obese';
      case NutritionCategory.atRisk:
        return 'At Risk';
      case NutritionCategory.normal:
        return 'Normal';
      case NutritionCategory.wasting:
      case NutritionCategory.severeCases:
        return null;
    }
  }
}
