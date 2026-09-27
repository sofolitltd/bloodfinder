import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../models/community.dart';
import '../pages/group_member_by_blood_page.dart';

/// Tappable 4-column grid of blood groups with member counts, drilling into
/// [BloodGroupMembersScreen] for groups that have at least one member.
class BloodGroupGrid extends StatelessWidget {
  final Community community;

  const BloodGroupGrid({super.key, required this.community});

  static const _allBloodGroups = ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'];

  @override
  Widget build(BuildContext context) {
    final counts = community.bloodGroupCounts ?? {};

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 0.85,
      children: _allBloodGroups.map((bg) {
        final count = counts[bg] ?? 0;
        final isAvailable = count > 0;
        return GestureDetector(
          onTap: isAvailable
              ? () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BloodGroupMembersScreen(
                        communityId: community.id,
                        bloodGroup: bg,
                      ),
                    ),
                  );
                }
              : null,
          child: Container(
            decoration: BoxDecoration(
              color: isAvailable ? Colors.red.shade50 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(
                color: isAvailable ? Colors.red.shade200 : Colors.grey.shade200,
                width: 1.w,
              ),
            ),
            padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 2.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  bg,
                  style: TextStyle(
                    color: isAvailable ? Colors.red.shade700 : Colors.grey.shade400,
                    fontWeight: FontWeight.bold,
                    fontSize: 15.sp,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 4.h),
                  child: Container(
                    height: 1.h,
                    width: 20.w,
                    color: isAvailable ? Colors.red.shade200 : Colors.grey.shade300,
                  ),
                ),
                Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 17.sp,
                    fontWeight: FontWeight.bold,
                    color: isAvailable ? Colors.red.shade600 : Colors.grey.shade400,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'member${count == 1 ? '' : 's'}',
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: isAvailable ? Colors.grey.shade600 : Colors.grey.shade400,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
