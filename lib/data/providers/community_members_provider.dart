import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final communityMembersProvider =
    StateNotifierProvider.family<
      CommunityMembersNotifier,
      List<DocumentSnapshot>,
      String
    >((ref, communityId) => CommunityMembersNotifier(communityId));

class CommunityMembersNotifier extends StateNotifier<List<DocumentSnapshot>> {
  final String communityId;
  DocumentSnapshot? _lastDoc;
  bool _hasMore = true; // track if more data exists
  bool _isLoading = false;

  bool get hasMore => _hasMore; // expose to UI

  CommunityMembersNotifier(this.communityId) : super([]) {
    loadMore();
  }

  Future<void> loadMore({int limit = 10}) async {
    if (!_hasMore || _isLoading) return;
    _isLoading = true;

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
    final docs = snapshot.docs;

    if (docs.length < limit) _hasMore = false; // no more data
    if (docs.isNotEmpty) _lastDoc = docs.last;

    state = [...state, ...docs];
    _isLoading = false;
  }

  void removeMemberLocally(String memberId) {
    state = state.where((doc) => doc.id != memberId).toList();
  }
}
