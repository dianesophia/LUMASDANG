import 'package:flutter/material.dart';
import 'form_card.dart';
import 'form_field_row.dart';

class DemographicDataForm extends StatelessWidget {
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController ageController;
  final TextEditingController sexController;
  final TextEditingController addressController;
  final TextEditingController placeOfBirthController;
  final TextEditingController dobController;
  final TextEditingController motherController;
  final TextEditingController motherContactController;
  final TextEditingController fatherController;
  final TextEditingController fatherContactController;

  const DemographicDataForm({
    super.key,
    required this.firstNameController,
    required this.lastNameController,
    required this.ageController,
    required this.sexController,
    required this.addressController,
    required this.placeOfBirthController,
    required this.dobController,
    required this.motherController,
    required this.motherContactController,
    required this.fatherController,
    required this.fatherContactController,
  });

  @override
  Widget build(BuildContext context) {
    return FormCard(
      title: 'DEMOGRAPHIC DATA',
      child: Column(
        children: [
          FormFieldRow(
            label: 'First Name:',
            controller: firstNameController,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'First name is required';
              if (v.trim().length < 2) return 'Must be at least 2 characters';
              return null;
            },
          ),
          const SizedBox(height: 12),
          FormFieldRow(
            label: 'Last Name:',
            controller: lastNameController,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Last name is required';
              if (v.trim().length < 2) return 'Must be at least 2 characters';
              return null;
            },
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: FormFieldRow(
                  label: 'Age:',
                  labelWidth: 40,
                  controller: ageController,
                  keyboardType: TextInputType.number,
                  hint: 'Enter age in months (0–60)',
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    final age = int.tryParse(v.trim());
                    if (age == null) return 'Enter a number';
                    if (age < 0 || age > 60) return 'Enter age in months (0–60)';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FormFieldRow(
                  label: 'Sex:',
                  labelWidth: 40,
                  controller: sexController,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    final sex = v.trim().toUpperCase();
                    if (sex != 'M' && sex != 'F' && sex != 'MALE' && sex != 'FEMALE') {
                      return 'Enter M or F';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FormFieldRow(
            label: 'Address:',
            controller: addressController,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Address is required';
              return null;
            },
          ),
          const SizedBox(height: 12),
          FormFieldRow(
            label: 'Place of Birth:',
            controller: placeOfBirthController,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Place of birth is required';
              return null;
            },
          ),
          const SizedBox(height: 12),
          FormFieldRow(
            label: 'Date of Birth:',
            controller: dobController,
            keyboardType: TextInputType.datetime,
            hint: 'MM-DD-YYYY (e.g. 05-01-2023)',
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Date of birth is required';
              final value = v.trim();
              final regex = RegExp(r'^\d{2}-\d{2}-\d{4}$');
              if (!regex.hasMatch(value)) {
                return 'Use format MM-DD-YYYY';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          FormFieldRow(
            label: 'Mother Name:',
            controller: motherController,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Mother\'s name is required';
              return null;
            },
          ),
          const SizedBox(height: 12),
          FormFieldRow(
            label: 'Contact #:',
            controller: motherContactController,
            keyboardType: TextInputType.phone,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Contact number is required';
              if (v.trim().length != 11) return 'Enter a valid contact number';
              return null;
            },
          ),
          const SizedBox(height: 12),
          FormFieldRow(
            label: 'Fathers Name:',
            controller: fatherController,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Father\'s name is required';
              return null;
            },
          ),
          const SizedBox(height: 12),
          FormFieldRow(
            label: 'Contact #:',
            controller: fatherContactController,
            keyboardType: TextInputType.phone,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Contact number is required';
              if (v.trim().length != 11) return 'Enter a valid contact number';
              return null;
            },
          ),
        ],
      ),
    );
  }
}
