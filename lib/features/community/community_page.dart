import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../data/models/community.dart';
import '../../notification/fcm_sender.dart';
import '../../notification/notification_service.dart';
import 'community_details.dart';
import 'create_community.dart';

final _currentUserId = FirebaseAuth.instance.currentUser!.uid;

class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Community'), centerTitle: true),
      bottomNavigationBar: _buildCreateCommunityButton(context),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 🔍 Search bar
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by name...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                searchQuery = '';
                              });
                            },
                          ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value.trim().toLowerCase();
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),

            // 🔥 Combine communities + my memberships
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('communities')
                  .snapshots(),
              builder: (context, allCommunitiesSnap) {
                if (!allCommunitiesSnap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allDocs = allCommunitiesSnap.data!.docs;
                final allCommunities = allDocs
                    .map(
                      (e) =>
                          Community.fromJson(e.data() as Map<String, dynamic>),
                    )
                    .toList();

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collectionGroup('members')
                      .where('uid', isEqualTo: _currentUserId)
                      .where('member', isEqualTo: true)
                      .snapshots(),
                  builder: (context, myMembershipsSnap) {
                    if (!myMembershipsSnap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    // Get my community IDs
                    final myCommunityIds = myMembershipsSnap.data!.docs
                        .map((doc) => doc.reference.parent.parent!.id)
                        .toSet();

                    final myCommunities = allCommunities
                        .where((c) => myCommunityIds.contains(c.id))
                        .where(
                          (c) => c.name.toLowerCase().contains(searchQuery),
                        )
                        .toList();

                    final otherCommunities = allCommunities
                        .where((c) => !myCommunityIds.contains(c.id))
                        .where(
                          (c) => c.name.toLowerCase().contains(searchQuery),
                        )
                        .toList();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (myCommunities.isNotEmpty)
                          Card(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                                  child: Text(
                                    'My Communities',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                _buildHorizontalCommunityList(
                                  context,
                                  myCommunities,
                                ),
                              ],
                            ),
                          ),
                        Card(
                          margin: const EdgeInsets.only(top: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Text(
                                  'Other Communities',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              _buildVerticalCommunityList(
                                context,
                                otherCommunities,
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// 🔽 Helper widgets
Widget _buildHorizontalCommunityList(
  BuildContext context,
  List<Community> communities,
) {
  return SizedBox(
    height: 150,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16),
      itemCount: communities.length,
      separatorBuilder: (context, index) => const SizedBox(width: 16),
      itemBuilder: (context, index) {
        final community = communities[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CommunityDetailsPage(communityId: community.id),
              ),
            );
          },
          child: Container(
            width: 300,
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          color: Colors.red.shade200,
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.group,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              community.name,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              spacing: 4,
                              children: [
                                Text("Code: ${community.code}"),
                                const Text("|", style: TextStyle(fontSize: 12)),
                                Text("Members: ${community.memberCount}"),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${community.address}, ${community.subDistrict}, ${community.district}',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}

Widget _buildVerticalCommunityList(
  BuildContext context,
  List<Community> communities,
) {
  if (communities.isEmpty) {
    return Container(
      height: 100,
      padding: const EdgeInsets.all(16),
      child: const Center(
        child: Text(
          'No other communities to join at the moment.',
          style: TextStyle(color: Colors.grey),
        ),
      ),
    );
  }

  return ListView.separated(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    itemCount: communities.length,
    separatorBuilder: (context, index) => const SizedBox(height: 16),
    itemBuilder: (context, index) {
      final community = communities[index];
      return GestureDetector(
        onTap: () {
          _showJoinSheet(context, community);
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey, width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    color: Colors.red.shade200,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    community.name[0],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        community.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${community.subDistrict}, ${community.district}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Members: ${community.memberCount}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

// 🔽 Join/Cancel join sheet
void _showJoinSheet(BuildContext context, Community community) {
  final memberDoc = FirebaseFirestore.instance
      .collection('communities')
      .doc(community.id)
      .collection('members')
      .doc(_currentUserId);

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) {
      return StreamBuilder<DocumentSnapshot>(
        stream: memberDoc.snapshots(),
        builder: (context, snapshot) {
          bool isRequested = false;

          if (snapshot.hasData && snapshot.data!.exists) {
            final data = snapshot.data!.data() as Map<String, dynamic>;
            if (data['member'] == false) {
              isRequested = true;
            }
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 50,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  Text(
                    community.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${community.subDistrict}, ${community.district}',
                    style: const TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Community Code: ${community.code}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Instructions to join:\n1. Press the Join Request button below.\n2. Wait for approval from community admin.',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (!isRequested) {
                          await memberDoc.set({
                            'uid': _currentUserId,
                            'member': false,
                            'createdAt': FieldValue.serverTimestamp(),
                          });

                          await FCMSender.sendToTopic(
                            topic: community.id,
                            title: 'New Join Request',
                            body: 'Someone requested to join ${community.name}',
                            data: {
                              'type': 'community',
                              'communityId': community.id,
                            },
                          );

                          await Future.wait(
                            community.admin.map((adminUid) {
                              return NotificationService.addNotification(
                                title: 'New Join Request',
                                body:
                                    'Someone requested to join your ${community.name}.',
                                type: 'community',
                                data: {'communityId': community.id},
                                userId: adminUid,
                              );
                            }),
                          );

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Join request sent')),
                          );
                        } else {
                          await memberDoc.delete();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Join request canceled'),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isRequested ? Colors.grey : Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        isRequested
                            ? 'Cancel Join Request'
                            : 'Send Join Request',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

Widget _buildCreateCommunityButton(BuildContext? context) {
  return Card(
    margin: const EdgeInsets.symmetric(vertical: 8),
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: ElevatedButton(
        onPressed: () {
          if (context != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CreateCommunityScreen(),
              ),
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          minimumSize: const Size(double.infinity, 50),
        ),
        child: const Text(
          'Create Community',
          style: TextStyle(fontSize: 16, color: Colors.white),
        ),
      ),
    ),
  );
}
