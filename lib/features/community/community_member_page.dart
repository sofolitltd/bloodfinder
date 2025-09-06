import 'package:bloodfinder/features/widgets/start_chat_btn.dart';
import 'package:bloodfinder/shared/admin_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CommunityMembersPage extends StatefulWidget {
  final String communityId;

  const CommunityMembersPage({super.key, required this.communityId});

  @override
  State<CommunityMembersPage> createState() => _CommunityMembersPageState();
}

class _CommunityMembersPageState extends State<CommunityMembersPage> {
  final int _pageSize = 10;
  final List<DocumentSnapshot> _membersDocs = [];
  bool _isLoading = false;
  bool _hasMore = true;
  DocumentSnapshot? _lastDocument;

  @override
  void initState() {
    super.initState();
    _fetchMembers();
  }

  /// 🔥 Fetch members with pagination
  Future<void> _fetchMembers() async {
    if (_isLoading || !_hasMore) return;
    setState(() => _isLoading = true);

    // Get community doc to extract members[]
    final communityDoc = await FirebaseFirestore.instance
        .collection('communities')
        .doc(widget.communityId)
        .get();

    if (!communityDoc.exists) {
      setState(() => _isLoading = false);
      return;
    }

    final members = List<String>.from(communityDoc['members'] ?? []);

    if (members.isEmpty) {
      setState(() {
        _isLoading = false;
        _hasMore = false;
      });
      return;
    }

    // Firestore query with whereIn (max 10 at once)
    Query query = FirebaseFirestore.instance
        .collection('users')
        .where(FieldPath.documentId, whereIn: members.take(10).toList())
        .limit(_pageSize);

    if (_lastDocument != null) {
      query = query.startAfterDocument(_lastDocument!);
    }

    final querySnapshot = await query.get();

    if (querySnapshot.docs.isNotEmpty) {
      _lastDocument = querySnapshot.docs.last;
      _membersDocs.addAll(querySnapshot.docs);
    }

    if (querySnapshot.docs.length < _pageSize) {
      _hasMore = false;
    }

    setState(() => _isLoading = false);
  }

  /// 🔴 Remove Member
  Future<void> _removeMember(String userId) async {
    await FirebaseFirestore.instance
        .collection('communities')
        .doc(widget.communityId)
        .update({
          'members': FieldValue.arrayRemove([userId]),
        });

    setState(() {
      _membersDocs.removeWhere((doc) => doc.id == userId);
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Member removed')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Community Members'), centerTitle: true),
      body: _membersDocs.isEmpty && !_isLoading
          ? const Center(child: Text('No members in this community.'))
          : ListView.separated(
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemCount: _membersDocs.length + 1,
              itemBuilder: (context, index) {
                if (index == _membersDocs.length) {
                  if (_hasMore) {
                    _fetchMembers();
                    return const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  } else {
                    return const SizedBox.shrink();
                  }
                }

                final userDoc = _membersDocs[index];
                final userData = userDoc.data() as Map<String, dynamic>;

                final otherUserId = userDoc.id;
                final firstName = userData['firstName'] ?? '';
                final lastName = userData['lastName'] ?? '';
                final name = '$firstName $lastName';
                final mobile = userData['mobileNumber'] ?? '';
                final bloodGroup = userData['bloodGroup'] ?? '';
                final address =
                    '${userData['address'][0]['currentAddress']}, ${userData['address'][0]['subDistrict']}, ${userData['address'][0]['district']}' ??
                    '';

                return Card(
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Colors.grey),
                    ),
                    leading: CircleAvatar(child: const Icon(Icons.person)),
                    isThreeLine: true,
                    title: Text(name),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        //
                        Text('Blood: $bloodGroup'),

                        Text('Address: $address'),

                        SizedBox(height: 8),

                        //
                        Row(
                          spacing: 10,
                          children: [
                            //
                            Expanded(
                              flex: 3,
                              child: StartChatButton(otherUserId: otherUserId),
                            ),

                            //
                            Expanded(
                              flex: 4,
                              child: AdminWidget(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    visualDensity: VisualDensity(vertical: -4),
                                  ),
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('Remove Member'),
                                        content: const Text(
                                          'Are you sure you want to remove this member?',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(ctx, false),
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(ctx, true),
                                            child: const Text('Remove'),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (confirm == true) {
                                      _removeMember(userDoc.id);
                                    }
                                  },
                                  child: Text('Remove Membership'),
                                ),
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 8),

                        //
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
