import 'package:cloud_firestore/cloud_firestore.dart';

class Member {
  final String uid;
  final bool member; // true if joined/approved, false if pending
  final Timestamp createdAt;
  final String source; // 'requested' (user asked to join) or 'invited' (admin/moderator invited them)
  final String? invitedBy; // uid of the admin/moderator who sent the invite
  final String? bloodGroup; // set when invited, so accept doesn't need an extra user fetch

  Member({
    required this.uid,
    required this.member,
    required this.createdAt,
    this.source = 'requested',
    this.invitedBy,
    this.bloodGroup,
  });

  // Factory constructor to create from Firestore document
  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      uid: json['uid'] as String,
      member: json['member'] as bool? ?? false,
      createdAt: (json['createdAt'] as Timestamp),
      source: json['source'] as String? ?? 'requested',
      invitedBy: json['invitedBy'] as String?,
      bloodGroup: json['bloodGroup'] as String?,
    );
  }

  // Convert to Map for saving to Firestore
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'member': member,
      'createdAt': FieldValue.serverTimestamp(),
      'source': source,
      if (invitedBy != null) 'invitedBy': invitedBy,
      if (bloodGroup != null) 'bloodGroup': bloodGroup,
    };
  }
}
