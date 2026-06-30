import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/providers/repository_providers.dart';
import '../models/my_circle_contact.dart';

final myCircleProvider = StreamProvider<List<MyCircleContact>>((ref) {
  final currentUser = ref.watch(currentUserProvider).asData?.value;
  if (currentUser == null) return const Stream.empty();

  final repo = ref.watch(myCircleRepositoryProvider);
  return repo.contactsStream(currentUser.uid).map(
        (list) => list.map((json) => MyCircleContact.fromJson(json)).toList(),
      );
});
