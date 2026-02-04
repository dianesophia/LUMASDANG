import 'package:flutter/material.dart';
import 'package:lumasdang/screens/patient_list.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedNavIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2E8B7B),
              Color(0xFF5CAA7F),
              Color(0xFF8BC88A),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildHomeTab(),
                    _buildPatientListTab(),
                    _buildNotificationsTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(25),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: const Color(0xFF2E8B7B),
        unselectedLabelColor: Colors.white,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        unselectedLabelStyle: const TextStyle(fontSize: 14),
        tabs: const [
          Tab(text: 'Home'),
          Tab(text: 'Patient List'),
          Tab(text: 'Notifications'),
        ],
      ),
    );
  }

  Widget _buildHomeTab() {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StatsRow(),
          SizedBox(height: 16),
          UpcomingEvents(),
          SizedBox(height: 20),
          Text(
            'NEW ASSESSMENT',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(height: 12),
          DemographicDataForm(),
          SizedBox(height: 16),
          AnthropometricDataForm(),
          SizedBox(height: 16),
          HealthStatusForm(),
          SizedBox(height: 16),
          DietaryAssessmentForm(),
          SizedBox(height: 16),
          OralAssessmentForm(),
          SizedBox(height: 16),
          VaccinationForm(),
          SizedBox(height: 16),
          DewormingForm(),
          SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildPatientListTab() {
    return const PatientListTab();
  }

  Widget _buildNotificationsTab() {
    return const Center(
      child: Text(
        'Notifications',
        style: TextStyle(
          fontSize: 24,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5CAA7F), Color(0xFF8BC88A)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.calendar_month, 0),
              _buildNavItem(Icons.assignment, 1),
              _buildNavItem(Icons.people, 2),
              _buildNavItem(Icons.settings, 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index) {
    final isSelected = _selectedNavIndex == index;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedNavIndex = index;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withValues(alpha: 0.3)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }
}


// ==================== STATS ROW ====================
class StatsRow extends StatelessWidget {
  const StatsRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5A962),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '16',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'No. of patient',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        'screened today',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        'January 8, 2026',
                        style: TextStyle(
                          fontSize: 9,
                          color: Color(0xFFF5A962),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                StatusRow(count: '0', label: 'Underweight'),
                SizedBox(height: 2),
                StatusRow(count: '1', label: 'Overweight/', subtitle: 'Obese'),
                SizedBox(height: 2),
                StatusRow(count: '2', label: 'Stunted'),
                SizedBox(height: 2),
                StatusRow(count: '3', label: 'At Risk'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class StatusRow extends StatelessWidget {
  final String count;
  final String label;
  final String? subtitle;

  const StatusRow({
    super.key,
    required this.count,
    required this.label,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFF5A962),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            count,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ==================== UPCOMING EVENTS ====================
class UpcomingEvents extends StatelessWidget {
  const UpcomingEvents({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF5A962),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.calendar_month,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'UPCOMING EVENTS',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFF5A962),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '• Operation Timbang',
                  style: TextStyle(fontSize: 11, color: Colors.black87),
                ),
                Text(
                  '• Deworming',
                  style: TextStyle(fontSize: 11, color: Colors.black87),
                ),
                Text(
                  '• Operation Bunot',
                  style: TextStyle(fontSize: 11, color: Colors.black87),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== FORM CARD WIDGET ====================
class FormCard extends StatelessWidget {
  final String title;
  final Widget child;

  const FormCard({super.key, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5A962),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF8B4513),
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

// ==================== FORM FIELD WIDGETS ====================
class FormFieldRow extends StatelessWidget {
  final String label;
  final String? hint;
  final double labelWidth;
  final TextEditingController? controller;

  const FormFieldRow({
    super.key,
    required this.label,
    this.hint,
    this.labelWidth = 100,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: labelWidth,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF5D4037),
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 32,
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Color(0xFF8B6914),
                  width: 1.5,
                ),
              ),
            ),
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: hint,
                hintStyle: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF8B6914),
                  fontStyle: FontStyle.italic,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                isDense: true,
              ),
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF5D4037),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class CheckboxFieldRow extends StatefulWidget {
  final String label;
  final String? hint;
  final bool initialValue;
  final ValueChanged<bool>? onChanged;

  const CheckboxFieldRow({
    super.key,
    required this.label,
    this.hint,
    this.initialValue = false,
    this.onChanged,
  });

  @override
  State<CheckboxFieldRow> createState() => _CheckboxFieldRowState();
}

class _CheckboxFieldRowState extends State<CheckboxFieldRow> {
  late bool _isChecked;

  @override
  void initState() {
    super.initState();
    _isChecked = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: _isChecked,
            onChanged: (value) {
              setState(() {
                _isChecked = value ?? false;
              });
              widget.onChanged?.call(_isChecked);
            },
            activeColor: const Color(0xFF2E8B7B),
            side: const BorderSide(color: Color(0xFF5D4037)),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          widget.label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF5D4037),
          ),
        ),
        if (widget.hint != null) ...[
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 28,
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Color(0xFF8B6914), width: 1),
                ),
              ),
              child: TextField(
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: widget.hint,
                  hintStyle: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF8B6914),
                    fontStyle: FontStyle.italic,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                  isDense: true,
                ),
                style: const TextStyle(fontSize: 12, color: Color(0xFF5D4037)),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ==================== DEMOGRAPHIC DATA FORM ====================
class DemographicDataForm extends StatelessWidget {
  const DemographicDataForm({super.key});

  @override
  Widget build(BuildContext context) {
    return FormCard(
      title: 'DEMOGRAPHIC DATA',
      child: Column(
        children: [
          const FormFieldRow(label: 'Name:'),
          const SizedBox(height: 12),
          Row(
            children: [
              const Expanded(child: FormFieldRow(label: 'Age:', labelWidth: 40)),
              const SizedBox(width: 16),
              const Expanded(child: FormFieldRow(label: 'Sex:', labelWidth: 40)),
            ],
          ),
          const SizedBox(height: 12),
          const FormFieldRow(label: 'Address:'),
          const SizedBox(height: 12),
          const FormFieldRow(label: 'Place of Birth:'),
          const SizedBox(height: 12),
          const FormFieldRow(label: 'Date of Birth:'),
          const SizedBox(height: 12),
          const FormFieldRow(label: 'Mother:'),
          const SizedBox(height: 12),
          const FormFieldRow(label: 'Contact #:'),
          const SizedBox(height: 12),
          const FormFieldRow(label: 'Father:'),
          const SizedBox(height: 12),
          const FormFieldRow(label: 'Contact #:'),
        ],
      ),
    );
  }
}

// ==================== ANTHROPOMETRIC DATA FORM ====================
class AnthropometricDataForm extends StatelessWidget {
  const AnthropometricDataForm({super.key});

  @override
  Widget build(BuildContext context) {
    return FormCard(
      title: 'ATHROPOMETRIC DATA',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const FormFieldRow(label: 'Date of Measurement:', labelWidth: 140),
          const SizedBox(height: 12),
          const FormFieldRow(label: 'Weight:'),
          const SizedBox(height: 12),
          const FormFieldRow(label: 'Height:'),
          const SizedBox(height: 12),
          const FormFieldRow(label: 'MUAC:'),
          const SizedBox(height: 16),
          // Auto-calculated fields
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFE8985A),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Column(
              children: [
                FormFieldRow(label: 'Weight-for-Age:', labelWidth: 140),
                SizedBox(height: 8),
                FormFieldRow(label: 'Weight-for-Height/Length:', labelWidth: 160),
                SizedBox(height: 8),
                FormFieldRow(label: 'Height-for-Age:', labelWidth: 140),
                SizedBox(height: 8),
                FormFieldRow(label: 'BMI:', labelWidth: 140),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== HEALTH STATUS FORM ====================
class HealthStatusForm extends StatelessWidget {
  const HealthStatusForm({super.key});

  @override
  Widget build(BuildContext context) {
    return FormCard(
      title: 'HEALTH STATUS',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          CheckboxFieldRow(
            label: 'Diarrhea:',
            hint: '(Date of Occurrence/ Duration)',
          ),
          SizedBox(height: 10),
          CheckboxFieldRow(
            label: 'Fever:',
            hint: '(Date of Occurrence/ Duration)',
          ),
          SizedBox(height: 10),
          CheckboxFieldRow(
            label: 'Cough/Pneumonia:',
            hint: '(Date of Occurrence/ Duration)',
          ),
          SizedBox(height: 10),
          CheckboxFieldRow(
            label: 'Other:',
            hint: '(Date of Occurrence/ Duration)',
          ),
          SizedBox(height: 10),
          CheckboxFieldRow(
            label: 'Medication/s:',
            hint: '(Current/ Taken during illness)',
          ),
        ],
      ),
    );
  }
}

// ==================== DIETARY ASSESSMENT FORM ====================
class DietaryAssessmentForm extends StatefulWidget {
  const DietaryAssessmentForm({super.key});

  @override
  State<DietaryAssessmentForm> createState() => _DietaryAssessmentFormState();
}

class _DietaryAssessmentFormState extends State<DietaryAssessmentForm> {
  bool? _purelyBreastfed;

  @override
  Widget build(BuildContext context) {
    return FormCard(
      title: 'DIETARY ASSESSMENT',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Purely Breastfed
          Row(
            children: [
              const Text(
                'Purely Breastfed:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF5D4037),
                ),
              ),
              const SizedBox(width: 16),
              Row(
                children: [
                  const Text('YES', style: TextStyle(fontSize: 12, color: Color(0xFF5D4037))),
                  Radio<bool>(
                    value: true,
                    groupValue: _purelyBreastfed,
                    onChanged: (v) => setState(() => _purelyBreastfed = v),
                    activeColor: const Color(0xFF2E8B7B),
                  ),
                ],
              ),
              Row(
                children: [
                  const Text('NO', style: TextStyle(fontSize: 12, color: Color(0xFF5D4037))),
                  Radio<bool>(
                    value: false,
                    groupValue: _purelyBreastfed,
                    onChanged: (v) => setState(() => _purelyBreastfed = v),
                    activeColor: const Color(0xFF2E8B7B),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Complimentary Feeding
          const Text(
            'Complimentary Feeding (CF):',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF5D4037),
            ),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.only(left: 12),
            child: Column(
              children: [
                FormFieldRow(label: 'Age when CF started:', hint: '(Age in months)', labelWidth: 140),
                SizedBox(height: 8),
                FormFieldRow(label: 'Frequency of CF a day:', labelWidth: 140),
                SizedBox(height: 8),
                FormFieldRow(label: 'Food/s given on CF:', labelWidth: 140),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Dietary Diversity
          const Text(
            'Dietary Diversity:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF5D4037),
            ),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.only(left: 12),
            child: Column(
              children: [
                CheckboxFieldRow(label: 'Grains/Roots/Tubers:', hint: '(Specify)'),
                SizedBox(height: 6),
                CheckboxFieldRow(label: 'Legumes/Nuts:', hint: '(Specify)'),
                SizedBox(height: 6),
                CheckboxFieldRow(label: 'Dairy Products:', hint: '(Specify)'),
                SizedBox(height: 6),
                CheckboxFieldRow(label: 'Meat/Fish/Poultry:', hint: '(Specify)'),
                SizedBox(height: 6),
                CheckboxFieldRow(label: 'Eggs:', hint: '(Specify)'),
                SizedBox(height: 6),
                CheckboxFieldRow(label: 'Vit-A rich foods & Vegetables:', hint: '(Specify)'),
                SizedBox(height: 6),
                CheckboxFieldRow(label: 'Other Fruits & Vegetables:', hint: '(Specify)'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const FormFieldRow(label: 'Meal frequency in a day:', labelWidth: 160),
        ],
      ),
    );
  }
}

// ==================== ORAL ASSESSMENT FORM ====================
class OralAssessmentForm extends StatelessWidget {
  const OralAssessmentForm({super.key});

  @override
  Widget build(BuildContext context) {
    return FormCard(
      title: 'ORAL ASSESSMENT',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Risk factors: Social/behavioral/medical
          _buildRiskSection(
            'Risk factors: Social/behavioral/medical',
            const Color(0xFFE53935), // High Risk - Red
            [
              'Mother/primary caregiver has active dental caries',
              'Parent/caregiver has life-time of poverty, low health literacy',
              'Child has frequent exposure (>3 times/day) between-meal sugar-containing snacks or beverages per day',
              'Child uses bottle or nonspill cup containing natural or added sugar frequently, between meals and/or at bedtime',
            ],
          ),
          const SizedBox(height: 8),
          _buildModerateRiskItems([
            'Child is a recent immigrant',
            'Child has special health care needs',
          ]),
          const SizedBox(height: 12),
          // Risk factors: Clinical
          _buildRiskSection(
            'Risk factors: Clinical',
            const Color(0xFFE53935),
            [
              'Child has visible plaque on teeth',
              'Child presents with dental enamel defects',
            ],
          ),
          const SizedBox(height: 12),
          // Protective Factors
          _buildRiskSection(
            'Protective Factors',
            const Color(0xFFFFEB3B), // Low Risk - Yellow
            [
              'Child receives optimally-fluoridated drinking water or fluoride supplements',
              'Child has teeth brushed daily with fluoridated toothpaste',
              'Child receives topical fluoride from health professional',
              'Child has dental home/regular dental care',
            ],
          ),
          const SizedBox(height: 16),
          // Disease Indicators
          const Text(
            'Disease Indicators:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF5D4037),
            ),
          ),
          const SizedBox(height: 8),
          _buildDiseaseIndicators(),
          const SizedBox(height: 12),
          // Overall Risk
          _buildOverallRisk(),
        ],
      ),
    );
  }

  Widget _buildRiskSection(String title, Color indicatorColor, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF5D4037),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: indicatorColor,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                indicatorColor == const Color(0xFFE53935)
                    ? 'High Risk'
                    : indicatorColor == const Color(0xFFFF9800)
                        ? 'Moderate Risk'
                        : 'Low Risk',
                style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        _buildYesNoHeader(),
        ...items.map((item) => _buildYesNoRow(item, indicatorColor)),
      ],
    );
  }

  Widget _buildModerateRiskItems(List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFFF9800),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Moderate Risk',
                style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        ...items.map((item) => _buildYesNoRow(item, const Color(0xFFFF9800))),
      ],
    );
  }

  Widget _buildYesNoHeader() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: SizedBox()),
          SizedBox(
            width: 35,
            child: Text('YES', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF5D4037)), textAlign: TextAlign.center),
          ),
          SizedBox(width: 8),
          SizedBox(
            width: 35,
            child: Text('NO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF5D4037)), textAlign: TextAlign.center),
          ),
        ],
      ),
    );
  }

  Widget _buildYesNoRow(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 11, color: Color(0xFF5D4037)),
            ),
          ),
          RiskCheckbox(color: color),
          const SizedBox(width: 8),
          RiskCheckbox(color: color),
        ],
      ),
    );
  }

  Widget _buildDiseaseIndicators() {
    return Column(
      children: [
        _buildYesNoHeader(),
        _buildYesNoRow('Child has noncavitated (incipient/white spot) caries lesions', const Color(0xFFE53935)),
        _buildYesNoRow('Child has visible caries lesions', const Color(0xFFE53935)),
        _buildYesNoRow('Child has recent restorations or missing teeth due to caries', const Color(0xFFE53935)),
      ],
    );
  }

  Widget _buildOverallRisk() {
    return Row(
      children: [
        const Text(
          'Overall:',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF5D4037)),
        ),
        const SizedBox(width: 12),
        _buildRiskChip('High', const Color(0xFFE53935)),
        const SizedBox(width: 8),
        _buildRiskChip('Moderate', const Color(0xFFFF9800)),
        const SizedBox(width: 8),
        _buildRiskChip('Low', const Color(0xFFFFEB3B)),
      ],
    );
  }

  Widget _buildRiskChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color == const Color(0xFFFFEB3B) ? Colors.black87 : Colors.white,
        ),
      ),
    );
  }
}

