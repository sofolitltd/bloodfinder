import 'dart:developer';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/member.dart';
import '../../../../data/providers/repository_providers.dart';

final membersStreamProvider =
    StreamProvider.family<List<Member>, String>((ref, communityId) {
  final repo = ref.watch(communityRepositoryProvider);
  return repo.approvedMembersStream(communityId).map(
        (snapshot) =>
            snapshot.docs.map((doc) => Member.fromJson(doc.data())).toList(),
      );
});

final joinRequestsStreamProvider =
    StreamProvider.family<List<Member>, String>((ref, communityId) {
  final repo = ref.watch(communityRepositoryProvider);
  return repo.pendingMembersStream(communityId).map((snapshot) {
    log('Pending requests: ${snapshot.docs.length}');
    return snapshot.docs
        .map((doc) => Member.fromJson(doc.data()))
        .toList();
  });
});
