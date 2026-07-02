import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseDataSource {
  FirebaseDataSource({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
    FirebaseMessaging? messaging,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance,
        _messaging = messaging ?? FirebaseMessaging.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final FirebaseMessaging _messaging;

  // Auth
  FirebaseAuth get auth => _auth;
  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  Future<UserCredential> signIn(String email, String password) =>
      _auth.signInWithEmailAndPassword(email: email, password: password);
  Future<UserCredential> signUp(String email, String password) =>
      _auth.createUserWithEmailAndPassword(email: email, password: password);
  Future<void> signOut() => _auth.signOut();
  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email);

  Future<void> changePassword({
    required String email,
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user logged in');

    final credential = EmailAuthProvider.credential(
      email: email,
      password: currentPassword,
    );
    await user.reauthenticateWithCredential(credential);
    await user.updatePassword(newPassword);
  }

  static bool isDevMode = false;

  String _redirectPath(String path) {
    if (!isDevMode) return path;
    final segments = path.split('/');
    for (int i = 0; i < segments.length; i += 2) {
      final collectionName = segments[i];
      if (!collectionName.endsWith('_test')) {
        segments[i] = '${collectionName}_test';
      }
    }
    return segments.join('/');
  }

  String _redirectCollectionGroup(String path) {
    if (!isDevMode) return path;
    if (!path.endsWith('_test')) {
      return '${path}_test';
    }
    return path;
  }

  // Firestore
  FirebaseFirestore get firestore => _firestore;

  CollectionReference<Map<String, dynamic>> collection(String path) =>
      _firestore.collection(_redirectPath(path));

  Query<Map<String, dynamic>> collectionGroup(String path) =>
      _firestore.collectionGroup(_redirectCollectionGroup(path));

  DocumentReference<Map<String, dynamic>> document(String path) =>
      _firestore.doc(_redirectPath(path));

  WriteBatch batch() => _firestore.batch();

  // Storage
  FirebaseStorage get storage => _storage;
  Reference storageRef(String path) {
    if (!isDevMode) return _storage.ref(path);
    // Prefix storage paths with test/ in development
    if (path.startsWith('/')) {
      return _storage.ref('/test$path');
    }
    return _storage.ref('test/$path');
  }

  // Messaging
  FirebaseMessaging get messaging => _messaging;
  Future<String?> get fcmToken => _messaging.getToken();
  Future<void> subscribeToTopic(String topic) =>
      _messaging.subscribeToTopic(topic);
  Future<void> deleteToken() => _messaging.deleteToken();
}
