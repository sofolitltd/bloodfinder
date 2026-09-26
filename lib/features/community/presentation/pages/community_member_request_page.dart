import 'package:bloodfinder/features/notification/services/fcm_sender.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/community.dart';
import '../../models/member.dart';
import '../../../../data/models/user_model.dart';
import '../../../../data/providers/repository_providers.dart';

import '../../../notification/services/notification_service.dart';

import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

class CommunityMemberRequestPage extends ConsumerWidget {
  final Community community;

  const CommunityMemberRequestPage({super.key, required this.community});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final communityRepo = ref.read(communityRepositoryProvider);
    final userRepo = ref.read(userRepositoryProvider);
    final currentUserId = ref.read(authRepositoryProvider).currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Join Requests'),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: communityRepo.pendingMembersStream(community.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text('Something went wrong. Please try again.'),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No pending join requests.'));
          }

          final requests = snapshot.data!.docs
              .map((doc) {
                try {
                  return Member.fromJson(doc.data() as Map<String, dynamic>);
                } catch (_) {
                  return null;
                }
              })
              .whereType<Member>()
              // Admin-issued invites awaiting the invitee's own response
              // aren't requests for the admin to approve — they're filtered
              // out here so they don't show up as if action is needed.
              .where((m) => m.source != 'invited')
              .toList();

          if (requests.isEmpty) {
            return const Center(child: Text('No pending join requests.'));
          }

          return ListView.separated(
            separatorBuilder: (context, index) => SizedBox(height: 8.h),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final member = requests[index];
              return StreamBuilder<DocumentSnapshot>(
                stream: userRepo.userStream(member.uid),
                builder: (context, userSnapshot) {
                  if (userSnapshot.hasError) {
                    return const ListTile(
                      title: Text('Could not load this user'),
                    );
                  }

                  if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                    return ListTile(title: Text('User not found'));
                  }

                  final userData =
                      userSnapshot.data!.data() as Map<String, dynamic>;
                  UserModel user;
                  try {
                    user = UserModel.fromJson(userData);
                  } catch (_) {
                    return const ListTile(
                      title: Text('Could not load this user'),
                    );
                  }
                  final name = '${user.firstName} ${user.lastName}';
                  final mobile = user.mobileNumber;
                  final blood = user.bloodGroup;
                  final email = user.email;
                  final token = user.token;
                  final address = user.locationAddress ?? '';

                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(child: Icon(PhosphorIcons.user)),
                      title: Text(name),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Blood: $blood | Mobile: $mobile'),
                          Text('Email: $email'),
                          Text('Address: $address'),

                          SizedBox(height: 8.h),

                          Row(
                            spacing: 8,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                ),
                                label: Text(
                                  'Accept',
                                  style: TextStyle(color: Colors.green),
                                ),
                                icon: Icon(
                                  Icons.check,
                                  color: Colors.green,
                                ),
                                onPressed: () async {
                                  try {
                                    await communityRepo
                                        .approveMemberAndUpdateCounts(
                                            community.id,
                                            member.uid,
                                            user.bloodGroup);
                                    try {
                                      await communityRepo.logCommunityAction(
                                        communityId: community.id,
                                        actorUid: currentUserId,
                                        action: 'approve_member',
                                        targetUid: member.uid,
                                      );
                                    } catch (_) {
                                      // Logging is best-effort.
                                    }
                                  } catch (_) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              'Could not accept this request. Please try again.'),
                                        ),
                                      );
                                    }
                                    return;
                                  }

                                  try {
                                    await FCMSender.sendToToken(
                                      token: token,
                                      title: 'Accept Member Request',
                                      body:
                                          'Your request to join ${community.name} has been approved.',
                                      data: {
                                        'type': 'community',
                                        'communityId': community.id,
                                      },
                                    );

                                    await NotificationService.addNotification(
                                      title: 'Accept Member Request',
                                      body:
                                          'Your request to join ${community.name} has been approved.',
                                      type: 'community',
                                      data: {'communityId': community.id},
                                      userId: user.uid,
                                    );
                                  } catch (_) {
                                    // Member was already added; a failed
                                    // notification shouldn't surface as an error.
                                  }
                                },
                              ),

                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                ),
                                label: Text(
                                  'Cancel',
                                  style: TextStyle(color: Colors.red),
                                ),
                                icon: Icon(
                                  PhosphorIcons.x,
                                  color: Colors.red,
                                ),
                                onPressed: () async {
                                  try {
                                    await communityRepo.removeMember(
                                        community.id, member.uid);
                                    try {
                                      await communityRepo.logCommunityAction(
                                        communityId: community.id,
                                        actorUid: currentUserId,
                                        action: 'decline_member',
                                        targetUid: member.uid,
                                      );
                                    } catch (_) {
                                      // Logging is best-effort.
                                    }
                                  } catch (_) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              'Could not cancel this request. Please try again.'),
                                        ),
                                      );
                                    }
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                      isThreeLine: true,
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
