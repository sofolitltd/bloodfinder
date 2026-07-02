import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';


import '../../models/community.dart';
import '../../providers/community_provider.dart';
import '../pages/community_member_page.dart';
import '../pages/group_member_by_blood_page.dart';

class MemberContentSection extends ConsumerWidget {
  final Community community;
  final String uid;

  const MemberContentSection({
    super.key,
    required this.community,
    required this.uid,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allBloodGroups = ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'];
    final counts = community.bloodGroupCounts ?? {};
    final hasAnyMember = counts.values.any((c) => c > 0);

    return Column(
      children: [
        // Members by Blood Group
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 28.w,
                    height: 28.h,
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Icon(PhosphorIcons.drop,
                        size: 15, color: Colors.red.shade600),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    'Members by Blood Group',
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
              // SizedBox(height: 8.h),
              if (!hasAnyMember)
                Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 24.h),
                    child: Text(
                      'No approved members yet',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ),
                )
              else
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 4,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 0.85,
                  children: allBloodGroups.map((bg) {
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
                          color: isAvailable
                              ? Colors.red.shade50
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(14.r),
                          border: Border.all(
                            color: isAvailable
                                ? Colors.red.shade200
                                : Colors.grey.shade200,
                            width: 1.w,
                          ),
                        ),
                        padding: EdgeInsets.symmetric(
                            vertical: 8.h, horizontal: 2.w),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              bg,
                              style: TextStyle(
                                color: isAvailable
                                    ? Colors.red.shade700
                                    : Colors.grey.shade400,
                                fontWeight: FontWeight.bold,
                                fontSize: 15.sp,
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(
                                  vertical: 4.h),
                              child: Container(
                                height: 1.h,
                                width: 20.w,
                                color: isAvailable
                                    ? Colors.red.shade200
                                    : Colors.grey.shade300,
                              ),
                            ),
                            Text(
                              '$count',
                              style: TextStyle(
                                fontSize: 17.sp,
                                fontWeight: FontWeight.bold,
                                color: isAvailable
                                    ? Colors.red.shade600
                                    : Colors.grey.shade400,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'member${count == 1 ? '' : 's'}',
                              style: TextStyle(
                                fontSize: 10.sp,
                                color: isAvailable
                                    ? Colors.grey.shade600
                                    : Colors.grey.shade400,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        ),

        SizedBox(height: 12.h),

        // All Community Members button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      CommunityMembersPage(community: community),
                ),
              );
            },
            icon: Icon(PhosphorIcons.usersThree, size: 20.w),
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'All Community Members',
                  style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600),
                ),
                SizedBox(width: 6.w),
                ref.watch(membersStreamProvider(community.id)).when(
                  data: (members) => Text(
                    '(${members.length})',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15.sp,
                    ),
                  ),
                  loading: () => Text(
                    '(${community.memberCount})',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15.sp,
                    ),
                  ),
                  error: (_, _) => Text(
                    '(${community.memberCount})',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15.sp,
                    ),
                  ),
                ),
              ],
            ),
            style: ElevatedButton.styleFrom(
              elevation: 0,
              minimumSize: const Size(double.infinity, 52),
            ),
          ),
        ),

        SizedBox(height: 8.h),
      ],
    );
  }
}
