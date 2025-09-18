import 'package:bloodfinder/features/widgets/start_chat_btn.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class BloodGroupMembersScreen extends StatelessWidget {
  final String communityId;
  final String bloodGroup;

  const BloodGroupMembersScreen({
    super.key,
    required this.communityId,
    required this.bloodGroup,
  });

  Stream<List<Map<String, dynamic>>> _communityBloodGroupMembers() {
    final membersRef = FirebaseFirestore.instance
        .collection('communities')
        .doc(communityId)
        .collection('members');

    return membersRef.snapshots().asyncMap((snapshot) async {
      final userIds = snapshot.docs.map((doc) => doc['uid'] as String).toList();

      if (userIds.isEmpty) return [];

      final List<Map<String, dynamic>> allMembers = [];

      // 🔹 Batch the userIds into chunks of 10
      for (var i = 0; i < userIds.length; i += 10) {
        final chunk = userIds.sublist(
          i,
          i + 10 > userIds.length ? userIds.length : i + 10,
        );

        final usersSnap = await FirebaseFirestore.instance
            .collection('users')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();

        final members = usersSnap.docs
            .map((doc) {
              final data = doc.data();
              data['uid'] = doc.id;
              return data;
            })
            .where((data) => data['bloodGroup'] == bloodGroup)
            .toList();

        allMembers.addAll(members);
      }

      return allMembers;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$bloodGroup Blood Group Members'),
        centerTitle: true,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _communityBloodGroupMembers(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final members = snapshot.data!;
          if (members.isEmpty) {
            return const Center(
              child: Text('No members found for this blood group.'),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: members.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final member = members[index];
              String otherUserId = member['uid'];

              final name =
                  '${member['firstName'] ?? ''} ${member['lastName'] ?? ''}'
                      .trim();
              final address =
                  '${member['currentAddress'] ?? ''}, ${member['district'] ?? ''} ${member['subdistrict'] ?? ''}';

              return Stack(
                children: [
                  //
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        radius: 21,
                        backgroundColor: Colors.redAccent.shade200,
                        child: member['image'].isEmpty
                            ? Text(
                                member['firstName'].isNotEmpty
                                    ? member['firstName'][0].toUpperCase()
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
                                  imageUrl: member['image'],
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) =>
                                      CircularProgressIndicator(strokeWidth: 2),
                                  errorWidget: (context, url, error) =>
                                      Icon(Icons.error, color: Colors.red),
                                ),
                              ),
                      ),
                      title: Text(name.isNotEmpty ? name : 'Unknown'),
                      isThreeLine: true,
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Address: $address'),
                          SizedBox(height: 8),

                          StartChatButton(otherUserId: otherUserId),
                          SizedBox(height: 4),
                        ],
                      ),
                    ),
                  ),

                  //
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 2, horizontal: 8),
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
  }
}
