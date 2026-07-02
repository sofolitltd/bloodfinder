import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;

  const SectionHeader({super.key, required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.only(top: 4.h, bottom: 2.h),
      child: Row(
        spacing: 8,
        children: [
          Icon(icon, size: 20, color: Colors.red.shade600),
          Text(
            title,
            style: TextStyle(
              fontSize: 17.sp,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.grey.shade200 : Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }
}
