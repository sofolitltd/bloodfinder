import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';


import '../../features/notification/models/notification.dart';
import '../repositories/community_repository.dart';
import 'repository_providers.dart';

class NotificationRepository {
  final CommunityRepository _communityRepository;

  NotificationRepository(this._communityRepository);

  Stream<List<NotificationModel>> getNotifications({
    required String userId,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  }) {
    return _communityRepository
        .userNotificationsStream(userId, startAfter: startAfter)
        .map(
      (snapshot) =>
          snapshot.docs.map((doc) => NotificationModel.fromDoc(doc)).toList(),
    );
  }
}

final notificationRepositoryProvider = Provider(
  (ref) => NotificationRepository(ref.watch(communityRepositoryProvider)),
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
