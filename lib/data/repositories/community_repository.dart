import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/utils/geohash.dart';
import '../../data/datasources/remote/firebase_datasource.dart';

abstract class CommunityRepository {
  Stream<QuerySnapshot<Map<String, dynamic>>> allCommunitiesStream();
  Stream<QuerySnapshot<Map<String, dynamic>>> communitiesByBloodGroupStream(
    String bloodGroup,
    double latitude,
    double longitude,
    double radiusInKm,
  );
  Future<void> updateBloodGroupCount(
      String communityId, String bloodGroup, int increment);
  DocumentReference<Map<String, dynamic>> communityDoc(String communityId);
  Stream<DocumentSnapshot<Map<String, dynamic>>> communityStream(
      String communityId);
  Future<void> createCommunity(Map<String, dynamic> data);
  Future<void> updateCommunity(String communityId, Map<String, dynamic> data);
  Future<void> deleteCommunity(String communityId);
  Future<void> updateMemberCount(String communityId, int increment);
  Future<void> addAdmin(String communityId, String uid);
  Future<void> removeAdmin(String communityId, String uid);
  Future<void> addModerator(String communityId, String uid);
  Future<void> removeModerator(String communityId, String uid);

  CollectionReference<Map<String, dynamic>> membersCollection();
  DocumentReference<Map<String, dynamic>> memberDoc(
      String communityId, String uid);
  Stream<DocumentSnapshot<Map<String, dynamic>>> memberStream(
      String communityId, String uid);
  Stream<QuerySnapshot<Map<String, dynamic>>> approvedMembersStream(
      String communityId);
  Stream<QuerySnapshot<Map<String, dynamic>>> pendingMembersStream(
      String communityId);
  Future<QuerySnapshot<Map<String, dynamic>>> getMembers(
      String communityId, {
        int limit = 20,
        DocumentSnapshot<Map<String, dynamic>>? startAfter,
      });
  Future<void> addMember(String communityId, String uid,
      Map<String, dynamic> data);
  Future<void> approveMember(String communityId, String uid);
  Future<void> approveMemberAndUpdateCounts(
      String communityId, String uid, String bloodGroup);
  Future<void> removeMember(String communityId, String uid);
  Future<void> inviteMember(
      String communityId, String uid, String invitedByUid, String bloodGroup);

  Stream<QuerySnapshot<Map<String, dynamic>>> userMembershipsStream(String uid);
  Future<DocumentReference<Map<String, dynamic>>> addChat(
      Map<String, dynamic> data);

  Stream<QuerySnapshot<Map<String, dynamic>>> userChatsStream(String uid);
  Future<List<DocumentSnapshot<Map<String, dynamic>>>> getExistingChat(
      String currentUserId, String otherUserId);
  Future<DocumentSnapshot<Map<String, dynamic>>> getChat(String chatId);
  Future<void> updateChat(String chatId, Map<String, dynamic> data);

  CollectionReference<Map<String, dynamic>> messagesCollection(String chatId);
  Stream<QuerySnapshot<Map<String, dynamic>>> messagesStream(String chatId);
  Future<DocumentReference<Map<String, dynamic>>> addMessage(
      String chatId, Map<String, dynamic> data);
  Future<void> updateMessage(
      String chatId, String msgId, Map<String, dynamic> data);
  Future<void> deleteMessage(String chatId, String msgId);

  Stream<QuerySnapshot<Map<String, dynamic>>> userNotificationsStream(
      String uid,
      {DocumentSnapshot<Map<String, dynamic>>? startAfter});
  Future<DocumentReference<Map<String, dynamic>>> addNotification(
      String uid,
      Map<String, dynamic> data);
  Future<void> markNotificationRead(String uid, String notifId);
  Future<DocumentSnapshot<Map<String, dynamic>>> getNotificationDoc(
      String uid, String notifId);

