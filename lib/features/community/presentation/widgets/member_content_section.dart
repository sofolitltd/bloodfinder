import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';


import '../../models/community.dart';
import '../../providers/community_provider.dart';
import '../pages/community_member_page.dart';
import '../pages/group_member_by_blood_page.dart';

class MemberContentSection extends ConsumerWidget {
  final Community community;
  final String uid;

  const MemberContentSection({
    super.key,
    required this.community,
    required this.uid,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allBloodGroups = ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'];
    final counts = community.bloodGroupCounts ?? {};
    final hasAnyMember = counts.values.any((c) => c > 0);

    return Column(
      children: [
        // Members by Blood Group
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
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
                    child: Icon(PhosphorIcons.drop,
                        size: 15, color: Colors.red.shade600),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Members by Blood Group',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (!hasAnyMember)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'No approved members yet',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: allBloodGroups.map((bg) {
                    final count = counts[bg] ?? 0;
                    final isAvailable = count > 0;
                    return GestureDetector(
                      onTap: isAvailable
                          ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => BloodGroupMembersScreen(
                                    communityId: community.id,
                                    bloodGroup: bg,
                                  ),
                                ),
                              );
                            }
                          : null,
                      child: Container(
                        width: (MediaQuery.of(context).size.width -
                                32 -
                                32 -
                                3 * 8) /
                            4,
                        decoration: BoxDecoration(
                          color: isAvailable
                              ? Colors.red.shade50
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isAvailable
                                ? Colors.red.shade200
                                : Colors.grey.shade200,
                            width: 1,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 4),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              bg,
                              style: TextStyle(
                                color: isAvailable
                                    ? Colors.red.shade700
                                    : Colors.grey.shade400,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 6),
                              child: Container(
                                height: 1,
                                width: 24,
                                color: isAvailable
                                    ? Colors.red.shade200
                                    : Colors.grey.shade300,
                              ),
                            ),
                            Text(
                              '$count',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isAvailable
                                    ? Colors.red.shade600
                                    : Colors.grey.shade400,
                              ),
                            ),
                            Text(
                              'member${count == 1 ? '' : 's'}',
                              style: TextStyle(
                                fontSize: 11,
                                color: isAvailable
                                    ? Colors.grey.shade600
                                    : Colors.grey.shade400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // All Community Members button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      CommunityMembersPage(community: community),
                ),
              );
            },
            icon: const Icon(PhosphorIcons.usersThree, size: 20),
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'All Community Members',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 6),
                ref.watch(membersStreamProvider(community.id)).when(
                  data: (members) => Text(
                    '(${members.length})',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  loading: () => Text(
                    '(${community.memberCount})',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  error: (_, __) => Text(
                    '(${community.memberCount})',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
            style: ElevatedButton.styleFrom(
              elevation: 0,
              minimumSize: const Size(double.infinity, 52),
            ),
          ),
        ),

        const SizedBox(height: 8),
      ],
    );
  }
}
