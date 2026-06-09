import 'package:cloud_firestore/cloud_firestore.dart';

class Member {
  final String uid;
  final bool member; // true if joined/approved, false if pending
  final Timestamp createdAt;

  Member({required this.uid, required this.member, required this.createdAt});

  // Factory constructor to create from Firestore document
  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      uid: json['uid'] as String,
      member: json['member'] as bool? ?? false,
      createdAt: (json['createdAt'] as Timestamp),
    );
  }

  // Convert to Map for saving to Firestore
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'member': member,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
