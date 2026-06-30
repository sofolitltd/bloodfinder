import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';


import '../models/user_model.dart';
import 'repository_providers.dart';

final userProvider = StreamProvider<UserModel?>((ref) {
  final currentUser = ref.watch(currentUserProvider).asData?.value;
  if (currentUser == null) return const Stream.empty();

  final userRepo = ref.watch(userRepositoryProvider);
  return userRepo
      .userStream(currentUser.uid)
      .map((doc) => doc.exists ? UserModel.fromJson(doc.data()!) : null);
});

final userDocProvider =
    StreamProvider<DocumentSnapshot<Map<String, dynamic>>?>((ref) {
  final currentUser = ref.watch(currentUserProvider).asData?.value;
  if (currentUser == null) return const Stream.empty();
  return ref.watch(userRepositoryProvider).userStream(currentUser.uid);
});

final donationProvider = StreamProvider<List<DocumentSnapshot>>((ref) {
  final currentUser = ref.watch(currentUserProvider).asData?.value;
  if (currentUser == null) return const Stream.empty();

  final userRepo = ref.watch(userRepositoryProvider);
  return userRepo
      .donationsStream(currentUser.uid)
      .map((snapshot) => snapshot.docs);
});
