import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ✅ Proper family provider
final communityMembersProvider =
    AsyncNotifierProvider.family<
      CommunityMembersNotifier,
      List<DocumentSnapshot>,
      String
    >((String communityId) => CommunityMembersNotifier(communityId));

class CommunityMembersNotifier extends AsyncNotifier<List<DocumentSnapshot>> {
  CommunityMembersNotifier(this.communityId);

  final String communityId;

  DocumentSnapshot? _lastDoc;
  bool _hasMore = true;
  bool _isLoading = false;

  bool get hasMore => _hasMore;

  @override
  Future<List<DocumentSnapshot>> build() async {
    // Initial load
    return _fetchMembers();
  }

  Future<void> loadMore({int limit = 10}) async {
    if (!_hasMore || _isLoading) return;
    _isLoading = true;

    final moreDocs = await _fetchMembers(limit: limit);
    state = AsyncData([...?state.value, ...moreDocs]);

    _isLoading = false;
  }

  void removeMemberLocally(String memberId) {
    final current = state.value ?? [];
    state = AsyncData(current.where((doc) => doc.id != memberId).toList());
  }

  Future<List<DocumentSnapshot>> _fetchMembers({int limit = 10}) async {
    Query query = FirebaseFirestore.instance
        .collection('communities')
        .doc(communityId)
        .collection('members')
        .where('member', isEqualTo: true)
        .orderBy(FieldPath.documentId)
        .limit(limit);

    if (_lastDoc != null) {
      query = query.startAfterDocument(_lastDoc!);
    }

    final snapshot = await query.get();
    if (snapshot.docs.length < limit) _hasMore = false;
    if (snapshot.docs.isNotEmpty) _lastDoc = snapshot.docs.last;

    return snapshot.docs;
  }
}
