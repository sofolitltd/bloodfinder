// lib/router_config.dart
import 'dart:async';

import 'package:bloodfinder/features/blood_request/my_blood_request.dart';
import 'package:bloodfinder/features/chat/archieve_message_page.dart';
import 'package:bloodfinder/features/community/edit_community.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '/features/auth/login.dart';
import '/features/auth/registration.dart';
import '/features/blood_bank/blood_bank.dart';
import '/features/blood_request/post_blood_request.dart';
import '/features/chat/chat_detail_page.dart';
import '/features/chat/chat_page.dart';
import '/features/community/community_details.dart';
import '/features/community/community_page.dart';
import '/features/donation/donation_history.dart';
import '/features/emergency_donor/emergency_donor_page.dart';
import '/features/feed/feed.dart';
import '/features/home/home_page.dart';
import '/features/profile/profile_page.dart';
import '../data/models/community.dart';
import '../features/auth/forgot_password.dart';
import 'app_route.dart';

// Global key for the root navigator, essential for GoRouter
final _rootNavigatorKey = GlobalKey<NavigatorState>();
final FirebaseAuth _auth = FirebaseAuth.instance;

final GoRouter routerConfig = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: AppRoute.home.path,
  redirect: (BuildContext context, GoRouterState state) {
    final isLoggedIn = _auth.currentUser != null;
    final isLoggingIn =
        state.uri.toString() == AppRoute.login.path ||
        state.uri.toString() == AppRoute.registration.path;

    if (!isLoggedIn && !isLoggingIn) return AppRoute.login.path;
    if (isLoggedIn && isLoggingIn) return AppRoute.home.path;

    return null;
  },
  refreshListenable: GoRouterRefreshStream(_auth.authStateChanges()),
  routes: [
    // StatefulShellRoute is used for persistent UI
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        // This builder defines the shared Scaffold with the NavigationBar.
        return ScaffoldWithNavBar(navigationShell: navigationShell);
      },
      branches: [
        // --- Branch for the 'Home' tab ---
        StatefulShellBranch(
          routes: [
            GoRoute(
              name: AppRoute.home.name,
              path: AppRoute.home.path,
              pageBuilder: (context, state) => const NoTransitionPage(
                child: HomePage(), // The widget displayed for this route
              ),
            ),
          ],
        ),

        // --- Branch for the 'Feed' tab ---
        StatefulShellBranch(
          routes: [
            GoRoute(
              name: AppRoute.feed.name,
              path: AppRoute.feed.path,
              pageBuilder: (context, state) => const NoTransitionPage(
                child: FeedPage(), // The widget displayed for this route
              ),
            ),
          ],
        ),

        // --- Branch for the 'Chat' tab ---
        StatefulShellBranch(
          routes: [
            GoRoute(
              name: AppRoute.chat.name,
              path: AppRoute.chat.path,
              pageBuilder: (context, state) => const NoTransitionPage(
                child: ChatPage(), // The widget displayed for this route
              ),
            ),
          ],
        ),

        // --- Branch for the 'Profile' tab ---
        StatefulShellBranch(
          routes: [
            GoRoute(
              name: AppRoute.profile.name,
              path: AppRoute.profile.path,
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: ProfilePage()),
            ),
          ],
        ),
      ],
    ),

    // chat details
    GoRoute(
      name: 'chatDetail',
      path: '/chats/:chatId',
      pageBuilder: (context, state) {
        final chatId = state.pathParameters['chatId']!;
        final extra =
            state.extra as Map<String, String>?; // donorId / requesterId
        return MaterialPage(child: ChatDetailPage(chatId: chatId));
      },
    ),

    //archive
    GoRoute(
      name: AppRoute.archive.name,
      path: AppRoute.archive.path,
      pageBuilder: (context, state) => const NoTransitionPage(
        child: ArchivedMessagesPage(), // The widget displayed for this route
      ),
    ),

    //community
    GoRoute(
      name: AppRoute.community.name,
      path: AppRoute.community.path,
      pageBuilder: (context, state) => const NoTransitionPage(
        child: CommunityPage(), // The widget displayed for this route
      ),
    ),

    GoRoute(
      name: 'communityDetail',
      path: '/community/:communityId',
      pageBuilder: (context, state) {
        final communityId = state.pathParameters['communityId']!;
        return MaterialPage(
          child: CommunityDetailsPage(communityId: communityId),
        );
      },
    ),

    // edit community
    GoRoute(
      name: 'editCommunity',
      path: '/editCommunity',
      pageBuilder: (context, state) {
        final community = state.extra as Community;
        return MaterialPage(child: EditCommunity(community: community));
      },
    ),

    // login
    GoRoute(
      name: AppRoute.login.name,
      path: AppRoute.login.path,
      pageBuilder: (context, state) => const NoTransitionPage(
        child: LoginPage(), // The widget displayed for this route
      ),
    ),

    //register
    GoRoute(
      name: AppRoute.registration.name,
      path: AppRoute.registration.path,
      pageBuilder: (context, state) => const NoTransitionPage(
        child: RegistrationPage(), // The widget displayed for this route
      ),
    ),

    //reset
    GoRoute(
      name: AppRoute.forgotPassword.name,
      path: AppRoute.forgotPassword.path,
      pageBuilder: (context, state) => const NoTransitionPage(
        child: ForgotPasswordPage(), // The widget displayed for this route
      ),
    ),

    // blood request
    GoRoute(
      name: AppRoute.bloodRequest.name,
      path: AppRoute.bloodRequest.path,
      pageBuilder: (context, state) => const NoTransitionPage(
        child: BloodRequestPage(), // The widget displayed for this route
      ),
    ),

    // blood bank
    GoRoute(
      name: AppRoute.bloodBank.name,
      path: AppRoute.bloodBank.path,
      pageBuilder: (context, state) => NoTransitionPage(
        child: BloodBankPage(), // The widget displayed for this route
      ),
    ),

    // emergency donor
    GoRoute(
      name: AppRoute.emergencyDonor.name,
      path: AppRoute.emergencyDonor.path,
      pageBuilder: (context, state) =>
          NoTransitionPage(child: EmergencyDonorPage()),
    ),

    // blood req history
    GoRoute(
      name: AppRoute.bloodRequestHistory.name,
      path: AppRoute.bloodRequestHistory.path,
      pageBuilder: (context, state) =>
          NoTransitionPage(child: MyBloodRequestsPage()),
    ),

    // donation history
    GoRoute(
      name: AppRoute.donationHistory.name,
      path: AppRoute.donationHistory.path,
      pageBuilder: (context, state) =>
          NoTransitionPage(child: DonationHistoryPage()),
    ),
  ],
);

// --- The Shared UI Shell with Material 3 NavigationBar ---
class ScaffoldWithNavBar extends StatelessWidget {
  const ScaffoldWithNavBar({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
          navigationShell, // Displays the content of the currently selected branch
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.feed_outlined),
            selectedIcon: Icon(Icons.feed),
            label: 'Feed',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: 'Chats',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        onDestinationSelected: (int index) {
          // Navigates to the selected branch using goBranch.
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
      ),
    );
  }
}

/// A ChangeNotifier that listens to a Stream and notifies its listeners on events.
/// Useful to connect a Stream (like Firebase Auth state) to GoRouter's `refreshListenable`.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen((_) {
      notifyListeners();
    });
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
