import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';


import '../../../../core/utils/string_utils.dart';
import '../../../../data/providers/notification_provider.dart';
import '../../../../data/providers/user_providers.dart';

import '../../../notification/presentation/pages/notification_page.dart';

import '../widgets/home_actions.dart';

import '../widgets/home_find_donor.dart';

import '../widgets/home_requests.dart';

import '../widgets/home_community_contribution.dart';
import '../widgets/home_events.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  bool _onboardingChecked = false;

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userProvider);
    final user = userAsync.value;

    // One-time check: navigate to location setup if savedAddresses is empty
    if (!_onboardingChecked && user != null && user.savedAddresses.isEmpty) {
      _onboardingChecked = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          GoRouter.of(context).push('/location-setup');
        }
      });
    }

    final greeting = _greeting();
    final displayName = user != null ? StringUtils.formatFullName(user.firstName, user.lastName) : 'Dear';

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Hero header
            Container(
              width: double.infinity,
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 16.h,
                left: 24.w,
                right: 8.w,
                bottom: 32.h,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.red.shade800,
                    Colors.red.shade600,
                    Colors.red.shade400,
                  ],
                ),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.elliptical(300.w, 40.h),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row: greeting + notification
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              greeting,
                              style: TextStyle(
                                fontSize: 15.sp,
                                color: Colors.white.withValues(alpha: 0.85),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              displayName,
                              style: TextStyle(
                                fontSize: 22.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      NotificationIconButton(
                        userId: FirebaseAuth.instance.currentUser!.uid,
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  // Blood drop + tagline
                  Row(
                    children: [
                      Container(
                        width: 20.w,
                        height: 20.h,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          PhosphorIcons.drop,
                          color: Colors.white,
                          size: 16.w,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Text(
                        'Ready to make a difference?',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.white.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 24.h),
            // Sections
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 0.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  HomeFindDonorSection(),
                  SizedBox(height: 24.h),
                  HomeActionButtonsSection(),
                  SizedBox(height: 24.h),
                  HomeCommunityContributionSection(),
                  SizedBox(height: 24.h),
                  HomeUpcomingEventsSection(),
                  SizedBox(height: 24.h),
                  HomeBloodRequestsSection(),
                  SizedBox(height: 24.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }
}

//

class NotificationIconButton extends ConsumerWidget {
  final String userId;

  const NotificationIconButton({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadAsync = ref.watch(unreadCountProvider(userId));

    return Stack(
      children: [
        IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => NotificationPage(userId: userId),
              ),
            );
          },
          icon: Icon(PhosphorIcons.bell, size: 24.w, color: Colors.white),
        ),

        //
        unreadAsync.when(
          data: (count) => count > 0
              ? Positioned(
                  right: 8.w,
                  top: 6.h,
                  child: Container(
                    padding: EdgeInsets.all(2.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    constraints: BoxConstraints(
                      minWidth: 16.w,
                      minHeight: 16.h,
                    ),
                    child: Text(
                      count.toString(),
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : const SizedBox(),
          loading: () => const SizedBox(),
          error: (_, _) => const SizedBox(),
        ),
      ],
    );
  }
}
