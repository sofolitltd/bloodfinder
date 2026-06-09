import '../../../data/datasources/remote/firebase_datasource.dart';
import '../models/app_feedback.dart';

abstract class FeedbackRepository {
  Future<void> submitFeedback(AppFeedback feedback);
}

class FirebaseFeedbackRepository implements FeedbackRepository {
  FirebaseFeedbackRepository(this._dataSource);

  final FirebaseDataSource _dataSource;

  @override
  Future<void> submitFeedback(AppFeedback feedback) =>
      _dataSource.collection('feedbacks').add(feedback.toJson());
}
