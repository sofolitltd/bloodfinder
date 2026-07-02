import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
class DonorInfoSection extends StatelessWidget {
  final String? bloodGroup;
  final ValueChanged<String?> onBloodGroupChanged;
  final String? gender;
  final ValueChanged<String?> onGenderChanged;
  final DateTime? dob;
  final VoidCallback onSelectDate;
  final bool isDonor;
  final VoidCallback onDonorTap;
  final String? donorError;

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
    required this.isDonor,
    required this.onDonorTap,
    this.donorError,
  });

  @override
  Widget build(BuildContext context) {
    return ButtonTheme(
      alignedDropdown: true,
      child: Column(
        spacing: 8.h,
        children: [
            // Blood group + Gender — row
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: bloodGroup,
                    hint: const Text('Blood Gr.'),
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
                SizedBox(width: 8.w),
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
            SizedBox(height: 8.h),

            // DOB
            GestureDetector(
              onTap: onSelectDate,
              child: AbsorbPointer(
                child: TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Date of Birth',
                    prefixIcon: Icon(Icons.calendar_today_outlined, size: 20.w),
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

            SizedBox(height: 8.h),

            // Donor toggle
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(
                  color: isDonor ? Colors.red.shade200 : Colors.grey.shade200,
                ),
                color: isDonor ? Colors.red.shade50 : Colors.grey.shade50,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sign up as a donor',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15.sp,
                            color: isDonor
                                ? Colors.red.shade800
                                : Colors.grey.shade700,
                          ),
                        ),
                        Text(
                          isDonor
                              ? "You're ready to save lives"
                              : 'Donors must set their location below',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: isDonor
                                ? Colors.red.shade400
                                : Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: isDonor,
                    onChanged: (_) => onDonorTap(),
                    activeTrackColor: Colors.red.shade200,
                    activeThumbColor: Colors.red.shade500,
                  ),
                ],
              ),
            ),

            if (donorError != null)
              Padding(
                padding: EdgeInsets.only(top: 8.h, left: 4.w),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, size: 16.w, color: Colors.red.shade600),
                    SizedBox(width: 6.w),
                    Flexible(
                      child: Text(
                        donorError!,
                        style: TextStyle(color: Colors.red.shade600, fontSize: 13.sp),
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
