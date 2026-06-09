import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers/repository_providers.dart';

class AdminWidget extends ConsumerWidget {
  final Widget child;

  const AdminWidget({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authRepo = ref.watch(authRepositoryProvider);
    final uid = authRepo.currentUser?.uid;
    if (uid == null) {
      return const SizedBox.shrink();
    }

    final adminStream = ref.watch(communityRepositoryProvider).adminStream(uid);

    return StreamBuilder<bool>(
      stream: adminStream.map((doc) => doc.exists),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        final isAdmin = snapshot.data ?? false;
        if (!isAdmin) {
          return const SizedBox.shrink();
        }

        return child;
      },
    );
  }
}
