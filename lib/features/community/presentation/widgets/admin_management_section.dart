import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';


import '../../models/community.dart';
import '../../providers/community_provider.dart';
import '../pages/community_member_page.dart';
import '../pages/community_member_request_page.dart';

class AdminManagementSection extends ConsumerWidget {
  final Community community;
  final String uid;

  const AdminManagementSection({
    super.key,
    required this.community,
    required this.uid,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
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
      padding: EdgeInsets.all(16.r),
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
                child: Icon(PhosphorIcons.shieldChevron,
                    size: 15.w, color: Colors.red.shade600),
              ),
              SizedBox(width: 8.w),
              Text(
                'Manage Community',
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          // SizedBox(height: 12.h),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12.w,
            mainAxisSpacing: 12.h,
            childAspectRatio: 1.2,
            children: [
              // All Members
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          CommunityMembersPage(community: community),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(14.r),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        PhosphorIcons.usersThree,
                        size: 24.w,
                        color: Colors.red.shade600,
                      ),
                      SizedBox(height: 6.h),
                      ref.watch(membersStreamProvider(community.id)).when(
                        data: (members) => FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '${members.length}',
                            style: TextStyle(
                              fontSize: 26.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.red.shade600,
                            ),
                          ),
                        ),
                        loading: () => FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '${community.memberCount}',
                            style: TextStyle(
                              fontSize: 26.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.red.shade600,
                            ),
                          ),
                        ),
                        error: (_, _) => FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '${community.memberCount}',
                            style: TextStyle(
                              fontSize: 26.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.red.shade600,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'Members',
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Member Requests
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          CommunityMemberRequestPage(community: community),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(14.r),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        PhosphorIcons.userCirclePlus,
                        size: 24.w,
                        color: Colors.orange.shade600,
                      ),
                      SizedBox(height: 6.h),
                      ref.watch(joinRequestsStreamProvider(community.id)).when(
                        data: (requests) => FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '${requests.length}',
                            style: TextStyle(
                              fontSize: 26.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade600,
                            ),
                          ),
                        ),
                        loading: () => FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '0',
                            style: TextStyle(
                              fontSize: 26.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ),
                        error: (_, _) => FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '0',
                            style: TextStyle(
                              fontSize: 26.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'Requests',
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
