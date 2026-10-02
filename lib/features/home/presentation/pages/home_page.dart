import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';


import '/core/utils/string_utils.dart';
import '/data/providers/notification_provider.dart';
import '/data/providers/user_providers.dart';

import '/features/notification/presentation/pages/notification_page.dart';
import '/features/profile/presentation/pages/address_management_page.dart';

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
                top: MediaQuery.of(context).padding.top + 16,
                left: 24,
                right: 8,
                bottom: 32,
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
                  bottom: Radius.elliptical(300, 40),
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
                                fontSize: 15,
                                color: Colors.white.withValues(alpha: 0.85),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              displayName,
                              style: TextStyle(
                                fontSize: 22,
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
                  SizedBox(height: 8),
                  // Current location / set location
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AddressManagementPage(),
                          ),
                        );
                      },
                      child: Row(
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              PhosphorIcons.mapPin,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              user?.locationAddress != null
                                  ? user!.locationAddress!
                                  : 'Tap to set your location',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withValues(alpha: 0.9),
                                fontWeight: FontWeight.w400,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            color: Colors.white.withValues(alpha: 0.8),
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                
                ],
              ),
            ),
            SizedBox(height: 24),
            // Sections
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  HomeFindDonorSection(),
                  SizedBox(height: 24),
                  HomeActionButtonsSection(),
                  SizedBox(height: 24),
                  HomeCommunityContributionSection(),
                  SizedBox(height: 24),
                  HomeUpcomingEventsSection(),
                  SizedBox(height: 16),
                  HomeBloodRequestsSection(),
                  SizedBox(height: 24),
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
          icon: Icon(PhosphorIcons.bell, size: 24, color: Colors.white),
        ),

        //
        unreadAsync.when(
          data: (count) => count > 0
              ? Positioned(
                  right: 8,
                  top: 6,
                  child: Container(
                    padding: EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      count.toString(),
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 10,
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
