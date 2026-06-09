import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../../routes/app_route.dart';
import 'home_community.dart';

class HomeActionButtonsSection extends StatelessWidget {
  const HomeActionButtonsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey.shade700.withValues(alpha: 0.3) : Colors.grey.shade200,
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              _buildActionButton(
                context,
                icon: PhosphorIcons.megaphone,
                label: 'Post Blood\nRequest',
                onTap: () => context.pushNamed(AppRoute.bloodRequest.name),
              ),
              const SizedBox(width: 12),
              _buildActionButton(
                context,
                icon: PhosphorIcons.heartbeat,
                label: 'Blood\nBank',
                onTap: () => context.pushNamed(AppRoute.bloodBank.name),
              ),
              const SizedBox(width: 12),
              _buildActionButton(
                context,
                icon: PhosphorIcons.ambulance,
                label: 'Emergency\nDonors',
                onTap: () => context.pushNamed(AppRoute.emergencyDonor.name),
              ),
              const SizedBox(width: 12),
              _buildActionButton(
                context,
                icon: PhosphorIcons.usersThree,
                label: 'My\nCircle',
                onTap: () => context.pushNamed(AppRoute.myCircle.name),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const HomeCommunitySection(),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isDark
                ? Colors.grey.shade800.withValues(alpha: 0.4)
                : Colors.grey.shade50,
            border: Border.all(
              color: isDark
                  ? Colors.grey.shade700.withValues(alpha: 0.2)
                  : Colors.grey.shade200,
              width: 0.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.red.shade500, size: 28),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
