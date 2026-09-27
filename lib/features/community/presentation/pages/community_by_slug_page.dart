import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/providers/repository_providers.dart';
import 'community_details_page.dart';

/// Resolves a shareable community [slug] to its Firestore document ID once,
/// then hands off to [CommunityDetailsPage] (which does its own live
/// streaming from that point on).
class CommunityBySlugPage extends ConsumerStatefulWidget {
  final String slug;

  const CommunityBySlugPage({super.key, required this.slug});

  @override
  ConsumerState<CommunityBySlugPage> createState() =>
      _CommunityBySlugPageState();
}

class _CommunityBySlugPageState extends ConsumerState<CommunityBySlugPage> {
  late final Future<DocumentSnapshot<Map<String, dynamic>>?> _resolveFuture;

  @override
  void initState() {
    super.initState();
    _resolveFuture = ref
        .read(communityRepositoryProvider)
        .getCommunityBySlug(widget.slug);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>?>(
      future: _resolveFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final doc = snapshot.data;
        if (doc == null || !doc.exists) {
          return const Scaffold(
            body: Center(child: Text('Community not found')),
          );
        }

        return CommunityDetailsPage(communityId: doc.id);
      },
    );
  }
}
