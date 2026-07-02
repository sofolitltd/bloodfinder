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

class CommunityMembersPage extends ConsumerWidget {
  final Community community;

  const CommunityMembersPage({super.key, required this.community});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final communityRepo = ref.read(communityRepositoryProvider);
    final userRepo = ref.read(userRepositoryProvider);
    final currentUserId = ref.read(authRepositoryProvider).currentUser!.uid;

    final communityStream = communityRepo
        .communityStream(community.id)
        .map((doc) => Community.fromJson({...?doc.data(), 'id': doc.id}));

    return StreamBuilder<Community>(
      stream: communityStream,
      builder: (context, communitySnapshot) {
        if (!communitySnapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final updatedCommunity = communitySnapshot.data!;

        final membersStream = communityRepo
            .membersCollection()
            .where('communityId', isEqualTo: updatedCommunity.id)
            .snapshots();

        return StreamBuilder<QuerySnapshot>(
          stream: membersStream,
          builder: (context, membersSnapshot) {
            if (!membersSnapshot.hasData) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final memberDocs = membersSnapshot.data!.docs;

            return Scaffold(
              appBar: AppBar(
                title: const Text("Community Members"),
                centerTitle: true,
              ),
              body: ListView.separated(
                padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 16.w),
                separatorBuilder: (_, _) => SizedBox(height: 8.h),
                itemCount: memberDocs.length,
                itemBuilder: (context, index) {
                  final memberData =
                      memberDocs[index].data() as Map<String, dynamic>;
                  final memberId = memberData['uid'] as String;

                  return StreamBuilder<DocumentSnapshot>(
                    stream: userRepo.userStream(memberId),
                    builder: (context, userSnapshot) {
                      if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                        return const ListTile(title: Text(''));
                      }

                      final userData =
                          userSnapshot.data!.data() as Map<String, dynamic>;
                      final user = UserModel.fromJson(userData);
                      final name = '${user.firstName} ${user.lastName}';
                      final address = user.locationAddress ?? '';
                      final bloodGroup = user.bloodGroup;

                      final isAdmin = updatedCommunity.admin.contains(user.uid);
                      final currentUserIsAdmin = updatedCommunity.admin
                          .contains(currentUserId);

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
                                                  ? user.firstName[0]
                                                      .toUpperCase()
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
                                            errorWidget:
                                                (context, url, error) => Icon(
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                                overflow:
                                                    TextOverflow.ellipsis,
                                              ),
                                            ),
                                            if (isAdmin) ...[
                                              SizedBox(width: 6.w),
                                              Container(
                                                padding:
                                                    EdgeInsets.symmetric(
                                                  horizontal: 6.w,
                                                  vertical: 2.h,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.red.shade50,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          4.r),
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
                                    padding: EdgeInsets.symmetric(
                                      vertical: 4.h,
                                      horizontal: 10.w,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade50,
                                      borderRadius:
                                          BorderRadius.circular(8.r),
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
                                          side: BorderSide(
                                              color: Colors.green.shade200),
                                          padding: EdgeInsets.symmetric(
                                              vertical: 10.h),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10.r),
                                          ),
                                        ),
                                        onPressed:
                                            user.mobileNumber.isNotEmpty
                                                ? () =>
                                                    callDonor(
                                                        user.mobileNumber)
                                                : null,
                                        icon: Icon(PhosphorIcons.phoneCall,
                                            size: 16.w),
                                        label: Text(
                                          'Call',
                                          style: TextStyle(fontSize: 13.sp),
                                        ),
                                      ),
                                    ),
                                  if (currentUserIsAdmin)...[
                                    SizedBox(width: 8.w),
                                    Spacer(),
                                  ],
                                    
                                  if (currentUserIsAdmin)
                                    PopupMenuButton<String>(
                                      onSelected: (value) async {
                                        if (value == 'remove_member') {
                                          final confirm =
                                              await showDialog<bool>(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: const Text(
                                                'Remove Member',
                                              ),
                                              content: const Text(
                                                'Are you sure you want to remove this member?',
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                          context, false),
                                                  child:
                                                      const Text('Cancel'),
                                                ),
                                                OutlinedButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                          context, true),
                                                  child: Text(
                                                    'Remove',
                                                    style: TextStyle(
                                                        color: Colors.red),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );

                                          if (confirm == true) {
                                            await communityRepo.removeMember(
                                                updatedCommunity.id, user.uid);
                                            await communityRepo
                                                .updateMemberCount(
                                                    updatedCommunity.id, -1);
                                            await communityRepo
                                                .updateBloodGroupCount(
                                                    updatedCommunity.id,
                                                    user.bloodGroup,
                                                    -1);
                                          }
                                        } else if (value == 'toggle_admin') {
                                          final isAlreadyAdmin =
                                              updatedCommunity.admin
                                                  .contains(user.uid);
                                          if (isAlreadyAdmin) {
                                            await communityRepo
                                                .updateCommunity(
                                                    updatedCommunity.id, {
                                              'admin': FieldValue.arrayRemove(
                                                  [user.uid]),
                                            });
                                          } else {
                                            await communityRepo
                                                .updateCommunity(
                                                    updatedCommunity.id, {
                                              'admin': FieldValue.arrayUnion(
                                                  [user.uid]),
                                            });
                                          }
                                        }
                                      },
                                      itemBuilder: (context) => [
                                        const PopupMenuItem(
                                          value: 'remove_member',
                                          child: Text('Remove Member'),
                                        ),
                                        PopupMenuItem(
                                          value: 'toggle_admin',
                                          child: Text(
                                            isAdmin
                                                ? 'Remove from Admin'
                                                : 'Make Admin',
                                          ),
                                        ),
                                      ],
                                      child: Container(
                                        padding: EdgeInsets.all(8.w),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade100,
                                          borderRadius:
                                              BorderRadius.circular(10.r),
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
              ),
            );
          },
        );
      },
    );
  }
}
