import 'package:cached_network_image/cached_network_image.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/community.dart';
import '../../../../data/models/user_model.dart';
import '../../../../data/providers/repository_providers.dart';

import 'member_contact_buttons.dart';

import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

/// Live list of a community's approved members, with admin/moderator
/// management actions for users who can manage the community.
///
/// [community] is expected to already be a live-streamed, up-to-date
/// instance (admin/moderator lists must be fresh for the management menu).
class CommunityMembersList extends ConsumerStatefulWidget {
  final Community community;
  final String currentUserId;

  const CommunityMembersList({
    super.key,
    required this.community,
    required this.currentUserId,
  });

  @override
  ConsumerState<CommunityMembersList> createState() =>
      _CommunityMembersListState();
}

class _CommunityMembersListState extends ConsumerState<CommunityMembersList> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    final community = widget.community;
    final currentUserId = widget.currentUserId;

    final communityRepo = ref.read(communityRepositoryProvider);
    final userRepo = ref.read(userRepositoryProvider);

    final membersStream = communityRepo
        .membersCollection()
        .where('communityId', isEqualTo: community.id)
        .snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: membersStream,
      builder: (context, membersSnapshot) {
        if (membersSnapshot.hasError) {
          return const Center(
            child: Text('Something went wrong. Please try again.'),
          );
        }

        if (!membersSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final memberDocs = membersSnapshot.data!.docs;
        final totalMembers = memberDocs.length;

        return ListView.builder(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 16),
          itemCount: memberDocs.isEmpty ? 2 : memberDocs.length + 1,
          itemBuilder: (context, listIndex) {
            if (listIndex == 0) {
              return Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          PhosphorIcons.usersThree,
                          size: 18,
                          color: Colors.grey.shade600,
                        ),
                        SizedBox(width: 6),
                        Text(
                          '$totalMembers ${totalMembers == 1 ? 'Member' : 'Members'}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: _searchController,
                      onChanged: (value) =>
                          setState(() => _query = value.trim().toLowerCase()),
                      decoration: InputDecoration(
                        hintText: 'Search members by name or address',
                        hintStyle: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                        prefixIcon: Icon(
                          PhosphorIcons.magnifyingGlass,
                          size: 18,
                          color: Colors.grey.shade500,
                        ),
                        suffixIcon: _query.isEmpty
                            ? null
                            : IconButton(
                                icon: Icon(
                                  PhosphorIcons.x,
                                  size: 16,
                                  color: Colors.grey.shade500,
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _query = '');
                                },
                              ),
                        isDense: true,
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surface,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Theme.of(
                              context,
                            ).colorScheme.outline.withValues(alpha: 0.3),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Theme.of(
                              context,
                            ).colorScheme.outline.withValues(alpha: 0.3),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Colors.red.shade400,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            if (memberDocs.isEmpty) {
              return Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'No members yet.',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                ),
              );
            }

            final index = listIndex - 1;
            final memberData = memberDocs[index].data() as Map<String, dynamic>;
            final memberId = memberData['uid'] as String;

            return StreamBuilder<DocumentSnapshot>(
              stream: userRepo.userStream(memberId),
              builder: (context, userSnapshot) {
                if (userSnapshot.hasError) {
                  return const SizedBox.shrink();
                }

                if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                  return const SizedBox.shrink();
                }

                final userData =
                    userSnapshot.data!.data() as Map<String, dynamic>;
                final UserModel user;
                try {
                  user = UserModel.fromJson(userData);
                } catch (_) {
                  return const SizedBox.shrink();
                }
                final name = '${user.firstName} ${user.lastName}';
                final address = user.locationAddress ?? '';
                final bloodGroup = user.bloodGroup;

                if (_query.isNotEmpty &&
                    !name.toLowerCase().contains(_query) &&
                    !address.toLowerCase().contains(_query) &&
                    !bloodGroup.toLowerCase().contains(_query)) {
                  return const SizedBox.shrink();
                }

                final isAdmin = community.isAdmin(user.uid);
                final isModerator = community.isModerator(user.uid);
                final currentUserIsAdmin = community.isAdmin(currentUserId);
                final currentUserCanManage = community.canManageMembers(
                  currentUserId,
                );

                return Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Container(
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
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top row: Avatar + Name/Address + Blood group badge
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Avatar
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
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    border: Border.all(
                                      color: Colors.grey.shade100,
                                      width: 1.5,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: user.image.isEmpty
                                      ? Center(
                                          child: Text(
                                            user.firstName.isNotEmpty
                                                ? user.firstName[0]
                                                      .toUpperCase()
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
                                          errorWidget: (context, url, error) =>
                                              Icon(
                                                PhosphorIcons.warningCircle,
                                                color: Colors.red.shade300,
                                                size: 26,
                                              ),
                                        ),
                                ),
                              ),
                              SizedBox(width: 10),
                              // Name + address
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
                                        if (isAdmin) ...[
                                          SizedBox(width: 6),
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.red.shade50,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              'Admin',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.red.shade600,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                        if (isModerator) ...[
                                          SizedBox(width: 6),
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.blue.shade50,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              'Moderator',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.blue.shade600,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    SizedBox(height: 4),
                                    if (address.isNotEmpty)
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
                                ),
                              ),
                              SizedBox(width: 8),
                              // Blood group badge
                              Container(
                                padding: EdgeInsets.symmetric(
                                  vertical: 4,
                                  horizontal: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  bloodGroup,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10),
                          // Bottom row: contact buttons + manage menu
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    if (currentUserIsAdmin &&
                                        user.mobileNumber.isNotEmpty) ...[
                                      ContactButton(
                                        icon: PhosphorIcons.phoneCall,
                                        label: 'Call',
                                        color: Colors.green.shade600,
                                        onTap: () =>
                                            callMember(user.mobileNumber),
                                      ),
                                      ContactButton(
                                        icon: PhosphorIcons.chatText,
                                        label: 'SMS',
                                        color: Colors.blue.shade600,
                                        onTap: () =>
                                            smsMember(user.mobileNumber),
                                      ),
                                    ],
                                    if (user.uid != currentUserId)
                                      ChatPillButton(otherUserId: user.uid),
                                  ],
                                ),
                              ),
                              if (currentUserCanManage) ...[
                                SizedBox(width: 8),
                                PopupMenuButton<String>(
                                  onSelected: (value) async {
                                    if (value == 'remove_member') {
                                      if (isAdmin &&
                                          community.admin.length <= 1) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'A community must have at least one admin.',
                                            ),
                                          ),
                                        );
                                        return;
                                      }

                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Remove Member'),
                                          content: const Text(
                                            'Are you sure you want to remove this member?',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, false),
                                              child: const Text('Cancel'),
                                            ),
                                            OutlinedButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, true),
                                              child: Text(
                                                'Remove',
                                                style: TextStyle(
                                                  color: Colors.red,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );

                                      if (confirm == true) {
                                        try {
                                          await communityRepo.removeMember(
                                            community.id,
                                            user.uid,
                                          );
                                          await communityRepo.updateMemberCount(
                                            community.id,
                                            -1,
                                          );
                                          await communityRepo
                                              .updateBloodGroupCount(
                                                community.id,
                                                user.bloodGroup,
                                                -1,
                                              );
                                          try {
                                            await communityRepo
                                                .logCommunityAction(
                                                  communityId: community.id,
                                                  actorUid: currentUserId,
                                                  action: 'remove_member',
                                                  targetUid: user.uid,
                                                );
                                          } catch (_) {
                                            // Logging is best-effort.
                                          }
                                        } catch (_) {
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Could not remove this member. Please try again.',
                                                ),
                                              ),
                                            );
                                          }
                                        }
                                      }
                                    } else if (value == 'toggle_admin') {
                                      if (isAdmin &&
                                          community.admin.length <= 1) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'A community must have at least one admin.',
                                            ),
                                          ),
                                        );
                                        return;
                                      }
                                      try {
                                        if (isAdmin) {
                                          await communityRepo.removeAdmin(
                                            community.id,
                                            user.uid,
                                          );
                                        } else {
                                          await communityRepo.addAdmin(
                                            community.id,
                                            user.uid,
                                          );
                                        }
                                        try {
                                          await communityRepo
                                              .logCommunityAction(
                                                communityId: community.id,
                                                actorUid: currentUserId,
                                                action: isAdmin
                                                    ? 'remove_admin'
                                                    : 'make_admin',
                                                targetUid: user.uid,
                                              );
                                        } catch (_) {
                                          // Logging is best-effort.
                                        }
                                      } catch (_) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Could not update admin status. Please try again.',
                                              ),
                                            ),
                                          );
                                        }
                                      }
                                    } else if (value == 'toggle_moderator') {
                                      try {
                                        if (isModerator) {
                                          await communityRepo.removeModerator(
                                            community.id,
                                            user.uid,
                                          );
                                        } else {
                                          await communityRepo.addModerator(
                                            community.id,
                                            user.uid,
                                          );
                                        }
                                        try {
                                          await communityRepo
                                              .logCommunityAction(
                                                communityId: community.id,
                                                actorUid: currentUserId,
                                                action: isModerator
                                                    ? 'remove_moderator'
                                                    : 'make_moderator',
                                                targetUid: user.uid,
                                              );
                                        } catch (_) {
                                          // Logging is best-effort.
                                        }
                                      } catch (_) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Could not update moderator status. Please try again.',
                                              ),
                                            ),
                                          );
                                        }
                                      }
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'remove_member',
                                      child: Text('Remove Member'),
                                    ),
                                    if (currentUserIsAdmin) ...[
                                      PopupMenuItem(
                                        value: 'toggle_admin',
                                        child: Text(
                                          isAdmin
                                              ? 'Remove from Admin'
                                              : 'Make Admin',
                                        ),
                                      ),
                                      PopupMenuItem(
                                        value: 'toggle_moderator',
                                        child: Text(
                                          isModerator
                                              ? 'Remove from Moderator'
                                              : 'Make Moderator',
                                        ),
                                      ),
                                    ],
                                  ],
                                  child: Container(
                                    padding: EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      PhosphorIcons.dotsThreeVertical,
                                      size: 18,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
