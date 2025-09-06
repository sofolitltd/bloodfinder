import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CommunityAdminDashboard extends StatelessWidget {
  final String communityId;

  const CommunityAdminDashboard({super.key, required this.communityId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Community Admin'), centerTitle: true),
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
            return const Center(child: Text('Community not found.'));
          }

          final communityData = snapshot.data!.data() as Map<String, dynamic>;

          final communityName = communityData['name'] ?? 'Community';
          final joinRequests = List<String>.from(
            communityData['joinRequests'] ?? [],
          );

          if (joinRequests.isEmpty) {
            return const Center(child: Text('No pending join requests.'));
          }

          return ListView.builder(
            itemCount: joinRequests.length,
            itemBuilder: (context, index) {
              final userId = joinRequests[index];

              return StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(userId)
                    .snapshots(),
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return const ListTile(title: Text('Loading user...'));
                  }

                  if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                    return ListTile(
                      title: Text('User not found (ID: $userId)'),
                      trailing: _buildActions(context, userId),
                    );
                  }

                  final userData =
                      userSnapshot.data!.data() as Map<String, dynamic>;

                  final firstName = userData['firstName'] ?? '';
                  final lastName = userData['lastName'] ?? '';
                  final name = '$firstName $lastName';
                  final address =
                      (userData['address'] != null &&
                          (userData['address'] as List).isNotEmpty)
                      ? '${userData['address'][0]['currentAddress']}, ${userData['address'][0]['subdistrict']}, ${userData['address'][0]['district']}'
                      : 'No address';
                  final bloodGroup = userData['bloodGroup'] ?? '';
                  final mobile = userData['mobileNumber'] ?? '';

                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(child: const Icon(Icons.person)),
                      title: Text(name),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Mobile: $mobile | Blood: $bloodGroup'),
                          Text('Address: $address'),
                          Align(
                            alignment: Alignment.centerRight,
                            child: _buildActions(context, userId),
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

  /// ✅ Action Buttons
  Widget _buildActions(BuildContext context, String userId) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.check, color: Colors.green),
          onPressed: () => _approveRequest(context, userId),
        ),
        IconButton(
          icon: const Icon(Icons.close, color: Colors.red),
          onPressed: () => _rejectRequest(context, userId),
        ),
      ],
    );
  }

  Future<void> _approveRequest(BuildContext context, String userId) async {
    final communityRef = FirebaseFirestore.instance
        .collection('communities')
        .doc(communityId);

    await communityRef.update({
      'members': FieldValue.arrayUnion([userId]),
      'joinRequests': FieldValue.arrayRemove([userId]),
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Request approved!')));
  }

  Future<void> _rejectRequest(BuildContext context, String userId) async {
    final communityRef = FirebaseFirestore.instance
        .collection('communities')
        .doc(communityId);

    await communityRef.update({
      'joinRequests': FieldValue.arrayRemove([userId]),
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Request rejected!')));
  }
}
