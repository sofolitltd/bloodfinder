import 'package:cached_network_image/cached_network_image.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/community.dart';
import '../../../../data/models/user_model.dart';
import '../../../../data/providers/repository_providers.dart';

import '../../../emergency_donor/presentation/pages/emergency_donor_page.dart';

import '../../../../shared/widgets/start_chat_btn.dart';

import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

/// Live list of a community's approved members, with admin/moderator
/// management actions for users who can manage the community.
///
/// [community] is expected to already be a live-streamed, up-to-date
/// instance (admin/moderator lists must be fresh for the management menu).
class CommunityMembersList extends ConsumerWidget {
  final Community community;
  final String currentUserId;

  const CommunityMembersList({
    super.key,
    required this.community,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

        return ListView.separated(
          padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 16.w),
          separatorBuilder: (_, _) => SizedBox(height: 8.h),
          itemCount: memberDocs.length,
          itemBuilder: (context, index) {
            final memberData = memberDocs[index].data() as Map<String, dynamic>;
            final memberId = memberData['uid'] as String;

            return StreamBuilder<DocumentSnapshot>(
              stream: userRepo.userStream(memberId),
              builder: (context, userSnapshot) {
                if (userSnapshot.hasError) {
                  return const ListTile(title: Text('Could not load this member'));
                }

                if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                  return const ListTile(title: Text(''));
                }

                final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                final UserModel user;
                try {
                  user = UserModel.fromJson(userData);
                } catch (_) {
                  return const ListTile(title: Text('Could not load this member'));
                }
                final name = '${user.firstName} ${user.lastName}';
                final address = user.locationAddress ?? '';
                final bloodGroup = user.bloodGroup;

                final isAdmin = community.isAdmin(user.uid);
                final isModerator = community.isModerator(user.uid);
                final currentUserIsAdmin = community.isAdmin(currentUserId);
                final currentUserCanManage = community.canManageMembers(currentUserId);

                return Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(12.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top row: Avatar + Name/Address + Blood group badge
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Avatar
                            Container(
                              width: 44.w,
                              height: 44.h,
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: user.image.isEmpty
                                  ? Center(
                                      child: Text(
                                        user.firstName.isNotEmpty
                                            ? user.firstName[0].toUpperCase()
                                            : '',
                                        style: TextStyle(
                                          fontSize: 18.sp,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.red.shade600,
                                        ),
                                      ),
                                    )
                                  : CachedNetworkImage(
                                      imageUrl: user.image,
                                      width: 44.w,
                                      height: 44.h,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) =>
                                          const CupertinoActivityIndicator(),
                                      errorWidget: (context, url, error) => Icon(
                                        PhosphorIcons.warningCircle,
                                        color: Colors.red.shade300,
                                        size: 22.w,
                                      ),
                                    ),
                            ),
                            SizedBox(width: 10.w),
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
                                            fontSize: 15.sp,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (isAdmin) ...[
                                        SizedBox(width: 6.w),
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 6.w,
                                            vertical: 2.h,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.red.shade50,
                                            borderRadius: BorderRadius.circular(4.r),
                                          ),
                                          child: Text(
                                            'Admin',
                                            style: TextStyle(
                                              fontSize: 10.sp,
                                              color: Colors.red.shade600,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                      if (isModerator) ...[
                                        SizedBox(width: 6.w),
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 6.w,
                                            vertical: 2.h,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.shade50,
                                            borderRadius: BorderRadius.circular(4.r),
                                          ),
                                          child: Text(
                                            'Moderator',
                                            style: TextStyle(
                                              fontSize: 10.sp,
                                              color: Colors.blue.shade600,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  SizedBox(height: 4.h),
                                  if (address.isNotEmpty)
                                    Text(
                                      address,
                                      style: TextStyle(
                                        fontSize: 13.sp,
                                        color: Colors.grey.shade600,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            ),
                            SizedBox(width: 8.w),
                            // Blood group badge
                            Container(
                              padding: EdgeInsets.symmetric(vertical: 4.h, horizontal: 10.w),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: Text(
                                bloodGroup,
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12.h),
                        // Action buttons row
                        Row(
                          children: [
                            SizedBox(
                              height: 36,
                              width: 150,
                              child: StartChatButton(
                                otherUserId: user.uid,
                                buttonText: 'Chat',
                              ),
                            ),
                            SizedBox(width: 8.w),
                            if (currentUserIsAdmin)
                              SizedBox(
                                height: 36,
                                width: 64,
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.green.shade700,
                                    side: BorderSide(color: Colors.green.shade200),
                                    padding: EdgeInsets.symmetric(vertical: 10.h),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10.r),
                                    ),
                                  ),
                                  onPressed: user.mobileNumber.isNotEmpty
                                      ? () => callDonor(user.mobileNumber)
                                      : null,
                                  icon: Icon(PhosphorIcons.phoneCall, size: 16.w),
                                  label: Text('Call', style: TextStyle(fontSize: 13.sp)),
                                ),
                              ),
                            if (currentUserCanManage) ...[
                              SizedBox(width: 8.w),
                              Spacer(),
                            ],

                            if (currentUserCanManage)
                              PopupMenuButton<String>(
                                onSelected: (value) async {
                                  if (value == 'remove_member') {
                                    if (isAdmin && community.admin.length <= 1) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              'A community must have at least one admin.'),
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
                                            onPressed: () => Navigator.pop(context, false),
                                            child: const Text('Cancel'),
                                          ),
                                          OutlinedButton(
                                            onPressed: () => Navigator.pop(context, true),
                                            child: Text(
                                              'Remove',
                                              style: TextStyle(color: Colors.red),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (confirm == true) {
                                      try {
                                        await communityRepo.removeMember(
                                            community.id, user.uid);
                                        await communityRepo.updateMemberCount(
                                            community.id, -1);
                                        await communityRepo.updateBloodGroupCount(
                                            community.id, user.bloodGroup, -1);
                                        try {
                                          await communityRepo.logCommunityAction(
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
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                  'Could not remove this member. Please try again.'),
                                            ),
                                          );
                                        }
                                      }
                                    }
                                  } else if (value == 'toggle_admin') {
                                    if (isAdmin && community.admin.length <= 1) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              'A community must have at least one admin.'),
                                        ),
                                      );
                                      return;
                                    }
                                    try {
                                      if (isAdmin) {
                                        await communityRepo.removeAdmin(
                                            community.id, user.uid);
                                      } else {
                                        await communityRepo.addAdmin(community.id, user.uid);
                                      }
                                      try {
                                        await communityRepo.logCommunityAction(
                                          communityId: community.id,
                                          actorUid: currentUserId,
                                          action: isAdmin ? 'remove_admin' : 'make_admin',
                                          targetUid: user.uid,
                                        );
                                      } catch (_) {
                                        // Logging is best-effort.
                                      }
                                    } catch (_) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                'Could not update admin status. Please try again.'),
                                          ),
                                        );
                                      }
                                    }
                                  } else if (value == 'toggle_moderator') {
                                    try {
                                      if (isModerator) {
                                        await communityRepo.removeModerator(
                                            community.id, user.uid);
                                      } else {
                                        await communityRepo.addModerator(
                                            community.id, user.uid);
                                      }
                                      try {
                                        await communityRepo.logCommunityAction(
                                          communityId: community.id,
                                          actorUid: currentUserId,
                                          action:
                                              isModerator ? 'remove_moderator' : 'make_moderator',
                                          targetUid: user.uid,
                                        );
                                      } catch (_) {
                                        // Logging is best-effort.
                                      }
                                    } catch (_) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                'Could not update moderator status. Please try again.'),
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
                                        isAdmin ? 'Remove from Admin' : 'Make Admin',
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'toggle_moderator',
                                      child: Text(
                                        isModerator ? 'Remove from Moderator' : 'Make Moderator',
                                      ),
                                    ),
                                  ],
                                ],
                                child: Container(
                                  padding: EdgeInsets.all(8.w),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(10.r),
                                  ),
                                  child: Icon(
                                    PhosphorIcons.dotsThreeVertical,
                                    size: 18.w,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
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
