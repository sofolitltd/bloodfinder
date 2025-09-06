import 'package:bloodfinder/features/community/community_member_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../data/models/community.dart';
import 'community_member_request.dart';
import 'group_member_by_blood.dart';

class CommunityDetailsScreen extends StatelessWidget {
  final String communityId;

  const CommunityDetailsScreen({super.key, required this.communityId});

  // Build the blood group widgets
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
      appBar: AppBar(title: const Text("My Community"), centerTitle: true),
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
                        // Top Red Banner
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
                              'Mobile',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              community.mobile,
                              style: TextStyle(
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
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Whats App',
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

                // --- Members by Blood Group Section ---
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      spacing: 8,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Members by Blood Group',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('users')
                              .where(
                                FieldPath.documentId,
                                whereIn: community.members.isEmpty
                                    ? ['dummy']
                                    : community.members,
                              )
                              .snapshots(),
                          builder: (context, userSnapshot) {
                            if (userSnapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const SizedBox(
                                height: 180,
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }

                            if (userSnapshot.hasError) {
                              return const Center(
                                child: Text('Failed to load members'),
                              );
                            }

                            final Map<String, int> bloodGroupCounts = {
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
                              final bloodGroup = doc['bloodGroup'];
                              if (bloodGroup != null &&
                                  bloodGroupCounts.containsKey(bloodGroup)) {
                                bloodGroupCounts[bloodGroup] =
                                    bloodGroupCounts[bloodGroup]! + 1;
                              }
                            }

                            return GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 4,
                                    crossAxisSpacing: 10,
                                    mainAxisSpacing: 10,
                                    childAspectRatio: 1,
                                  ),
                              itemCount: bloodGroupCounts.length,
                              itemBuilder: (context, index) {
                                final bloodGroup = bloodGroupCounts.keys
                                    .elementAt(index);
                                final count = bloodGroupCounts[bloodGroup] ?? 0;
                                return _buildBloodGroupItem(
                                  context,
                                  bloodGroup,
                                  count,
                                  community.id,
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                CommunityMembersPage(communityId: community.id),
                          ),
                        );
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("All Community Members "),
                          const SizedBox(height: 8),
                          Text(
                            "( ${community.members.length} )",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // --- Manage Community Section ---
                if (community.admin.contains(uid))
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Manage Community',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 16),

                          GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1.4,
                            children: [
                              //
                              InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          CommunityMembersPage(
                                            communityId: community.id,
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
                                      Text(
                                        "${community.members.length}",
                                        style: const TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.red,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              //
                              InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          CommunityAdminDashboard(
                                            communityId: community.id,
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
                                      Text(
                                        "${community.joinRequests.length}",
                                        style: const TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.orange,
                                        ),
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
