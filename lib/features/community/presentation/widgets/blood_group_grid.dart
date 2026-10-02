import 'package:flutter/material.dart';

import '../../models/community.dart';
import '../pages/group_member_by_blood_page.dart';

/// Blood groups with member counts, laid out as two rows of four tiles
/// (instead of a GridView, to avoid grid/column sizing sync issues), drilling
/// into [BloodGroupMembersScreen] for groups that have at least one member.
class BloodGroupGrid extends StatelessWidget {
  final Community community;

  const BloodGroupGrid({super.key, required this.community});

  static const _allBloodGroups = [
    'A+',
    'A-',
    'B+',
    'B-',
    'O+',
    'O-',
    'AB+',
    'AB-',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildRow(context, _allBloodGroups.sublist(0, 4)),
        SizedBox(height: 10),
        _buildRow(context, _allBloodGroups.sublist(4, 8)),
      ],
    );
  }

  Widget _buildRow(BuildContext context, List<String> bloodGroups) {
    return Row(
      children: [
        for (final bg in bloodGroups) ...[
          Expanded(
            child: _BloodGroupTile(community: community, bloodGroup: bg),
          ),
          if (bg != bloodGroups.last) SizedBox(width: 10),
        ],
      ],
    );
  }
}

class _BloodGroupTile extends StatelessWidget {
  final Community community;
  final String bloodGroup;

  const _BloodGroupTile({required this.community, required this.bloodGroup});

  @override
  Widget build(BuildContext context) {
    final counts = community.bloodGroupCounts ?? {};
    final count = counts[bloodGroup] ?? 0;
    final isAvailable = count > 0;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isAvailable
          ? Colors.red.shade50
          : (isDark ? Colors.grey.shade800 : Colors.grey.shade100),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: isAvailable
            ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BloodGroupMembersScreen(
                      communityId: community.id,
                      bloodGroup: bloodGroup,
                    ),
                  ),
                );
              }
            : null,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isAvailable
                  ? Colors.red.shade200
                  : (isDark ? Colors.grey.shade700 : Colors.grey.shade200),
              width: 1,
            ),
          ),
          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isAvailable
                      ? Colors.red.shade100
                      : (isDark ? Colors.grey.shade700 : Colors.grey.shade200),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  bloodGroup,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isAvailable
                        ? Colors.red.shade700
                        : Colors.grey.shade500,
                  ),
                ),
              ),
              SizedBox(height: 4),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isAvailable
                      ? Colors.red.shade600
                      : Colors.grey.shade400,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                'member${count == 1 ? '' : 's'}',
                style: TextStyle(
                  fontSize: 10,
                  color: isAvailable
                      ? Colors.grey.shade600
                      : Colors.grey.shade400,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
