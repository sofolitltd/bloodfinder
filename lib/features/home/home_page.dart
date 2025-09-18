import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers/notification_provider.dart';
import '../../notification/notification_page.dart';
import 'widgets/home_actions.dart';
import 'widgets/home_find_donor.dart';
import 'widgets/home_requests.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // title: const Text('Blood Finder', style: TextStyle(color: Colors.red)),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,

          children: [
            //
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: AssetImage('assets/images/logo.png'),
                ),
              ),
            ),

            SizedBox(width: 4),

            //
            Text(
              "Blood",
              // "BLOOD",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),

            SizedBox(width: 4),
            Text(
              "Finder",
              // "FINDER",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w100,
                color:
                    Theme.of(context).colorScheme.brightness == Brightness.light
                    ? Colors.black87
                    : Colors.white,
              ),
            ),
          ],
        ),

        actions: [
          //
          NotificationIconButton(
            userId: FirebaseAuth.instance.currentUser!.uid,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            spacing: 8,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              HomeFindDonorSection(),
              HomeActionButtonsSection(),
              HomeBloodRequestsSection(),
              SizedBox(),
            ],
          ),
        ),
      ),
    );
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
          icon: const Icon(Icons.notifications_none, size: 24),
        ),
        unreadAsync.when(
          data: (count) => count > 0
              ? Positioned(
                  right: 4,
                  top: 4,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      count.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : const SizedBox(),
          loading: () => const SizedBox(),
          error: (_, __) => const SizedBox(),
        ),
      ],
    );
  }
}
