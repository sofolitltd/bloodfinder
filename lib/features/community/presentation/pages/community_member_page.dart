import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/community.dart';
import '../../../../data/providers/repository_providers.dart';
import '../widgets/community_members_list.dart';

class CommunityMembersPage extends ConsumerWidget {
  final Community community;

  const CommunityMembersPage({super.key, required this.community});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final communityRepo = ref.read(communityRepositoryProvider);
    final currentUserId = ref.read(authRepositoryProvider).currentUser!.uid;

    final communityStream = communityRepo
        .communityStream(community.id)
        .map((doc) => Community.fromJson({...?doc.data(), 'id': doc.id}));

    return Scaffold(
      appBar: AppBar(
        title: const Text("Community Members"),
        centerTitle: true,
      ),
      body: StreamBuilder<Community>(
        stream: communityStream,
        builder: (context, communitySnapshot) {
          if (communitySnapshot.hasError) {
            return const Center(
              child: Text('Something went wrong. Please try again.'),
            );
          }

          if (!communitySnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          return CommunityMembersList(
            community: communitySnapshot.data!,
            currentUserId: currentUserId,
          );
        },
      ),
    );
  }
}
