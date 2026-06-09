/// App-wide configuration constants.
///
/// ⚠️ TESTING MODE:
/// [usersCollection] is set to 'users_test' so new code runs against
/// a separate collection and does NOT affect production data.
///
/// Before Play Store release → change [usersCollection] to 'users'.
class AppConfig {
  AppConfig._();

  /// Firestore collection name for user documents.
  /// Set to 'users_test' during development/testing.
  /// Change to 'users' before releasing to production.
  static const String usersCollection = 'users_test';
}