  Future<bool> isAdmin(String uid);
  Stream<DocumentSnapshot<Map<String, dynamic>>> adminStream(String uid);

  // Announcements
  CollectionReference<Map<String, dynamic>> announcementsCollection();
  Stream<QuerySnapshot<Map<String, dynamic>>> announcementsStream(
      String communityId);
  Future<DocumentReference<Map<String, dynamic>>> addAnnouncement(
      Map<String, dynamic> data);
  Future<void> deleteAnnouncement(String announcementId);
  Future<void> setAnnouncementPinned(String announcementId, bool pinned);

  // Audit log
  CollectionReference<Map<String, dynamic>> auditLogCollection();
  Stream<QuerySnapshot<Map<String, dynamic>>> auditLogStream(
      String communityId);
  Future<void> logCommunityAction({
    required String communityId,
    required String actorUid,
    required String action,
    String? targetUid,
  });
}

class FirebaseCommunityRepository implements CommunityRepository {
  FirebaseCommunityRepository(this._dataSource);

  final FirebaseDataSource _dataSource;

  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> allCommunitiesStream() =>
      _dataSource.collection('communities').orderBy('name', descending: true).snapshots();

  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> communitiesByBloodGroupStream(
    String bloodGroup,
    double latitude,
    double longitude,
    double radiusInKm,
  ) {
    int precision;
    if (radiusInKm <= 1.0) {
      precision = 7;
    } else if (radiusInKm <= 5.0) {
      precision = 6;
    } else if (radiusInKm <= 20.0) {
      precision = 5;
    } else if (radiusInKm <= 80.0) {
      precision = 4;
    } else {
      precision = 3;
    }

    final centerHash = Geohash.encode(latitude, longitude);
    final prefix = centerHash.substring(0, precision);

    return _dataSource
        .collection('communities')
        .where('geohash', isGreaterThanOrEqualTo: prefix)
        .where('geohash', isLessThanOrEqualTo: '$prefix\uf8ff')
        .orderBy('geohash')
        .snapshots();
  }

  @override
  Future<void> updateBloodGroupCount(
          String communityId, String bloodGroup, int increment) =>
      communityDoc(communityId).update({
        'bloodGroupCounts.$bloodGroup': FieldValue.increment(increment),
      });

  @override
  DocumentReference<Map<String, dynamic>> communityDoc(String communityId) =>
      _dataSource.document('communities/$communityId');

  @override
  Stream<DocumentSnapshot<Map<String, dynamic>>> communityStream(
          String communityId) =>
      communityDoc(communityId).snapshots();

  @override
  Future<void> createCommunity(Map<String, dynamic> data) =>
      _dataSource.collection('communities').add(data);

  @override
  Future<void> updateCommunity(
          String communityId, Map<String, dynamic> data) =>
      communityDoc(communityId).update(data);

  @override
  Future<void> deleteCommunity(String communityId) async {
    // Cascade-delete everything that references this community so nothing
    // is left orphaned: memberships, tagged notifications, and the cover
    // image in Storage.
    final membersSnap = await membersCollection()
        .where('communityId', isEqualTo: communityId)
        .get();
    final notificationsSnap = await _dataSource
        .collection('notifications')
        .where('data.communityId', isEqualTo: communityId)
        .get();

    final docsToDelete = [
      ...membersSnap.docs,
      ...notificationsSnap.docs,
    ];

    // Firestore batches are capped at 500 writes, so chunk defensively.
    const batchChunkSize = 400;
    for (var i = 0; i < docsToDelete.length; i += batchChunkSize) {
      final batch = _dataSource.batch();
      for (final doc in docsToDelete.skip(i).take(batchChunkSize)) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }

    await communityDoc(communityId).delete();

    try {
      await _dataSource.storageRef('communities/$communityId.jpg').delete();
    } catch (_) {
      // No cover image was uploaded — safe to ignore.
    }
  }

