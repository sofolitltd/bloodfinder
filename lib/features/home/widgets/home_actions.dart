import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../routes/app_route.dart';
import 'home_community.dart';

class HomeActionButtonsSection extends StatelessWidget {
  const HomeActionButtonsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          spacing: 20,
          children: [
            //
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: .9,
              children: [
                _buildActionButton(
                  context,
                  icon: Icons.scatter_plot,
                  text: 'Post Blood\nRequest',
                  onTap: () {
                    context.pushNamed(AppRoute.bloodRequest.name);
                  },
                ),
                _buildActionButton(
                  context,
                  icon: Icons.bloodtype,
                  text: 'Blood\nBank',
                  onTap: () {
                    context.pushNamed(AppRoute.bloodBank.name);
                  },
                ),
                _buildActionButton(
                  context,
                  icon: Icons.local_hospital,
                  text: 'Emergency\nDonors',
                  onTap: () {
                    //
                    context.pushNamed(AppRoute.emergencyDonor.name);
                  },
                ),
              ],
            ),

            //
            HomeCommunitySection(),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.fromLTRB(8, 6, 8, 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Theme.of(context).colorScheme.brightness == Brightness.light
              ? Colors.white
              : Colors.transparent,
          boxShadow: [
            BoxShadow(
              color: Colors.transparent.withValues(alpha: .05),
              spreadRadius: 2,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],

          border: Border.all(
            color: Theme.of(context).colorScheme.brightness == Brightness.light
                ? Colors.black12
                : Colors.white30,
            width: .5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.red, size: 60),
            const SizedBox(height: 8),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
