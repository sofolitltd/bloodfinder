import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '/data/models/community.dart';
import '/data/models/member.dart';
import '/features/community/edit_community.dart';
import '/notification/fcm_sender.dart';
import '/notification/notification_service.dart';
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
  Stream<List<Member>> _joinRequestsStream(String communityId) {
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

  // Add this helper function within your State class (or outside, if you prefer)
  Stream<DocumentSnapshot> _currentUserMemberStatusStream(String communityId) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return FirebaseFirestore.instance
        .collection('communities')
        .doc(communityId)
        .collection('members')
        .doc(uid)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final uid = _currentUserId; // Use the class variable

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
              if (community.admin.contains(uid)) {
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
                        Stack(
                          alignment: AlignmentGeometry.topRight,
                          children: [
                            //
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
                                  Container(
                                    width: 64,
                                    height: 64,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(100),
                                      border: Border.all(
                                        color: Colors.grey,
                                        width: .5,
                                      ),
                                      color: Colors.white,
                                    ),
                                    alignment: Alignment.center,
                                    child: community.images.isEmpty
                                        ? Text(
                                            community.name.isNotEmpty
                                                ? community.name[0]
                                                      .toUpperCase()
                                                : '',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.red.shade100,
                                            ),
                                          )
                                        : ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              100,
                                            ),
                                            child: CachedNetworkImage(
                                              imageUrl: community.images.first,
                                              width: 64,
                                              height: 64,
                                              fit: BoxFit.cover,
                                              placeholder: (context, url) =>
                                                  CupertinoActivityIndicator(),
                                              errorWidget:
                                                  (context, url, error) => Icon(
                                                    Icons.error,
                                                    color: Colors.red,
                                                  ),
                                            ),
                                          ),
                                  ),

                                  //
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

                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              spacing: 0,
                              children: [
                                //
                                if (community.admin.contains(uid))
                                  IconButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => EditCommunity(
                                            community: community,
                                          ),
                                        ),
                                      );
                                    },
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Colors.white,
                                    ),
                                  ),

                                //
                                IconButton.filledTonal(
                                  style: IconButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    visualDensity: VisualDensity.compact,
                                    padding: const EdgeInsets.all(0),
                                  ),
                                  onPressed: () {
                                    //
                                    SharePlus.instance.share(
                                      ShareParams(
                                        title: "Share Community",
                                        text:
                                            "Blood Finder\n\nCommunity: ${community.name}\n\nCheck out our community:\n https://bloodfinder.web.app/open-app.html?community=${community.id}",
                                      ),
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.share,
                                    color: Colors.red,
                                  ),
                                ),
                                SizedBox(width: 8),
                              ],
                            ),

                            // edit btn (Only show edit button if current user is an admin)
                          ],
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

                // 🌟 NEW: Check Current User's Member Status to show member content 🌟
                StreamBuilder<DocumentSnapshot>(
                  stream: _currentUserMemberStatusStream(community.id),
                  builder: (context, memberStatusSnapshot) {
                    bool isApprovedMember = false;

                    if (memberStatusSnapshot.hasData &&
                        memberStatusSnapshot.data!.exists) {
                      final memberData =
                          memberStatusSnapshot.data!.data()
                              as Map<String, dynamic>?;
                      // Check if 'member' field is explicitly true
                      if (memberData != null && memberData['member'] == true) {
                        isApprovedMember = true;
                      }
                    }

                    if (isApprovedMember) {
                      // ➡️ Show Member-Only Content
                      return Column(
                        children: [
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
                                    constraints: const BoxConstraints(
                                      minHeight: 180,
                                    ),
                                    child: StreamBuilder<List<Member>>(
                                      stream: _membersStream(community.id),
                                      builder: (context, memberSnapshot) {
                                        if (!memberSnapshot.hasData) {
                                          return const SizedBox();
                                        }

                                        final members = memberSnapshot.data!;
                                        if (members.isEmpty) {
                                          return const Text(
                                            "No approved members yet",
                                          );
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
                                              return const SizedBox();
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

                                            for (var doc
                                                in userSnapshot.data!.docs) {
                                              final blood =
                                                  doc['bloodGroup'] as String?;
                                              if (blood != null &&
                                                  bloodGroupCounts.containsKey(
                                                    blood,
                                                  )) {
                                                bloodGroupCounts[blood] =
                                                    bloodGroupCounts[blood]! +
                                                    1;
                                              }
                                            }

                                            return GridView.builder(
                                              shrinkWrap: true,
                                              physics:
                                                  const NeverScrollableScrollPhysics(),
                                              gridDelegate:
                                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                                    crossAxisCount: 4,
                                                    crossAxisSpacing: 10,
                                                    mainAxisSpacing: 10,
                                                  ),
                                              itemCount:
                                                  bloodGroupCounts.length,
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
                                          CommunityMembersPage(
                                            community: community,
                                          ),
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
                        ],
                      );
                    } else {
                      // ➡️ Show Join Request Card if not an approved member
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  builder: (context) =>
                                      _showJoinSheet(context, community),
                                );
                              },
                              icon: const Icon(Icons.group_add),
                              label: const Text('View Join Instructions'),
                            ),
                          ),
                        ),
                      );
                    }
                  },
                ),

                // --- Admin Section: Manage Community (Keep this outside the member check but inside the admin check) ---
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

  // 🔽 Join/Cancel join sheet
  _showJoinSheet(BuildContext context, Community community) {
    final memberDoc = FirebaseFirestore.instance
        .collection('communities')
        .doc(community.id)
        .collection('members')
        .doc(_currentUserId);

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
                          'member': false, // Request state
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
                      // Close the bottom sheet after action
                      if (context.mounted) {
                        Navigator.of(context).pop();
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
                      isRequested ? 'Cancel Join Request' : 'Send Join Request',
                      style: const TextStyle(color: Colors.white),
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
  }
}
