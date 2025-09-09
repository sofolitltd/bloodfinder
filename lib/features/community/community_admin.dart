import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '/data/models/community.dart';

class AdminCommunityScreen extends StatelessWidget {
  const AdminCommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Dashboard'), centerTitle: true),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('communities')
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No communities to manage.'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final community = Community.fromJson(
                doc.data() as Map<String, dynamic>,
              );
              final communityDocId = doc.id;

              // return ExpansionTile(
              //   title: Text(community.name),
              //   subtitle: Text(
              //     'Pending Requests: ${community.joinRequests.length}',
              //   ),
              //   children: community.joinRequests.map((userId) {
              //     return ListTile(
              //       title: Text('User ID: $userId'),
              //       trailing: Row(
              //         mainAxisSize: MainAxisSize.min,
              //         children: [
              //           IconButton(
              //             icon: const Icon(Icons.check, color: Colors.green),
              //             onPressed: () =>
              //                 _approveRequest(context, communityDocId, userId),
              //           ),
              //           IconButton(
              //             icon: const Icon(Icons.close, color: Colors.red),
              //             onPressed: () =>
              //                 _rejectRequest(context, communityDocId, userId),
              //           ),
              //         ],
              //       ),
              //     );
              //   }).toList(),
              // );
            },
          );
        },
      ),
    );
  }

  Future<void> _approveRequest(
    BuildContext context,
    String communityDocId,
    String userId,
  ) async {
    final communityRef = FirebaseFirestore.instance
        .collection('communities')
        .doc(communityDocId);
    await communityRef.update({
      'members': FieldValue.arrayUnion([userId]),
      'joinRequests': FieldValue.arrayRemove([userId]),
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Request approved!')));
  }

  Future<void> _rejectRequest(
    BuildContext context,
    String communityDocId,
    String userId,
  ) async {
    final communityRef = FirebaseFirestore.instance
        .collection('communities')
        .doc(communityDocId);
    await communityRef.update({
      'joinRequests': FieldValue.arrayRemove([userId]),
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Request rejected!')));
  }
}
