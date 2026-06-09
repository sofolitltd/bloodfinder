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

  Map<String, dynamic> toJson() => {
        'id': id,
        'uid': uid,
        'category': category,
        'message': message,
        'createdAt': createdAt,
      };
}
