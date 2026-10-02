import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../models/community.dart';
import 'blood_group_grid.dart';
import 'community_emergency_donors_section.dart';

/// Content for the "Blood" tab: members-by-blood-group card, with the same
/// tappable grid (drilling into each group's member list) shown to everyone,
/// member or not — matching the rest of the app, where blood group members
/// are discoverable without joining the community first.
class BloodTabSection extends StatelessWidget {
  final Community community;

  const BloodTabSection({super.key, required this.community});

  @override
  Widget build(BuildContext context) {
    final counts = community.bloodGroupCounts ?? {};
    final hasAnyMember = counts.values.any((c) => c > 0);

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final card = Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  PhosphorIcons.drop,
                  size: 15,
                  color: Colors.red.shade600,
                ),
              ),
              SizedBox(width: 8),
              Text(
                'Members by Blood Group',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey.shade200 : Colors.grey.shade800,
                ),
              ),
            ],
          ),
          SizedBox(height: 14),
          if (!hasAnyMember)
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'No approved members yet',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                ),
              ),
            )
          else
            BloodGroupGrid(community: community),
        ],
      ),
    );

    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        card,
        CommunityEmergencyDonorsSection(community: community),
      ],
    );
  }
}
