import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// One-time migration to populate `bloodGroupCounts` on existing communities
/// that were created before this field was added.
///
/// Run this from a debug UI button or an isolate. Example usage:
/// ```dart
/// ElevatedButton(
///   onPressed: () => migrateBloodGroupCounts(FirebaseFirestore.instance),
///   child: Text('Migrate Blood Group Counts'),
/// );
/// ```
Future<void> migrateBloodGroupCounts(FirebaseFirestore firestore) async {
  final communitiesSnap = await firestore.collectionGroup('communities').get();

  for (final communityDoc in communitiesSnap.docs) {
    final communityRef = communityDoc.reference;
    final communityData = communityDoc.data();

    if (communityData['bloodGroupCounts'] != null) {
      debugPrint(
          'SKIP ${communityDoc.id} — already has bloodGroupCounts');
      continue;
    }

    final membersSnap = await communityRef
        .collection('members')
        .where('member', isEqualTo: true)
        .get();

    final bloodGroupCounts = <String, int>{
      'A+': 0,
      'A-': 0,
      'B+': 0,
      'B-': 0,
      'O+': 0,
      'O-': 0,
      'AB+': 0,
      'AB-': 0,
    };

    for (final memberDoc in membersSnap.docs) {
      final uid = memberDoc.data()['uid'] as String?;
      if (uid == null) continue;

      try {
        final userDoc =
            await firestore.collection('users').doc(uid).get();
        final bloodGroup = userDoc.data()?['bloodGroup'] as String?;
        if (bloodGroup != null && bloodGroupCounts.containsKey(bloodGroup)) {
          bloodGroupCounts[bloodGroup] = bloodGroupCounts[bloodGroup]! + 1;
        }
      } catch (e) {
        debugPrint('Error fetching user $uid: $e');
      }
    }

    await communityRef.update({'bloodGroupCounts': bloodGroupCounts});
    debugPrint(
        'UPDATED ${communityDoc.id} (${communityData['name']}) — $bloodGroupCounts');
  }

  debugPrint('Migration complete.');
}
