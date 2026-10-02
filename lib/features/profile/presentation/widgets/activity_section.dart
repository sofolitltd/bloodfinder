import 'package:flutter/material.dart';
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
        SizedBox(height: 24),
        const SectionHeader(
          icon: Icons.menu,
          title: 'Activity',
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
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
              _divider(context),
              _buildProfileOption(
                context,
                PhosphorIcons.clockCounterClockwise,
                'My Donation History',
                () {
                  context.pushNamed(AppRoute.donationHistory.name);
                },
              ),
              _divider(context),
              _buildProfileOption(
                context,
                PhosphorIcons.usersThree,
                'Community Page',
                () {
                  context.pushNamed(AppRoute.community.name);
                },
              ),
              _divider(context),
              _buildProfileOption(
                context,
                PhosphorIcons.calendar,
                'Events Page',
                () {
                  context.pushNamed(AppRoute.events.name);
                },
              ),
              _divider(context),
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
        ),

      ],
    );
  }

  Widget _divider(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 0.5,
      indent: 50,
      endIndent: 16,
      color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
    );
  }

  Widget _buildProfileOption(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 22),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
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
    );
  }

}
