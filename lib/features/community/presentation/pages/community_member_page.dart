import 'package:cached_network_image/cached_network_image.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

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
                padding: EdgeInsets.symmetric(vertical: 8.h),
                separatorBuilder: (_, __) => SizedBox(height: 8.h),
                itemCount: memberDocs.length,
                itemBuilder: (context, index) {
                  final memberId = memberDocs[index].id;

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

                      return Stack(
                        children: [
                          Card(
                            child: ListTile(
                              isThreeLine: true,
                              leading: Column(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: Colors.redAccent.shade200,
                                    child: user.image.isEmpty
                                        ? Text(
                                            user.firstName.isNotEmpty
                                                ? user.firstName[0]
                                                      .toUpperCase()
                                                : '',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 20.sp,
                                            ),
                                          )
                                        : ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              50,
                                            ),
                                            child: CachedNetworkImage(
                                              imageUrl: user.image,
                                              width: 36.w,
                                              height: 36.h,
                                              fit: BoxFit.cover,
                                              placeholder: (context, url) =>
                                                  const CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                  ),
                                              errorWidget:
                                                  (context, url, error) => Icon(
                                                    PhosphorIcons.warningCircle,
                                                    color: Colors.red,
                                                  ),
                                            ),
                                          ),
                                  ),
                                  if (isAdmin)
                                    Text(
                                      'Admin',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                ],
                              ),
                              title: Text(name),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: 4.h),

                                  Text('Address: $address'),
                                  SizedBox(height: 8.h),
                                  Row(
                                    spacing: 8,
                                    children: [
                                      Expanded(
                                        flex: 4,
                                        child: StartChatButton(
                                          otherUserId: user.uid,
                                        ),
                                      ),

                                      Expanded(
                                        flex: 4,
                                        child: !currentUserIsAdmin
                                            ? SizedBox()
                                            : ElevatedButton.icon(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      Colors.green.shade500,
                                                  visualDensity: VisualDensity(
                                                    vertical: -3,
                                                  ),
                                                ),
                                                onPressed:
                                                    (user
                                                        .mobileNumber
                                                        .isNotEmpty)
                                                    ? () => callDonor(
                                                        user.mobileNumber,
                                                      )
                                                    : null,
                                                icon: Icon(
                                                  PhosphorIcons.phoneCall,
                                                ),
                                                label: const Text("Call Donor"),
                                              ),
                                      ),

                                      if (currentUserIsAdmin)
                                        PopupMenuButton<String>(
                                          onSelected: (value) async {
                                            if (value == 'remove_member') {
                                              final confirm = await showDialog<bool>(
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
                                                            context,
                                                            false,
                                                          ),
                                                      child: const Text(
                                                        'Cancel',
                                                      ),
                                                    ),
                                                    OutlinedButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                            context,
                                                            true,
                                                          ),
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
                                            } else if (value ==
                                                'toggle_admin') {
                                              final isAlreadyAdmin =
                                                  updatedCommunity.admin
                                                      .contains(user.uid);
                                              if (isAlreadyAdmin) {
                                                await communityRepo
                                                    .updateCommunity(
                                                        updatedCommunity.id, {
                                                  'admin':
                                                      FieldValue.arrayRemove([
                                                        user.uid,
                                                      ]),
                                                });
                                              } else {
                                                await communityRepo
                                                    .updateCommunity(
                                                        updatedCommunity.id, {
                                                  'admin':
                                                      FieldValue.arrayUnion([
                                                        user.uid,
                                                      ]),
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
                                          child: Icon(
                                            PhosphorIcons.dotsThreeVertical,
                                          ),
                                        ),
                                    ],
                                  ),
                                  SizedBox(height: 4.h),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            right: 12,
                            top: 12,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                vertical: 2.h,
                                horizontal: 8.w,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(4.r),
                              ),
                              child: Text(
                                bloodGroup,
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ],
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
