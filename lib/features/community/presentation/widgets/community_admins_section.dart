import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../../data/models/user_model.dart';
import '../../../../data/providers/repository_providers.dart';
import '../../models/community.dart';
import 'member_contact_buttons.dart';

/// Read-only list of a community's admins and moderators, so members can
/// see who to reach out to.
class CommunityAdminsSection extends ConsumerWidget {
  final Community community;

  const CommunityAdminsSection({super.key, required this.community});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userRepo = ref.read(userRepositoryProvider);
    final currentUserId = ref.read(authRepositoryProvider).currentUser!.uid;

    final entries = <MapEntry<String, bool>>[
      ...community.admin.map((uid) => MapEntry(uid, true)),
      ...community.moderators
          .where((uid) => !community.admin.contains(uid))
          .map((uid) => MapEntry(uid, false)),
    ];

    if (entries.isEmpty) {
      return Center(
        child: Text(
          'No admins found',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.all(16),
      separatorBuilder: (_, _) => SizedBox(height: 8),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final uid = entries[index].key;
        final isAdmin = entries[index].value;

        return StreamBuilder<DocumentSnapshot>(
          stream: userRepo.userStream(uid),
          builder: (context, snapshot) {
            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const SizedBox.shrink();
            }

            final userData = snapshot.data!.data() as Map<String, dynamic>;
            final UserModel user;
            try {
              user = UserModel.fromJson(userData);
            } catch (_) {
              return const SizedBox.shrink();
            }

            final name = '${user.firstName} ${user.lastName}';
            final address = user.locationAddress ?? '';
            final bloodGroup = user.bloodGroup;

            return Container(
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
              padding: EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: user.image.isEmpty
                        ? null
                        : () => _showFullImage(
                            context,
                            imageUrl: user.image,
                            name: name,
                            bloodGroup: bloodGroup,
                          ),
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: user.image.isEmpty
                          ? Center(
                              child: Text(
                                user.firstName.isNotEmpty
                                    ? user.firstName[0].toUpperCase()
                                    : '',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red.shade600,
                                ),
                              ),
                            )
                          : CachedNetworkImage(
                              imageUrl: user.image,
                              width: 64,
                              height: 64,
                              fit: BoxFit.cover,
                              placeholder: (context, url) =>
                                  const CupertinoActivityIndicator(),
                              errorWidget: (context, url, error) => Icon(
                                PhosphorIcons.warningCircle,
                                color: Colors.red.shade300,
                                size: 26,
                              ),
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
                            Flexible(
                              child: Text(
                                name,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(width: 6),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isAdmin
                                    ? Colors.red.shade50
                                    : Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                isAdmin ? 'Admin' : 'Moderator',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isAdmin
                                      ? Colors.red.shade600
                                      : Colors.blue.shade600,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (address.isNotEmpty) ...[
                          SizedBox(height: 4),
                          Text(
                            address,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        if (user.mobileNumber.isNotEmpty ||
                            uid != currentUserId) ...[
                          SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              if (user.mobileNumber.isNotEmpty) ...[
                                ContactButton(
                                  icon: PhosphorIcons.phoneCall,
                                  label: 'Call',
                                  color: Colors.green.shade600,
                                  onTap: () => callMember(user.mobileNumber),
                                ),
                                ContactButton(
                                  icon: PhosphorIcons.chatText,
                                  label: 'SMS',
                                  color: Colors.blue.shade600,
                                  onTap: () => smsMember(user.mobileNumber),
                                ),
                              ],
                              if (uid != currentUserId)
                                ChatPillButton(otherUserId: uid),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showFullImage(
    BuildContext context, {
    required String imageUrl,
    required String name,
    required String bloodGroup,
  }) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.all(20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              InteractiveViewer(
                maxScale: 4,
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.contain,
                  width: double.infinity,
                  placeholder: (context, url) => const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CupertinoActivityIndicator()),
                  ),
                  errorWidget: (context, url, error) => Padding(
                    padding: EdgeInsets.all(40),
                    child: Icon(
                      PhosphorIcons.warningCircle,
                      color: Colors.white54,
                      size: 32,
                    ),
                  ),
                ),
              ),
              // Name + blood group caption
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: EdgeInsets.fromLTRB(16, 36, 16, 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.75),
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (bloodGroup.isNotEmpty) ...[
                        SizedBox(width: 8),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.shade600,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            bloodGroup,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              // Close button
              Positioned(
                top: 8,
                right: 8,
                child: Material(
                  color: Colors.black45,
                  shape: const CircleBorder(),
                  child: IconButton(
                    icon: Icon(PhosphorIcons.x, color: Colors.white, size: 20),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
