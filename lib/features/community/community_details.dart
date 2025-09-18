import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../data/models/community.dart';
import '../../data/models/member.dart';
import 'community_member_page.dart';
import 'community_member_request.dart';
import 'group_member_by_blood.dart';

class CommunityDetailsPage extends StatelessWidget {
  final String communityId;
  const CommunityDetailsPage({super.key, required this.communityId});

  String get _currentUserId => FirebaseAuth.instance.currentUser!.uid;

  // Fetch approved members
  Stream<List<Member>> _membersStream(String communityId) {
    return FirebaseFirestore.instance
        .collection('communities')
        .doc(communityId)
        .collection('members')
        .where('member', isEqualTo: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Member.fromJson(doc.data())).toList(),
        );
  }

  // Fetch pending join requests
  _joinRequestsStream(String communityId) {
    return FirebaseFirestore.instance
        .collection('communities')
        .doc(communityId)
        .collection('members')
        .where('member', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
          log('Pending requests: ${snapshot.docs.length}');
          return snapshot.docs
              .map((doc) => Member.fromJson(doc.data()))
              .toList();
        });
  }

  // Blood group item
  Widget _buildBloodGroupItem(
    BuildContext context,
    String bloodGroup,
    int count,
    String communityId,
  ) {
    final isAvailable = count > 0;
    return GestureDetector(
      onTap: isAvailable
          ? () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BloodGroupMembersScreen(
                    communityId: communityId,
                    bloodGroup: bloodGroup,
                  ),
                ),
              );
            }
          : null,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.circle_outlined,
                size: 50,
                color: isAvailable ? Colors.red : Colors.grey[300],
              ),
              Text(
                bloodGroup,
                style: TextStyle(
                  color: isAvailable ? Colors.red : Colors.grey[300],
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            '$count Members',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isAvailable ? Colors.red : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Community"),
        centerTitle: true,
        actions: [
          //create a delete btn with a dialog
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('communities')
                .doc(communityId)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || !snapshot.data!.exists) {
                return const SizedBox.shrink();
              }
              final communityData =
                  snapshot.data!.data() as Map<String, dynamic>;
              final community = Community.fromJson({
                ...communityData,
                'id': communityId,
              });
              if (community.admin.contains(_currentUserId)) {
                return IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text("Delete Community"),
                          content: const Text(
                            "Are you sure you want to delete this community? This action cannot be undone.",
                          ),
                          actions: <Widget>[
                            TextButton(
                              child: const Text("Cancel"),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                            TextButton(
                              child: const Text(
                                "Delete",
                                style: TextStyle(color: Colors.red),
                              ),
                              onPressed: () async {
                                await FirebaseFirestore.instance
                                    .collection('communities')
                                    .doc(communityId)
                                    .delete();
                                Navigator.of(context).popUntil(
                                  (route) => route.isFirst,
                                ); // Pop until the first route
                              },
                            ),
                          ],
                        );
                      },
                    );
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('communities')
            .doc(communityId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Community not found"));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final community = Community.fromJson({...data, 'id': communityId});

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Community Info Card ---
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Top Banner
                        Container(
                          width: double.infinity,
                          height: 180,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.bloodtype,
                                color: Colors.white,
                                size: 40,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                community.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                '${community.address}, ${community.subDistrict}, ${community.district}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Contact No',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              community.mobile,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),

                        if (community.facebook!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Facebook',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                community.facebook!,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800],
                                ),
                              ),
                            ],
                          ),
                        ],

                        if (community.whatsapp!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'WhatsApp',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                community.whatsapp!,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // --- Members by Blood Group ---
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Members by Blood Group',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),

                        //
                        ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 180),
                          child: StreamBuilder<List<Member>>(
                            stream: _membersStream(community.id),
                            builder: (context, memberSnapshot) {
                              if (!memberSnapshot.hasData) {
                                return SizedBox();
                              }

                              final members = memberSnapshot.data!;
                              if (members.isEmpty) {
                                return Text("No members yet");
                              }

                              return StreamBuilder<QuerySnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection('users')
                                    .where(
                                      FieldPath.documentId,
                                      whereIn: members
                                          .map((m) => m.uid)
                                          .toList(),
                                    )
                                    .snapshots(),
                                builder: (context, userSnapshot) {
                                  if (!userSnapshot.hasData) {
                                    return SizedBox();
                                  }

                                  final bloodGroupCounts = {
                                    'A+': 0,
                                    'A-': 0,
                                    'B+': 0,
                                    'B-': 0,
                                    'O+': 0,
                                    'O-': 0,
                                    'AB+': 0,
                                    'AB-': 0,
                                  };

                                  for (var doc in userSnapshot.data!.docs) {
                                    final blood = doc['bloodGroup'] as String?;
                                    if (blood != null &&
                                        bloodGroupCounts.containsKey(blood)) {
                                      bloodGroupCounts[blood] =
                                          bloodGroupCounts[blood]! + 1;
                                    }
                                  }

                                  return GridView.builder(
                                    shrinkWrap: true,
                                    physics: NeverScrollableScrollPhysics(),
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 4,
                                          crossAxisSpacing: 10,
                                          mainAxisSpacing: 10,
                                        ),
                                    itemCount: bloodGroupCounts.length,
                                    itemBuilder: (context, index) {
                                      final bg = bloodGroupCounts.keys
                                          .elementAt(index);
                                      return _buildBloodGroupItem(
                                        context,
                                        bg,
                                        bloodGroupCounts[bg]!,
                                        community.id,
                                      );
                                    },
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // --- All Community Members Button ---
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                CommunityMembersPage(community: community),
                          ),
                        );
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("All Community Members"),
                          const SizedBox(width: 4),
                          StreamBuilder<List<Member>>(
                            stream: _membersStream(community.id),
                            builder: (context, snapshot) {
                              final count =
                                  snapshot.data?.length ??
                                  community.memberCount;
                              return Text(
                                "( $count )",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // --- Admin Section: Manage Community ---
                if (community.admin.contains(uid))
                  Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Manage Community',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1.2,
                            children: [
                              // All Members
                              InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          CommunityMembersPage(
                                            community: community,
                                          ),
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.red),
                                  ),
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text(
                                        "All Members",
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      StreamBuilder<List<Member>>(
                                        stream: _membersStream(community.id),
                                        builder: (context, snapshot) {
                                          final count =
                                              snapshot.data?.length ??
                                              community.memberCount;
                                          return Text(
                                            "$count",
                                            style: const TextStyle(
                                              fontSize: 28,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.red,
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // Member Requests
                              InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          CommunityMemberRequestPage(
                                            community: community,
                                          ),
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.orange),
                                  ),
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text(
                                        "Member Requests",
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      StreamBuilder<List<Member>>(
                                        stream: _joinRequestsStream(
                                          community.id,
                                        ),
                                        builder: (context, snapshot) {
                                          if (!snapshot.hasData) {
                                            return const Text("0");
                                          }
                                          final count = snapshot.data!.length;
                                          return Text(
                                            "$count",
                                            style: const TextStyle(
                                              fontSize: 28,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.orange,
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
