import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// A read-only, non-tappable summary of a community's blood-group
/// availability — shown on browse-list cards and to non-members on the
/// details page, so the breakdown is visible without joining.
class BloodGroupCountChips extends StatelessWidget {
  final Map<String, int>? bloodGroupCounts;
  final bool dense;

  const BloodGroupCountChips({
    super.key,
    required this.bloodGroupCounts,
    this.dense = false,
  });

  static const _allBloodGroups = [
    'A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'
  ];

  @override
  Widget build(BuildContext context) {
    final counts = bloodGroupCounts ?? {};
    final available = _allBloodGroups
        .where((bg) => (counts[bg] ?? 0) > 0)
        .toList();

    if (available.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 6.w,
      runSpacing: 6.h,
      children: available.map((bg) {
        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: dense ? 6.w : 8.w,
            vertical: dense ? 3.h : 4.h,
          ),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: Colors.red.shade200, width: 1),
          ),
          child: Text(
            '$bg · ${counts[bg]}',
            style: TextStyle(
              fontSize: dense ? 10.sp : 11.sp,
              fontWeight: FontWeight.w600,
              color: Colors.red.shade700,
            ),
          ),
        );
      }).toList(),
    );
  }
}
