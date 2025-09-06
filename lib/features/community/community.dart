import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '/data/models/community.dart';
import 'community_details.dart';
import 'create_community.dart';

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  static final _currentUserId = FirebaseAuth.instance.currentUser!.uid;

  // Logic to send a join request to a community
  Future<void> _sendJoinRequest(
    BuildContext context,
    Community community,
  ) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('communities')
          .where('code', isEqualTo: community.code)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final docId = querySnapshot.docs.first.id;
        await FirebaseFirestore.instance
            .collection('communities')
            .doc(docId)
            .update({
              'joinRequests': FieldValue.arrayUnion([_currentUserId]),
            });

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Join request sent!')));
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Community not found.')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to send request: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Community'),
        centerTitle: true,
        actions: [
          // todo: for developer
          // AdminWidget(
          //   child: IconButton(
          //     icon: const Icon(Icons.admin_panel_settings),
          //     onPressed: () {
          //       Navigator.push(
          //         context,
          //         MaterialPageRoute(
          //           builder: (_) => const AdminCommunityScreen(),
          //         ),
          //       );
          //     },
          //   ),
          // ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 10,
          children: [
            // StreamBuilder for "My Communities" horizontal list
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('communities')
                  .where('members', arrayContains: _currentUserId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(); // or a loader if needed
                }

                if (snapshot.hasError) {
                  return const SizedBox(); // or display error if needed
                }

                // If the user is not a member of any community, return an empty widget
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const SizedBox(); // <-- Hides the card
                }

                // Convert Firestore docs to Community list
                final communities = snapshot.data!.docs
                    .map(
                      (doc) => Community.fromJson(
                        doc.data() as Map<String, dynamic>,
                      ),
                    )
                    .toList();

                return Card(
                  margin: const EdgeInsets.only(top: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
                        child: Text(
                          'My Communities',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      //
                      _buildHorizontalCommunityList(context, communities),

                      SizedBox(height: 8),
                    ],
                  ),
                );
              },
            ),

            //
            Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                    child: Text(
                      'All Communities',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  // StreamBuilder for "Other Communities" vertical list
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('communities')
                        .where('members', isNotEqualTo: [_currentUserId])
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return const Center(
                          child: Text('Error loading communities'),
                        );
                      }
                      final communities = snapshot.data!.docs
                          .map(
                            (doc) => Community.fromJson(
                              doc.data() as Map<String, dynamic>,
                            ),
                          )
                          .toList();
                      // Filter out communities where the user is already a member
                      final otherCommunities = communities
                          .where(
                            (community) =>
                                !community.members.contains(_currentUserId),
                          )
                          .toList();
                      return _buildVerticalCommunityList(
                        context,
                        otherCommunities,
                      );
                    },
                  ),
                ],
              ),
            ),

            //
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CreateCommunityScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text(
                    'Create Community',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  //
  // Helper widgets to build the horizontal list of communities
  Widget _buildHorizontalCommunityList(
    BuildContext context,
    List<Community> communities,
  ) {
    //
    return SizedBox(
      height: 140, // Fixed height for the horizontal list
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
                  builder: (_) =>
                      CommunityDetailsScreen(communityId: community.id),
                ),
              );
            },
            child: Container(
              width: 350,
              decoration: BoxDecoration(
                // color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    //
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 12,
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

                        //
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              //
                              Text(
                                community.name,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),

                              //
                              SizedBox(height: 4),
                              Row(
                                spacing: 12,
                                children: [
                                  Text(
                                    "Code: ${community.code}",
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(),
                                  ),

                                  Text(
                                    "|",
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12),
                                  ),

                                  Text(
                                    'Members: ${community.members.length}',
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 4),
                    //
                    Text(
                      '${community.address}, ${community.subDistrict}, ${community.district}',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(),
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

  // Helper widgets to build the vertical list of communities
  Widget _buildVerticalCommunityList(
    BuildContext context,
    List<Community> communities,
  ) {
    if (communities.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'No other communities to join at the moment.',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }
    return ListView.separated(
      shrinkWrap: true, // Use this with SingleChildScrollView
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      itemCount: communities.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final community = communities[index];
        return GestureDetector(
          onTap: () {
            // Handle join request
            _sendJoinRequest(context, community);
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
                          'Community code: ${community.code}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.person_add,
                    color: community.joinRequests.contains(_currentUserId)
                        ? Colors.grey
                        : Colors.blue,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
