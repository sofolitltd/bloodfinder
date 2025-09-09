import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../data/models/member.dart';
import '../../data/models/user_model.dart';

class CommunityMemberRequestPage extends StatelessWidget {
  final String communityId;

  const CommunityMemberRequestPage({super.key, required this.communityId});

  @override
  Widget build(BuildContext context) {
    final membersRef = FirebaseFirestore.instance
        .collection('communities')
        .doc(communityId)
        .collection('members')
        .where('member', isEqualTo: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Join Requests'),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: membersRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No pending join requests.'));
          }

          final requests = snapshot.data!.docs
              .map((doc) => Member.fromJson(doc.data() as Map<String, dynamic>))
              .toList();

          return ListView.separated(
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final member = requests[index];
              return StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(member.uid)
                    .snapshots(),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                    return ListTile(title: Text('User not found'));
                  }

                  final userData =
                      userSnapshot.data!.data() as Map<String, dynamic>;
                  UserModel user = UserModel.fromJson(userData);
                  final name = '${user.firstName} ${user.lastName}';
                  final mobile = user.mobileNumber;
                  final blood = user.bloodGroup;
                  final email = user.email;
                  final address =
                      '${user.currentAddress}, ${user.subdistrict}, ${user.district}';

                  return Card(
                    child: ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(name),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Blood: $blood | Mobile: $mobile'),
                          Text('Email: $email'),
                          Text('Address: $address'),

                          SizedBox(height: 8),
                          //
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
                                icon: const Icon(
                                  Icons.check,
                                  color: Colors.green,
                                ),
                                onPressed: () => _approveRequest(member),
                              ),
                              //
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                ),
                                label: Text(
                                  'Cancel',
                                  style: TextStyle(color: Colors.red),
                                ),
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.red,
                                ),
                                onPressed: () => _rejectRequest(member),
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

  Future<void> _approveRequest(Member member) async {
    final ref = FirebaseFirestore.instance
        .collection('communities')
        .doc(communityId)
        .collection('members')
        .doc(member.uid);

    await ref.update({
      'member': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _rejectRequest(Member member) async {
    final ref = FirebaseFirestore.instance
        .collection('communities')
        .doc(communityId)
        .collection('members')
        .doc(member.uid);

    await ref.delete();
  }
}