  @override
  Future<void> updateMemberCount(String communityId, int increment) =>
      communityDoc(communityId).update({
        'memberCount': FieldValue.increment(increment),
      });

  @override
  Future<void> addAdmin(String communityId, String uid) => updateCommunity(
      communityId, {'admin': FieldValue.arrayUnion([uid])});

  @override
  Future<void> removeAdmin(String communityId, String uid) => updateCommunity(
      communityId, {'admin': FieldValue.arrayRemove([uid])});

  @override
  Future<void> addModerator(String communityId, String uid) => updateCommunity(
      communityId, {'moderators': FieldValue.arrayUnion([uid])});

  @override
  Future<void> removeModerator(String communityId, String uid) =>
      updateCommunity(
          communityId, {'moderators': FieldValue.arrayRemove([uid])});

  @override
  CollectionReference<Map<String, dynamic>> membersCollection() =>
      _dataSource.collection('community_members');

  @override
  DocumentReference<Map<String, dynamic>> memberDoc(
          String communityId, String uid) =>
      _dataSource.document('community_members/${communityId}_$uid');

  @override
  Stream<DocumentSnapshot<Map<String, dynamic>>> memberStream(
          String communityId, String uid) =>
      memberDoc(communityId, uid).snapshots();

  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> approvedMembersStream(
          String communityId) =>
      membersCollection()
          .where('communityId', isEqualTo: communityId)
          .where('member', isEqualTo: true)
          .snapshots();

  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> pendingMembersStream(
          String communityId) =>
      membersCollection()
          .where('communityId', isEqualTo: communityId)
          .where('member', isEqualTo: false)
          .snapshots();

