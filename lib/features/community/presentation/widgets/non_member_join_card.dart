import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../models/community.dart';
import 'join_request_sheet.dart';
import 'request_blood_from_community_sheet.dart';

/// Shown in the "Members" tab to users who are not yet an approved member
/// of the community: lets them see how to join or request blood instead.
class NonMemberJoinCard extends StatelessWidget {
  final Community community;

  const NonMemberJoinCard({super.key, required this.community});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(16.w),
      children: [
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
              Text(
                "You're not a member yet",
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                'Join this community to see and connect with its members.',
                style: TextStyle(fontSize: 13.sp, color: Colors.grey.shade600),
              ),
              SizedBox(height: 16.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      builder: (context) => JoinRequestSheet(community: community),
                    );
                  },
                  icon: Icon(PhosphorIcons.usersThree),
                  label: const Text('View Join Instructions'),
                ),
              ),
              SizedBox(height: 8.h),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      builder: (context) =>
                          RequestBloodFromCommunitySheet(community: community),
                    );
                  },
                  icon: Icon(PhosphorIcons.drop, color: Colors.red.shade600),
                  label: Text(
                    'Request Blood from this Community',
                    style: TextStyle(color: Colors.red.shade600),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.red.shade200),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
