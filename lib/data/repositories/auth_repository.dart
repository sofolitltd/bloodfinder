import 'package:firebase_auth/firebase_auth.dart';

import '../datasources/remote/firebase_datasource.dart';

abstract class AuthRepository {
  User? get currentUser;
  Stream<User?> get authStateChanges;
  Future<UserCredential> signIn({required String email, required String password});
  Future<UserCredential> signUp({required String email, required String password});
  Future<void> signOut();
  Future<void> sendPasswordReset(String email);
  Future<void> changePassword({
    required String email,
    required String currentPassword,
    required String newPassword,
  });
}

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this._dataSource);

  final FirebaseDataSource _dataSource;

  @override
  User? get currentUser => _dataSource.currentUser;

  @override
  Stream<User?> get authStateChanges => _dataSource.authStateChanges;

  @override
  Future<UserCredential> signIn({required String email, required String password}) =>
      _dataSource.signIn(email, password);

  @override
  Future<UserCredential> signUp({required String email, required String password}) =>
      _dataSource.signUp(email, password);

  @override
  Future<void> signOut() => _dataSource.signOut();

  @override
  Future<void> sendPasswordReset(String email) =>
      _dataSource.sendPasswordReset(email);

  @override
  Future<void> changePassword({
    required String email,
    required String currentPassword,
    required String newPassword,
  }) =>
      _dataSource.changePassword(
        email: email,
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
}
