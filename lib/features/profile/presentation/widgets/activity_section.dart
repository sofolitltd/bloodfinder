import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '/routes/app_route.dart';
import 'section_header.dart';

class ActivitySection extends ConsumerWidget {
  const ActivitySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        SizedBox(height: 24.h),
        const SectionHeader(
          icon: Icons.menu,
          title: 'Activity',
        ),
        SizedBox(height: 8.h),
        Column(
          spacing: 8,
          children: [
            _buildProfileOption(
              context,
              PhosphorIcons.drop,
              'My Blood Requests',
              () {
                context.pushNamed(
                  AppRoute.bloodRequestHistory.name,
                );
              },
            ),
            _buildProfileOption(
              context,
              PhosphorIcons.clockCounterClockwise,
              'My Donation History',
              () {
                context.pushNamed(AppRoute.donationHistory.name);
              },
            ),
            _buildProfileOption(
              context,
              PhosphorIcons.usersThree,
              'Community Page',
              () {
                context.pushNamed(AppRoute.community.name);
              },
            ),
            _buildProfileOption(
              context,
              PhosphorIcons.calendar,
              'Events Page',
              () {
                context.pushNamed(AppRoute.events.name);
              },
            ),
            _buildProfileOption(
              context,
              PhosphorIcons.chatCircleDots,
              'My Feedback',
              () {
                context.pushNamed(AppRoute.myFeedback.name);
              },
            ),
          ],
        ),

      ],
    );
  }

  Widget _buildProfileOption(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          child: Row(
            children: [
              Icon(icon, size: 22.w),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500),
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }

}
