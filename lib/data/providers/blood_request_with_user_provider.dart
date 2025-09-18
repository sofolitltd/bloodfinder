import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/data/models/blood_request.dart';
import '/data/models/blood_request_with_user.dart';
import '/data/models/user_model.dart';

final bloodRequestsWithUsersProvider =
    StreamProvider<List<BloodRequestWithUser>>((ref) {
      final firestore = FirebaseFirestore.instance;

      return firestore.collection('bloodRequests').snapshots().asyncMap((
        snapshot,
      ) async {
        final List<BloodRequestWithUser> results = [];

        for (final doc in snapshot.docs) {
          final request = BloodRequest.fromJson(doc.data());

          // fetch user document
          final userDoc = await firestore
              .collection('users')
              .doc(request.uid)
              .get();

          if (!userDoc.exists) continue;

          final user = UserModel.fromJson(userDoc.data()!);

          results.add(BloodRequestWithUser(request: request, user: user));
        }

        return results;
      });
    });

final districtRequestsWithUsersProvider =
    StreamProvider.family<List<BloodRequestWithUser>, String>((ref, district) {
      final firestore = FirebaseFirestore.instance;
      return firestore
          .collection('blood_requests')
          .where('district', isEqualTo: district)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .asyncMap((snapshot) async {
            final List<BloodRequestWithUser> result = [];

            for (final doc in snapshot.docs) {
              final request = BloodRequest.fromJson(doc.data());

              // fetch user info
              final userDoc = await firestore
                  .collection('users')
                  .doc(request.uid)
                  .get();
              if (!userDoc.exists) continue;
              final user = UserModel.fromJson(userDoc.data()!);

              result.add(BloodRequestWithUser(request: request, user: user));
            }

            return result;
          });
    });
