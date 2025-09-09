import 'package:bloodfinder/data/models/community.dart';
import 'package:bloodfinder/data/models/user_model.dart';
import 'package:bloodfinder/features/widgets/start_chat_btn.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/data/providers/community_members_provider.dart';

class CommunityMembersPage extends ConsumerWidget {
  final Community community;
  const CommunityMembersPage({super.key, required this.community});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final members = ref.watch(communityMembersProvider(community.id));

    if (members.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Community Members"), centerTitle: true),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemCount:
            members.length +
            (ref.read(communityMembersProvider(community.id).notifier).hasMore
                ? 1
                : 0),
        itemBuilder: (context, index) {
          if (index == members.length) {
            // only show loading if more data exists
            ref
                .read(communityMembersProvider(community.id).notifier)
                .loadMore();
            return const Center(child: CircularProgressIndicator());
          }

          final memberDoc = members[index];
          final memberId = memberDoc.id;

          return StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(memberId)
                .snapshots(),
            builder: (context, userSnapshot) {
              if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                return const ListTile(title: Text('User not found'));
              }

              final userData =
                  userSnapshot.data!.data() as Map<String, dynamic>;
              final user = UserModel.fromJson(userData);
              final name = '${user.firstName} ${user.lastName}';
              final mobile = user.mobileNumber;
              final blood = user.bloodGroup;
              final otherUserId = user.uid;

              return Card(
                child: ListTile(
                  isThreeLine: true,
                  leading: CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.redAccent.shade200,
                    child: user.image.isEmpty
                        ? Text(
                            user.firstName.isNotEmpty
                                ? user.firstName[0].toUpperCase()
                                : '',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(50),
                            child: CachedNetworkImage(
                              imageUrl: user.image,
                              width: 36,
                              height: 36,
                              fit: BoxFit.cover,
                              placeholder: (context, url) =>
                                  CircularProgressIndicator(strokeWidth: 2),
                              errorWidget: (context, url, error) =>
                                  Icon(Icons.error, color: Colors.red),
                            ),
                          ),
                  ),

                  title: Text(name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Mobile: $mobile | Blood: $blood'),
                      const SizedBox(height: 8),
                      Row(
                        spacing: 10,
                        children: [
                          Expanded(
                            flex: 3,
                            child: StartChatButton(otherUserId: otherUserId),
                          ),
                          if (community.admin.contains(
                            FirebaseAuth.instance.currentUser!.uid,
                          ))
                            Expanded(
                              flex: 2,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  visualDensity: const VisualDensity(
                                    vertical: -3,
                                  ),
                                ),
                                onPressed: () async {
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
                                          child: const Text(
                                            'Remove',
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (confirm == true) {
                                    // Remove locally first
                                    ref
                                        .read(
                                          communityMembersProvider(
                                            community.id,
                                          ).notifier,
                                        )
                                        .removeMemberLocally(otherUserId);

                                    // Remove from Firestore
                                    await FirebaseFirestore.instance
                                        .collection('communities')
                                        .doc(community.id)
                                        .collection('members')
                                        .doc(otherUserId)
                                        .delete();

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Member removed successfully',
                                        ),
                                      ),
                                    );
                                  }
                                },
                                child: const Text('Remove'),
                              ),
                            )
                          else
                            Expanded(flex: 2, child: const SizedBox()),
                        ],
                      ),
                      const SizedBox(height: 4),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
