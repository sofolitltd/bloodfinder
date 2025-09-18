import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  static final _firestore = FirebaseFirestore.instance;

  /// Add a notification to a user's collection
  static Future<void> addNotification({
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? data,
    String? userId, // optional, defaults to current user
  }) async {
    final uid = userId ?? FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final docRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .doc(); // auto-generated ID

    await docRef.set({
      'id': docRef.id,
      'title': title,
      'body': body,
      'type': type,
      'data': data ?? {},
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
