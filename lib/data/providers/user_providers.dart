import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';


import '../models/user_model.dart';
import 'repository_providers.dart';

final userProvider = StreamProvider<UserModel?>((ref) {
  final auth = ref.watch(authRepositoryProvider);
  final user = auth.currentUser;
  if (user == null) return const Stream.empty();

  final userRepo = ref.watch(userRepositoryProvider);
  return userRepo
      .userStream(user.uid)
      .map((doc) => doc.exists ? UserModel.fromJson(doc.data()!) : null);
});

final userDocProvider =
    StreamProvider<DocumentSnapshot<Map<String, dynamic>>?>((ref) {
  final auth = ref.watch(authRepositoryProvider);
  final user = auth.currentUser;
  if (user == null) return const Stream.empty();
  return ref.watch(userRepositoryProvider).userStream(user.uid);
});

final donationProvider = StreamProvider<List<DocumentSnapshot>>((ref) {
  final auth = ref.watch(authRepositoryProvider);
  final user = auth.currentUser;
  if (user == null) return const Stream.empty();

  final userRepo = ref.watch(userRepositoryProvider);
  return userRepo
      .donationsStream(user.uid)
      .map((snapshot) => snapshot.docs);
});
