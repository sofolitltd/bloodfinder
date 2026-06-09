import 'package:flutter/material.dart';

class DonorInfoSection extends StatelessWidget {
  final String? bloodGroup;
  final ValueChanged<String?> onBloodGroupChanged;
  final String? gender;
  final ValueChanged<String?> onGenderChanged;
  final DateTime? dob;
  final VoidCallback onSelectDate;

  static int _calculateAge(DateTime dob) {
    final now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age;
  }

  const DonorInfoSection({
    super.key,
    required this.bloodGroup,
    required this.onBloodGroupChanged,
    required this.gender,
    required this.onGenderChanged,
    required this.dob,
    required this.onSelectDate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Blood group + Gender — row
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: bloodGroup,
                  hint: const Text('Blood Group'),
                  items: ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-']
                      .map((bg) => DropdownMenuItem(
                            value: bg,
                            child: Text(bg),
                          ))
                      .toList(),
                  onChanged: onBloodGroupChanged,
                  decoration: const InputDecoration(),
                  validator: (v) => v == null ? 'Required' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: gender,
                  hint: const Text('Gender'),
                  items: ['Male', 'Female']
                      .map((g) => DropdownMenuItem(
                            value: g,
                            child: Text(g),
                          ))
                      .toList(),
                  onChanged: onGenderChanged,
                  decoration: const InputDecoration(),
                  validator: (v) => v == null ? 'Required' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // DOB
          GestureDetector(
            onTap: onSelectDate,
            child: AbsorbPointer(
              child: TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Date of Birth',
                  prefixIcon: Icon(Icons.calendar_today_outlined, size: 20),
                ),
                controller: TextEditingController(
                  text: dob == null
                      ? ''
                      : '${dob!.day.toString().padLeft(2, '0')}/${dob!.month.toString().padLeft(2, '0')}/${dob!.year} (${_calculateAge(dob!)} years old)',
                ),
                validator: (_) => dob == null ? 'Required' : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
