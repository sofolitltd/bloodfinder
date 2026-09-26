import 'package:cloud_firestore/cloud_firestore.dart';

class AuditLogEntry {
  final String id;
  final String communityId;
  final String actorUid;
  final String action;
  final String? targetUid;
  final Timestamp createdAt;

  AuditLogEntry({
    required this.id,
    required this.communityId,
    required this.actorUid,
    required this.action,
    this.targetUid,
    required this.createdAt,
  });

  factory AuditLogEntry.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AuditLogEntry(
      id: doc.id,
      communityId: data['communityId'] as String,
      actorUid: data['actorUid'] as String,
      action: data['action'] as String? ?? '',
      targetUid: data['targetUid'] as String?,
      createdAt: data['createdAt'] as Timestamp? ?? Timestamp.now(),
    );
  }

  /// Human-readable description of [action], e.g. "made admin".
  String get description {
    switch (action) {
      case 'approve_member':
        return 'approved a join request';
      case 'decline_member':
        return 'declined a join request';
      case 'remove_member':
        return 'removed a member';
      case 'make_admin':
        return 'promoted a member to admin';
      case 'remove_admin':
        return 'removed admin from a member';
      case 'make_moderator':
        return 'promoted a member to moderator';
      case 'remove_moderator':
        return 'removed moderator from a member';
      case 'invite_member':
        return 'invited a user to join';
      default:
        return action;
    }
  }
}
