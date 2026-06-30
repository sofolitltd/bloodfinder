import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../datasources/remote/firebase_datasource.dart';
import '../repositories/auth_repository.dart';
import '../repositories/blood_request_repository.dart';
import '../repositories/community_repository.dart';
import '../repositories/storage_repository.dart';
import '../repositories/user_repository.dart';
import '../../features/blood_bank/repositories/blood_bank_repository.dart';
import '../../features/emergency_donor/repositories/emergency_donor_repository.dart';
import '../../features/feed/repositories/feed_repository.dart';
import '../../features/my_circle/repositories/my_circle_repository.dart';
import '../../features/feedback/repositories/feedback_repository.dart';
import '../../features/events/repositories/event_repository.dart';

final firebaseDataSourceProvider = Provider<FirebaseDataSource>((ref) {
  return FirebaseDataSource();
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dataSource = ref.watch(firebaseDataSourceProvider);
  return FirebaseAuthRepository(dataSource);
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  final dataSource = ref.watch(firebaseDataSourceProvider);
  return FirebaseUserRepository(dataSource);
});

final communityRepositoryProvider = Provider<CommunityRepository>((ref) {
  final dataSource = ref.watch(firebaseDataSourceProvider);
  return FirebaseCommunityRepository(dataSource);
});

final bloodRequestRepositoryProvider = Provider<BloodRequestRepository>((ref) {
  final dataSource = ref.watch(firebaseDataSourceProvider);
  return FirebaseBloodRequestRepository(dataSource);
});

final storageRepositoryProvider = Provider<StorageRepository>((ref) {
  final dataSource = ref.watch(firebaseDataSourceProvider);
  return FirebaseStorageRepository(dataSource);
});

final feedRepositoryProvider = Provider<FeedRepository>((ref) {
  final dataSource = ref.watch(firebaseDataSourceProvider);
  return FirebaseFeedRepository(dataSource);
});

final emergencyDonorRepositoryProvider = Provider<EmergencyDonorRepository>((ref) {
  final dataSource = ref.watch(firebaseDataSourceProvider);
  return FirebaseEmergencyDonorRepository(dataSource);
});

final bloodBankRepositoryProvider = Provider<BloodBankRepository>((ref) {
  final dataSource = ref.watch(firebaseDataSourceProvider);
  return FirebaseBloodBankRepository(dataSource);
});

final myCircleRepositoryProvider = Provider<MyCircleRepository>((ref) {
  final dataSource = ref.watch(firebaseDataSourceProvider);
  return FirebaseMyCircleRepository(dataSource);
});

final eventRepositoryProvider = Provider<EventRepository>((ref) {
  final dataSource = ref.watch(firebaseDataSourceProvider);
  return FirebaseEventRepository(dataSource);
});

final feedbackRepositoryProvider = Provider<FeedbackRepository>((ref) {
  final dataSource = ref.watch(firebaseDataSourceProvider);
  return FirebaseFeedbackRepository(dataSource);
});

/// Reactive auth user provider.
///
/// Follows Firebase auth state changes so any provider watching this
/// automatically re-evaluates on login / logout.
final currentUserProvider = StreamProvider<User?>((ref) {
  final dataSource = ref.watch(firebaseDataSourceProvider);
  return dataSource.authStateChanges;
});
