import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../data/datasources/remote/firebase_datasource.dart';
import '../models/app_feedback.dart';

abstract class FeedbackRepository {
  Future<void> submitFeedback(AppFeedback feedback);
  Future<List<AppFeedback>> getUserFeedback(String uid);
  Future<List<AppFeedback>> getAllFeedback();
  Future<void> updateFeedback(String feedbackId, Map<String, dynamic> data);
  Future<void> deleteFeedback(String feedbackId);
}

class FirebaseFeedbackRepository implements FeedbackRepository {
  FirebaseFeedbackRepository(this._dataSource);

  final FirebaseDataSource _dataSource;

  CollectionReference<Map<String, dynamic>> get _ref =>
      _dataSource.collection('feedbacks');

  @override
  Future<void> submitFeedback(AppFeedback feedback) =>
      _ref.add(feedback.toJson());

  @override
  Future<List<AppFeedback>> getUserFeedback(String uid) async {
    final snap = await _ref
        .where('uid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs
        .map((doc) => AppFeedback.fromJson(doc.data(), doc.id))
        .toList();
  }

  @override
  Future<List<AppFeedback>> getAllFeedback() async {
    final snap = await _ref
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs
        .map((doc) => AppFeedback.fromJson(doc.data(), doc.id))
        .toList();
  }

  @override
  Future<void> updateFeedback(String feedbackId, Map<String, dynamic> data) =>
      _ref.doc(feedbackId).update(data);

  @override
  Future<void> deleteFeedback(String feedbackId) =>
      _ref.doc(feedbackId).delete();
}
