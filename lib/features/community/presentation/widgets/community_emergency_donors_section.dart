import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../../data/providers/repository_providers.dart';
import '../../models/community.dart';
import 'member_contact_buttons.dart';

/// Emergency donors who are members of [community], shown to everyone —
/// member or not — since without joining the community a visitor can't see
/// its regular member list, but still needs a way to reach an emergency
/// donor in an urgent situation.
class CommunityEmergencyDonorsSection extends ConsumerWidget {
  final Community community;

  const CommunityEmergencyDonorsSection({super.key, required this.community});

  Stream<List<Map<String, dynamic>>> _emergencyDonorsStream(WidgetRef ref) {
    final communityRepo = ref.read(communityRepositoryProvider);
    final userRepo = ref.read(userRepositoryProvider);

    return communityRepo
        .membersCollection()
        .where('communityId', isEqualTo: community.id)
        .snapshots()
        .asyncMap((snapshot) async {
          final userIds = snapshot.docs
              .map((doc) => doc['uid'] as String)
              .toList();
          if (userIds.isEmpty) return <Map<String, dynamic>>[];

          final donors = <Map<String, dynamic>>[];
          for (var i = 0; i < userIds.length; i += 10) {
            final chunk = userIds.sublist(
              i,
              i + 10 > userIds.length ? userIds.length : i + 10,
            );
            final usersSnap = await userRepo.getUsersByIds(chunk);
            donors.addAll(
              usersSnap.docs
                  .map((doc) => {...doc.data(), 'uid': doc.id})
                  .where((data) => data['isEmergencyDonor'] == true),
            );
          }
          return donors;
        });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _emergencyDonorsStream(ref),
      builder: (context, snapshot) {
        final donors = snapshot.data ?? [];
        final isLoading = !snapshot.hasData;

        return Container(
          width: double.infinity,
          margin: EdgeInsets.only(top: 16),
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
                      PhosphorIcons.ambulance,
                      size: 15,
                      color: Colors.red.shade600,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Emergency Donors',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? Colors.grey.shade200
                          : Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 14),
              if (isLoading)
                Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (donors.isEmpty)
                Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'No emergency donors in this community yet',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ),
                )
              else
                Column(
                  children: [
                    for (var i = 0; i < donors.length; i++) ...[
                      if (i != 0) SizedBox(height: 10),
                      _EmergencyDonorTile(donor: donors[i]),
                    ],
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}

class _EmergencyDonorTile extends ConsumerWidget {
  final Map<String, dynamic> donor;

  const _EmergencyDonorTile({required this.donor});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserId = ref.read(authRepositoryProvider).currentUser!.uid;

    final uid = donor['uid'] as String;
    final firstName = donor['firstName'] as String? ?? '';
    final lastName = donor['lastName'] as String? ?? '';
    final name = '$firstName $lastName'.trim();
    final image = donor['image'] as String? ?? '';
    final bloodGroup = donor['bloodGroup'] as String? ?? '';
    final mobile = donor['mobileNumber'] as String? ?? '';
    final address = donor['locationAddress'] as String? ?? '';

    return Container(
      decoration: BoxDecoration(
        color: Colors.red.shade50.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.red.shade100),
      ),
      padding: EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            clipBehavior: Clip.antiAlias,
            child: image.isEmpty
                ? Center(
                    child: Text(
                      firstName.isNotEmpty ? firstName[0].toUpperCase() : '?',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade600,
                      ),
                    ),
                  )
                : CachedNetworkImage(
                    imageUrl: image,
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                    placeholder: (context, url) =>
                        const CupertinoActivityIndicator(),
                    errorWidget: (context, url, error) => Icon(
                      PhosphorIcons.warningCircle,
                      color: Colors.red.shade300,
                      size: 20,
                    ),
                  ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name.isNotEmpty ? name : 'Unknown',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (bloodGroup.isNotEmpty) ...[
                      SizedBox(width: 6),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.shade600,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          bloodGroup,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (address.isNotEmpty) ...[
                  SizedBox(height: 3),
                  Text(
                    address,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (mobile.isNotEmpty)
                      ContactButton(
                        icon: PhosphorIcons.phoneCall,
                        label: 'Call',
                        color: Colors.green.shade600,
                        onTap: () => callMember(mobile),
                      ),
                    if (uid != currentUserId) ChatPillButton(otherUserId: uid),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
