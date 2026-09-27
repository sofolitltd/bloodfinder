import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../core/utils/slug_utils.dart';

/// One-time migration to populate a `slug` field on existing communities
/// that were created before this field was added.
///
/// Run this from a debug UI button or an isolate. Example usage:
/// ```dart
/// ElevatedButton(
///   onPressed: () => migrateCommunitySlugs(FirebaseFirestore.instance),
///   child: Text('Migrate Community Slugs'),
/// );
/// ```
Future<void> migrateCommunitySlugs(FirebaseFirestore firestore) async {
  final communitiesRef = firestore.collection('communities');
  final communitiesSnap = await communitiesRef.get();

  final usedSlugs = <String>{
    for (final doc in communitiesSnap.docs)
      if (doc.data()['slug'] is String) doc.data()['slug'] as String,
  };

  for (final communityDoc in communitiesSnap.docs) {
    final communityData = communityDoc.data();

    if (communityData['slug'] != null) {
      debugPrint('SKIP ${communityDoc.id} — already has a slug');
      continue;
    }

    final name = communityData['name'] as String? ?? '';
    final base = slugify(name).isEmpty ? 'community' : slugify(name);
    var candidate = base;
    var suffix = 2;
    while (usedSlugs.contains(candidate)) {
      candidate = '$base-$suffix';
      suffix++;
    }
    usedSlugs.add(candidate);

    await communityDoc.reference.update({'slug': candidate});
    debugPrint('UPDATED ${communityDoc.id} ($name) — slug: $candidate');
  }

  debugPrint('Migration complete.');
}
