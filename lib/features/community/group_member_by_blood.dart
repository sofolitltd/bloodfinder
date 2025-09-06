import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class BloodGroupMembersScreen extends StatefulWidget {
  final String communityId;
  final String bloodGroup;

  const BloodGroupMembersScreen({
    super.key,
    required this.communityId,
    required this.bloodGroup,
  });

  @override
  State<BloodGroupMembersScreen> createState() =>
      _BloodGroupMembersScreenState();
}

class _BloodGroupMembersScreenState extends State<BloodGroupMembersScreen> {
  final List<Map<String, dynamic>> _members = [];
  final int _batchSize = 10;
  bool _isLoading = false;
  bool _hasMore = true;
  DocumentSnapshot? _lastMemberDoc;
  List<String> _memberIds = [];

  @override
  void initState() {
    super.initState();
    _loadCommunityMembers();
  }

  Future<void> _loadCommunityMembers() async {
    setState(() => _isLoading = true);

    final communityDoc = await FirebaseFirestore.instance
        .collection('communities')
        .doc(widget.communityId)
        .get();

    if (!communityDoc.exists) {
      setState(() => _isLoading = false);
      return;
    }

    final data = communityDoc.data() as Map<String, dynamic>;
    _memberIds = List<String>.from(data['members'] ?? []);

    await _loadNextBatch();

    setState(() => _isLoading = false);
  }

  Future<void> _loadNextBatch() async {
    if (!_hasMore || _memberIds.isEmpty) return;

    final usersCollection = FirebaseFirestore.instance.collection('users');

    final startIndex = _lastMemberDoc == null
        ? 0
        : _memberIds.indexOf(_lastMemberDoc!.id) + 1;
    final endIndex = (startIndex + _batchSize) > _memberIds.length
        ? _memberIds.length
        : startIndex + _batchSize;

    final batchIds = _memberIds.sublist(startIndex, endIndex);

    if (batchIds.isEmpty) {
      _hasMore = false;
      return;
    }

    final snapshot = await usersCollection
        .where(FieldPath.documentId, whereIn: batchIds)
        .get();

    final newMembers = snapshot.docs
        .where((doc) => doc['bloodGroup'] == widget.bloodGroup)
        .map((doc) {
          final data = doc.data();
          data['uid'] = doc.id;
          return data;
        })
        .toList();

    setState(() {
      _members.addAll(newMembers);
      if (snapshot.docs.isNotEmpty) {
        _lastMemberDoc = snapshot.docs.last;
      }
      if (endIndex >= _memberIds.length) {
        _hasMore = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.bloodGroup} Blood Group Members'),
        centerTitle: true,
      ),
      body: _isLoading && _members.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _members.isEmpty
          ? const Center(child: Text('No members found for this blood group.'))
          : NotificationListener<ScrollNotification>(
              onNotification: (ScrollNotification scrollInfo) {
                if (!_isLoading &&
                    _hasMore &&
                    scrollInfo.metrics.pixels ==
                        scrollInfo.metrics.maxScrollExtent) {
                  _loadNextBatch();
                }
                return false;
              },
              child: Card(
                margin: EdgeInsets.symmetric(vertical: 8),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _members.length + (_hasMore ? 1 : 0),
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    if (index == _members.length) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final member = _members[index];
                    final firstName = member['firstName'] ?? '';
                    final lastName = member['lastName'] ?? '';
                    final name = '$firstName $lastName'.trim();
                    final phone = member['mobileNumber'] ?? 'N/A';

                    return Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListTile(
                        title: Text(name.isNotEmpty ? name : 'Unknown'),
                        subtitle: Text('Phone: $phone'),
                        trailing: CircleAvatar(
                          backgroundColor: Colors.red,
                          child: Text(
                            widget.bloodGroup,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
    );
  }
}