  @override
  Future<QuerySnapshot<Map<String, dynamic>>> getMembers(
      String communityId, {
        int limit = 20,
        DocumentSnapshot<Map<String, dynamic>>? startAfter,
      }) {
    var query = membersCollection()
        .where('communityId', isEqualTo: communityId)
        .where('member', isEqualTo: true)
        .orderBy(FieldPath.documentId)
        .limit(limit);
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }
    return query.get();
  }

  @override
  Future<void> addMember(
      String communityId, String uid, Map<String, dynamic> data) {
    data['communityId'] = communityId;
    data['uid'] = uid;
    return memberDoc(communityId, uid).set(data);
  }

  @override
  Future<void> approveMember(String communityId, String uid) =>
      memberDoc(communityId, uid).update({'member': true});

  @override
  Future<void> approveMemberAndUpdateCounts(
      String communityId, String uid, String bloodGroup) {
    final batch = _dataSource.batch();
    batch.update(memberDoc(communityId, uid), {
      'member': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.update(communityDoc(communityId), {
      'memberCount': FieldValue.increment(1),
      'bloodGroupCounts.$bloodGroup': FieldValue.increment(1),
    });
    return batch.commit();
  }

  @override
  Future<void> removeMember(String communityId, String uid) =>
      memberDoc(communityId, uid).delete();

  @override
  Future<void> inviteMember(String communityId, String uid,
          String invitedByUid, String bloodGroup) =>
      addMember(communityId, uid, {
        'member': false,
        'source': 'invited',
        'invitedBy': invitedByUid,
        'bloodGroup': bloodGroup,
        'createdAt': FieldValue.serverTimestamp(),
      });

  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> userMembershipsStream(
          String uid) =>
      _dataSource
          .collection('community_members')
          .where('uid', isEqualTo: uid)
          .where('member', isEqualTo: true)
          .snapshots();

  @override
  Future<DocumentReference<Map<String, dynamic>>> addChat(
          Map<String, dynamic> data) =>
      _dataSource.collection('chats').add(data);

  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> userChatsStream(String uid) =>
      _dataSource
          .collection('chats')
          .where('participants', arrayContains: uid)
          .snapshots();

  @override
  Future<List<DocumentSnapshot<Map<String, dynamic>>>> getExistingChat(
      String currentUserId, String otherUserId) {
    return _dataSource
        .collection('chats')
        .where('participants', arrayContains: currentUserId)
        .get()
        .then((snap) => snap.docs
            .where((doc) =>
                (doc.data()['participants'] as List?)?.contains(otherUserId) ??
                false)
            .toList());
  }

  @override
  Future<DocumentSnapshot<Map<String, dynamic>>> getChat(String chatId) =>
      _dataSource.document('chats/$chatId').get();

  @override
  Future<void> updateChat(String chatId, Map<String, dynamic> data) =>
      _dataSource.document('chats/$chatId').update(data);

  @override
  CollectionReference<Map<String, dynamic>> messagesCollection(
          String chatId) =>
      _dataSource.collection('chats/$chatId/messages');

  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> messagesStream(String chatId) =>
      messagesCollection(chatId).orderBy('timestamp').snapshots();

  @override
  Future<DocumentReference<Map<String, dynamic>>> addMessage(
          String chatId, Map<String, dynamic> data) =>
      messagesCollection(chatId).add(data);

  @override
  Future<void> updateMessage(
          String chatId, String msgId, Map<String, dynamic> data) =>
      messagesCollection(chatId).doc(msgId).update(data);

  @override
  Future<void> deleteMessage(String chatId, String msgId) =>
      messagesCollection(chatId).doc(msgId).delete();

  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> userNotificationsStream(
      String uid, {
        DocumentSnapshot<Map<String, dynamic>>? startAfter,
      }) {
    var query = _dataSource
        .collection('notifications')
        .where('uid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(20);
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }
    return query.snapshots();
  }

  @override
  Future<DocumentReference<Map<String, dynamic>>> addNotification(
          String uid, Map<String, dynamic> data) {
    data['uid'] = uid;
    return _dataSource.collection('notifications').add(data);
  }

  @override
  Future<void> markNotificationRead(String uid, String notifId) =>
      _dataSource.document('notifications/$notifId').update({'read': true});

  @override
  Future<DocumentSnapshot<Map<String, dynamic>>> getNotificationDoc(
          String uid, String notifId) =>
      _dataSource.document('notifications/$notifId').get();

  @override
  Future<bool> isAdmin(String uid) =>
      _dataSource.document('admin/$uid').get().then((doc) => doc.exists);

  @override
  Stream<DocumentSnapshot<Map<String, dynamic>>> adminStream(String uid) =>
      _dataSource.document('admin/$uid').snapshots();

  @override
  CollectionReference<Map<String, dynamic>> announcementsCollection() =>
      _dataSource.collection('community_announcements');

  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> announcementsStream(
          String communityId) =>
      announcementsCollection()
          .where('communityId', isEqualTo: communityId)
          .snapshots();

  @override
  Future<DocumentReference<Map<String, dynamic>>> addAnnouncement(
          Map<String, dynamic> data) =>
      announcementsCollection().add(data);

  @override
  Future<void> deleteAnnouncement(String announcementId) =>
      announcementsCollection().doc(announcementId).delete();

  @override
  Future<void> setAnnouncementPinned(String announcementId, bool pinned) =>
      announcementsCollection().doc(announcementId).update({'pinned': pinned});

  @override
  CollectionReference<Map<String, dynamic>> auditLogCollection() =>
      _dataSource.collection('community_audit_logs');

  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> auditLogStream(
          String communityId) =>
      auditLogCollection()
          .where('communityId', isEqualTo: communityId)
          .orderBy('createdAt', descending: true)
          .limit(100)
          .snapshots();

  @override
  Future<void> logCommunityAction({
    required String communityId,
    required String actorUid,
    required String action,
    String? targetUid,
  }) =>
      auditLogCollection().add({
        'communityId': communityId,
        'actorUid': actorUid,
        'action': action,
        'targetUid': targetUid,
        'createdAt': FieldValue.serverTimestamp(),
      });
}
