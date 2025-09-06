import 'package:flutter/material.dart';

import 'widgets/home_actions.dart';
import 'widgets/home_filters.dart';
import 'widgets/home_requests.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Blood Finder', style: TextStyle(color: Colors.red)),
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
              HomeFilterSection(),
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