class RiskCheckbox extends StatefulWidget {
  final Color color;

  const RiskCheckbox({super.key, required this.color});

  @override
  State<RiskCheckbox> createState() => _RiskCheckboxState();
}

class _RiskCheckboxState extends State<RiskCheckbox> {
  bool _isChecked = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _isChecked = !_isChecked),
      child: Container(
        width: 35,
        height: 20,
        decoration: BoxDecoration(
          color: _isChecked ? widget.color : widget.color.withValues(alpha: 0.25),
          border: Border.all(color: widget.color, width: 1.5),
          borderRadius: BorderRadius.circular(3),
        ),
        child: _isChecked
            ? const Icon(Icons.check, size: 14, color: Colors.white)
            : null,
      ),
    );
  }
}

// ==================== VACCINATION FORM ====================
class VaccinationForm extends StatelessWidget {
  const VaccinationForm({super.key});

  @override
  Widget build(BuildContext context) {
    return FormCard(
      title: 'VACCINATION',
      child: Column(
        children: [
          // Vaccination Table
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF5D4037), width: 1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              children: [
                // Header Row
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: Color(0xFF5D4037))),
                  ),
                  child: const Row(
                    children: [
                      SizedBox(width: 80),
                      Expanded(child: Text('BIRTH', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF5D4037)), textAlign: TextAlign.center)),
                      Expanded(child: Text('1½', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF5D4037)), textAlign: TextAlign.center)),
                      Expanded(child: Text('2½', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF5D4037)), textAlign: TextAlign.center)),
                      Expanded(child: Text('3½', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF5D4037)), textAlign: TextAlign.center)),
                      Expanded(child: Text('9', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF5D4037)), textAlign: TextAlign.center)),
                      Expanded(child: Text('1 YR', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF5D4037)), textAlign: TextAlign.center)),
                    ],
                  ),
                ),
                // Vaccine Rows
                _buildVaccineRow('BCG', [true, false, false, false, false, false]),
                _buildVaccineRow('HEP B', [true, false, false, false, false, false]),
                _buildVaccineRow('PENTAVALENT', [false, true, true, true, false, false]),
                _buildVaccineRow('OPV', [false, true, true, true, false, false]),
                _buildVaccineRow('IPV', [false, true, true, false, false, false]),
                _buildVaccineRow('PCV', [false, true, true, true, false, false]),
                _buildVaccineRow('MMR', [false, false, false, false, true, true]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVaccineRow(String name, List<bool> schedule) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF5D4037), width: 0.5)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(
                name,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF5D4037)),
              ),
            ),
          ),
          ...schedule.map((scheduled) => Expanded(
                child: Center(
                  child: scheduled ? const VaccineCheckCircle() : const SizedBox(),
                ),
              )),
        ],
      ),
    );
  }
}

