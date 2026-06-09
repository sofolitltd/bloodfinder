import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/providers/repository_providers.dart';

// ✅ Proper family provider
final communityMembersProvider =
    AsyncNotifierProvider.family<
      CommunityMembersNotifier,
      List<DocumentSnapshot<Map<String, dynamic>>>,
      String
    >((String communityId) => CommunityMembersNotifier(communityId));

class CommunityMembersNotifier extends AsyncNotifier<List<DocumentSnapshot<Map<String, dynamic>>>> {
  CommunityMembersNotifier(this.communityId);

  final String communityId;

  DocumentSnapshot<Map<String, dynamic>>? _lastDoc;
  bool _hasMore = true;
  bool _isLoading = false;

  bool get hasMore => _hasMore;

  @override
  Future<List<DocumentSnapshot<Map<String, dynamic>>>> build() async {
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

  Future<List<DocumentSnapshot<Map<String, dynamic>>>> _fetchMembers({int limit = 10}) async {
    final repo = ref.read(communityRepositoryProvider);
    final snapshot = await repo.getMembers(
      communityId,
      limit: limit,
      startAfter: _lastDoc,
    );

    if (snapshot.docs.length < limit) _hasMore = false;
    if (snapshot.docs.isNotEmpty) _lastDoc = snapshot.docs.last;

    return snapshot.docs;
  }
}
