import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/providers/repository_providers.dart';
import '../models/my_circle_contact.dart';

final myCircleProvider = StreamProvider<List<MyCircleContact>>((ref) {
  final repo = ref.watch(myCircleRepositoryProvider);
  final uid = ref.watch(authRepositoryProvider).currentUser!.uid;

  return repo.contactsStream(uid).map(
        (list) => list.map((json) => MyCircleContact.fromJson(json)).toList(),
      );
});
