import 'package:cloud_firestore/cloud_firestore.dart';

class AppFeedback {
  final String id;
  final String uid;
  final String category;
  final String message;
  final Timestamp createdAt;

  AppFeedback({
    required this.id,
    required this.uid,
    required this.category,
    required this.message,
    required this.createdAt,
  });

  factory AppFeedback.fromJson(Map<String, dynamic> json, String docId) {
    return AppFeedback(
      id: docId,
      uid: json['uid'] as String? ?? '',
      category: json['category'] as String? ?? '',
      message: json['message'] as String? ?? '',
      createdAt: (json['createdAt'] as Timestamp?) ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'category': category,
        'message': message,
        'createdAt': createdAt,
      };

  AppFeedback copyWith({
    String? id,
    String? uid,
    String? category,
    String? message,
    Timestamp? createdAt,
  }) {
    return AppFeedback(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      category: category ?? this.category,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
