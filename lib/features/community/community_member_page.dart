import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/community.dart';
import '../../data/models/user_model.dart';
import '../emergency_donor/emergency_donor_page.dart';
import '../widgets/start_chat_btn.dart';

class CommunityMembersPage extends ConsumerWidget {
  final Community community;

  const CommunityMembersPage({super.key, required this.community});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Stream for the updated community (especially admin list)
    final communityStream = FirebaseFirestore.instance
        .collection('communities')
        .doc(community.id)
        .snapshots()
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

        // Stream for members subcollection
        final membersStream = FirebaseFirestore.instance
            .collection('communities')
            .doc(updatedCommunity.id)
            .collection('members')
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
                padding: const EdgeInsets.symmetric(vertical: 8),
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemCount: memberDocs.length,
                itemBuilder: (context, index) {
                  final memberId = memberDocs[index].id;

                  // StreamBuilder for user data
                  return StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(memberId)
                        .snapshots(),
                    builder: (context, userSnapshot) {
                      if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                        return const ListTile(title: Text(''));
                      }

                      final userData =
                          userSnapshot.data!.data() as Map<String, dynamic>;
                      final user = UserModel.fromJson(userData);
                      final name = '${user.firstName} ${user.lastName}';
                      final address =
                          '${user.currentAddress}, ${user.district}, ${user.subdistrict}';
                      final bloodGroup = user.bloodGroup;

                      final isAdmin = updatedCommunity.admin.contains(user.uid);
                      final currentUserIsAdmin = updatedCommunity.admin
                          .contains(FirebaseAuth.instance.currentUser!.uid);

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
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 20,
                                            ),
                                          )
                                        : ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              50,
                                            ),
                                            child: CachedNetworkImage(
                                              imageUrl: user.image,
                                              width: 36,
                                              height: 36,
                                              fit: BoxFit.cover,
                                              placeholder: (context, url) =>
                                                  const CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                  ),
                                              errorWidget:
                                                  (context, url, error) =>
                                                      const Icon(
                                                        Icons.error,
                                                        color: Colors.red,
                                                      ),
                                            ),
                                          ),
                                  ),
                                  if (isAdmin)
                                    const Text(
                                      'Admin',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                ],
                              ),
                              title: Text(name),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),

                                  Text('Address: $address'),
                                  const SizedBox(height: 8),
                                  Row(
                                    spacing: 8,
                                    children: [
                                      Expanded(
                                        flex: 4,
                                        child: StartChatButton(
                                          otherUserId: user.uid,
                                        ),
                                      ),

                                      //
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
                                                icon: const Icon(Icons.call),
                                                label: const Text("Call Donor"),
                                              ),
                                      ),

                                      if (currentUserIsAdmin)
                                        PopupMenuButton<String>(
                                          onSelected: (value) async {
                                            final communityDoc =
                                                FirebaseFirestore.instance
                                                    .collection('communities')
                                                    .doc(updatedCommunity.id);

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
                                                      child: const Text(
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
                                                // Remove member from members subcollection
                                                await communityDoc
                                                    .collection('members')
                                                    .doc(user.uid)
                                                    .delete();

                                                // Update member count
                                                await communityDoc.update({
                                                  'memberCount':
                                                      FieldValue.increment(-1),
                                                });
                                              }
                                            } else if (value ==
                                                'toggle_admin') {
                                              final isAlreadyAdmin =
                                                  updatedCommunity.admin
                                                      .contains(user.uid);
                                              if (isAlreadyAdmin) {
                                                await communityDoc.update({
                                                  'admin':
                                                      FieldValue.arrayRemove([
                                                        user.uid,
                                                      ]),
                                                });
                                              } else {
                                                await communityDoc.update({
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
                                          child: const Icon(Icons.more_vert),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            right: 12,
                            top: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 2,
                                horizontal: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                bloodGroup,
                                style: const TextStyle(color: Colors.white),
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
