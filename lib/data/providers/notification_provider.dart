import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/notification.dart';

class NotificationRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<NotificationModel>> getNotifications({
    required String userId,
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) {
    Query query = _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    return query.snapshots().map(
      (snapshot) =>
          snapshot.docs.map((doc) => NotificationModel.fromDoc(doc)).toList(),
    );
  }
}

// Repository provider
final notificationRepositoryProvider = Provider(
  (ref) => NotificationRepository(),
);

// Notification stream provider (paginated)
final notificationsStreamProvider =
    StreamProvider.family<List<NotificationModel>, String>((ref, userId) {
      final repo = ref.watch(notificationRepositoryProvider);
      return repo.getNotifications(userId: userId);
    });

// Unread count provider
final unreadCountProvider = StreamProvider.family<int, String>((ref, userId) {
  final repo = ref.watch(notificationRepositoryProvider);
  return repo
      .getNotifications(userId: userId)
      .map((list) => list.where((n) => !n.read).length);
});
