import 'package:flutter/material.dart';

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
          //todo: later
          // IconButton(
          //   onPressed: () {},
          //   icon: const Icon(Icons.notifications_none, size: 24),
          // ),
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
