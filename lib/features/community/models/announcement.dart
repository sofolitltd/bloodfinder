import 'package:cloud_firestore/cloud_firestore.dart';

class Announcement {
  final String id;
  final String communityId;
  final String authorUid;
  final String message;
  final bool pinned;
  final Timestamp createdAt;

  Announcement({
    required this.id,
    required this.communityId,
    required this.authorUid,
    required this.message,
    required this.pinned,
    required this.createdAt,
  });

  factory Announcement.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Announcement(
      id: doc.id,
      communityId: data['communityId'] as String,
      authorUid: data['authorUid'] as String,
      message: data['message'] as String? ?? '',
      pinned: data['pinned'] as bool? ?? false,
      createdAt: data['createdAt'] as Timestamp? ?? Timestamp.now(),
    );
  }
}