class VaccineCheckCircle extends StatefulWidget {
  const VaccineCheckCircle({super.key});

  @override
  State<VaccineCheckCircle> createState() => _VaccineCheckCircleState();
}

class _VaccineCheckCircleState extends State<VaccineCheckCircle> {
  bool _isChecked = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _isChecked = !_isChecked),
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _isChecked
              ? const Color(0xFF2E8B7B)
              : const Color(0xFF2E8B7B).withValues(alpha: 0.25),
          border: Border.all(
            color: const Color(0xFF2E8B7B),
            width: 1.5,
          ),
        ),
        child: _isChecked
            ? const Icon(Icons.check, size: 12, color: Colors.white)
            : null,
      ),
    );
  }
}

// ==================== DEWORMING FORM ====================
class DewormingForm extends StatefulWidget {
  const DewormingForm({super.key});

  @override
  State<DewormingForm> createState() => _DewormingFormState();
}

class _DewormingFormState extends State<DewormingForm> {
  bool _isNA = false;
  String? _drugGiven;

  @override
  Widget build(BuildContext context) {
    return FormCard(
      title: 'DEWORMING',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Date of last deworming:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF5D4037)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 28,
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: Color(0xFF8B6914), width: 1)),
                  ),
                  child: const TextField(
                    decoration: InputDecoration(border: InputBorder.none, isDense: true),
                    style: TextStyle(fontSize: 12, color: Color(0xFF5D4037)),
                  ),
                ),
              ),
            ],
          ),
          Row(
            children: [
              const SizedBox(width: 12),
              Checkbox(
                value: _isNA,
                onChanged: (v) => setState(() => _isNA = v ?? false),
                activeColor: const Color(0xFF2E8B7B),
              ),
              const Text('N/A', style: TextStyle(fontSize: 12, color: Color(0xFF5D4037))),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text(
                'Drug Given:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF5D4037)),
              ),
              const SizedBox(width: 8),
              Checkbox(
                value: _drugGiven == 'Albendazole',
                onChanged: (v) => setState(() => _drugGiven = v == true ? 'Albendazole' : null),
                activeColor: const Color(0xFF2E8B7B),
              ),
              const Text('Albendazole', style: TextStyle(fontSize: 12, color: Color(0xFF5D4037))),
              Checkbox(
                value: _drugGiven == 'Mebendazole',
                onChanged: (v) => setState(() => _drugGiven = v == true ? 'Mebendazole' : null),
                activeColor: const Color(0xFF2E8B7B),
              ),
              const Text('Mebendazole', style: TextStyle(fontSize: 12, color: Color(0xFF5D4037))),
            ],
          ),
          const SizedBox(height: 12),
          const FormFieldRow(label: 'Adverse Reactions:', labelWidth: 130),
          const SizedBox(height: 12),
          const FormFieldRow(label: 'Next deworming date:', labelWidth: 140),
          const SizedBox(height: 24),
          // Save Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Assessment saved successfully!'),
                    backgroundColor: Color(0xFF2E8B7B),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E8B7B),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                elevation: 3,
              ),
              child: const Text(
                'Save',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

