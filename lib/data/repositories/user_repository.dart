import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/config/app_config.dart';
import '../../core/utils/geohash.dart';
import '../../core/utils/phone_utils.dart';
import '../../data/datasources/remote/firebase_datasource.dart';
import '../models/user_model.dart';

abstract class UserRepository {
  DocumentReference<Map<String, dynamic>> userDoc(String uid);
  Future<DocumentSnapshot<Map<String, dynamic>>> getUser(String uid);
  Future<void> createUser(String uid, Map<String, dynamic> data);
  Future<void> updateUser(String uid, Map<String, dynamic> data);
  Future<QuerySnapshot<Map<String, dynamic>>> searchUsers({
    int limit = 10,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  });
  Stream<DocumentSnapshot<Map<String, dynamic>>> userStream(String uid);

  /// Search for donors near [latitude]/[longitude] within [radiusInKm].
  /// Always uses geohash proximity — no text-based district/country filtering.
  Stream<QuerySnapshot<Map<String, dynamic>>> usersByDonors({
    required String bloodGroup,
    required double latitude,
    required double longitude,
    required double radiusInKm,
    int limit = 10,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  });

  Future<QuerySnapshot<Map<String, dynamic>>> getUsersByIds(List<String> uids);
  Future<UserModel?> findUserByPhone(String phone);
  Future<UserModel?> findUserByEmail(String email);
  Future<List<UserModel>> searchUsersByName(String query);

  /// Dispatches to phone/email/name lookup based on the shape of [query].
  Future<List<UserModel>> searchRegisteredUsers(String query);
  Stream<QuerySnapshot<Map<String, dynamic>>> emergencyDonorsStream();
  Future<QuerySnapshot<Map<String, dynamic>>> getUsersByCountry(
    String country,
  );
  Future<QuerySnapshot<Map<String, dynamic>>> getPaginatedEmergencyDonors(
    int limit, {
    String? country,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  });
  Future<QuerySnapshot<Map<String, dynamic>>> getPaginatedEmergencyDonorsByProximity(
    double latitude,
    double longitude,
    double radiusInKm,
    int limit, {
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  });
  Future<void> updateToken(String uid, String token);
  Future<void> updateOnlineStatus(String uid, bool isOnline);

  /// Top-level donations collection.
  CollectionReference<Map<String, dynamic>> donationCollection();
  Future<DocumentReference<Map<String, dynamic>>> addDonation(
      String uid, Map<String, dynamic> data);
  Future<void> deleteDonation(String uid, String docId);
  Stream<QuerySnapshot<Map<String, dynamic>>> donationsStream(String uid);
}

class FirebaseUserRepository implements UserRepository {
  FirebaseUserRepository(this._dataSource);

  final FirebaseDataSource _dataSource;

  // Collection name from AppConfig.
  String get _col => AppConfig.usersCollection;

  @override
  DocumentReference<Map<String, dynamic>> userDoc(String uid) =>
      _dataSource.document('$_col/$uid');

  @override
  Future<DocumentSnapshot<Map<String, dynamic>>> getUser(String uid) =>
      userDoc(uid).get();

  @override
  Future<void> createUser(String uid, Map<String, dynamic> data) =>
      userDoc(uid).set(data);

  @override
  Future<void> updateUser(String uid, Map<String, dynamic> data) =>
      userDoc(uid).update(data);

  @override
  Future<QuerySnapshot<Map<String, dynamic>>> searchUsers({
    int limit = 10,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  }) {
    var query = _dataSource
        .collection(_col)
        .orderBy('mobileNumber')
        .limit(limit);
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }
    return query.get();
  }

  @override
  Stream<DocumentSnapshot<Map<String, dynamic>>> userStream(String uid) =>
      userDoc(uid).snapshots();

  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> usersByDonors({
    required String bloodGroup,
    required double latitude,
    required double longitude,
    required double radiusInKm,
    int limit = 10,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  }) {
    // Determine geohash precision from radius
    int precision;
    if (radiusInKm <= 1.0) {
      precision = 7; // ~153 m
    } else if (radiusInKm <= 5.0) {
      precision = 6; // ~1.2 km
    } else if (radiusInKm <= 20.0) {
      precision = 5; // ~4.9 km
    } else if (radiusInKm <= 80.0) {
      precision = 4; // ~39 km
    } else {
      precision = 3; // ~156 km
    }

    final centerHash = Geohash.encode(latitude, longitude);
    final prefix = centerHash.substring(0, precision);

    var query = _dataSource
        .collection(_col)
        .where('isDonor', isEqualTo: true)
        .where('bloodGroup', isEqualTo: bloodGroup)
        .where('geohash', isGreaterThanOrEqualTo: prefix)
        .where('geohash', isLessThanOrEqualTo: '$prefix\uf8ff')
        .orderBy('geohash')
        .limit(limit);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    return query.snapshots();
  }

  @override
  Future<QuerySnapshot<Map<String, dynamic>>> getUsersByIds(
          List<String> uids) =>
      _dataSource
          .collection(_col)
          .where(FieldPath.documentId, whereIn: uids)
          .get();

  @override
  Future<UserModel?> findUserByPhone(String phone) async {
    final normalized = PhoneUtils.normalize(phone);
    final usersRef = _dataSource.collection(_col);

    var snap = await usersRef
        .where('mobileNumber', isEqualTo: normalized)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) {
      // Retry with the +880 prefix variant, since stored numbers may use
      // either the bare-digits or canonical E.164 format.
      final withPrefix =
          normalized.startsWith('880') ? '+$normalized' : normalized;
      snap = await usersRef
          .where('mobileNumber', isEqualTo: withPrefix)
          .limit(1)
          .get();
    }

    if (snap.docs.isEmpty) return null;
    return UserModel.fromFirestore(snap.docs.first);
  }

  @override
  Future<UserModel?> findUserByEmail(String email) async {
    final usersRef = _dataSource.collection(_col);
    final trimmed = email.trim();

    var snap = await usersRef
        .where('email', isEqualTo: trimmed.toLowerCase())
        .limit(1)
        .get();

    if (snap.docs.isEmpty && trimmed != trimmed.toLowerCase()) {
      // Stored casing isn't guaranteed, so retry with the as-typed value.
      snap = await usersRef.where('email', isEqualTo: trimmed).limit(1).get();
    }

    if (snap.docs.isEmpty) return null;
    return UserModel.fromFirestore(snap.docs.first);
  }

  @override
  Future<List<UserModel>> searchUsersByName(String query) async {
    final usersRef = _dataSource.collection(_col);
    if (query.isEmpty) return [];

    final variants = <String>{
      query,
      '${query[0].toUpperCase()}${query.substring(1)}',
      '${query[0].toLowerCase()}${query.substring(1)}',
    };

    final results = <String, UserModel>{};
    for (final variant in variants) {
      for (final field in ['firstName', 'lastName']) {
        final snap = await usersRef
            .where(field, isGreaterThanOrEqualTo: variant)
            .where(field, isLessThanOrEqualTo: '$variant')
            .limit(10)
            .get();
        for (final doc in snap.docs) {
          results[doc.id] = UserModel.fromFirestore(doc);
        }
      }
    }
    return results.values.toList();
  }

  @override
  Future<List<UserModel>> searchRegisteredUsers(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return [];

    if (trimmed.contains('@')) {
      final user = await findUserByEmail(trimmed);
      return user != null ? [user] : [];
    }

    final digitCount = trimmed.replaceAll(RegExp(r'[^0-9]'), '').length;
    final looksLikePhone = digitCount >= 6 &&
        RegExp(r'^[0-9+\-\s()]+$').hasMatch(trimmed);
    if (looksLikePhone) {
      final user = await findUserByPhone(trimmed);
      return user != null ? [user] : [];
    }

    return searchUsersByName(trimmed);
  }

  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> emergencyDonorsStream() =>
      _dataSource
          .collection(_col)
          .where('isEmergencyDonor', isEqualTo: true)
          .snapshots();

  @override
  Future<QuerySnapshot<Map<String, dynamic>>> getPaginatedEmergencyDonors(
    int limit, {
    String? country,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  }) {
    Query<Map<String, dynamic>> query = _dataSource
        .collection(_col)
        .where('isEmergencyDonor', isEqualTo: true);
    if (country != null && country.isNotEmpty) {
      query = query.where('country', isEqualTo: country);
    }
    query = query.orderBy('firstName').limit(limit);
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }
    return query.get();
  }

  @override
  Future<QuerySnapshot<Map<String, dynamic>>>
      getPaginatedEmergencyDonorsByProximity(
    double latitude,
    double longitude,
    double radiusInKm,
    int limit, {
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  }) {
    int precision;
    if (radiusInKm <= 1.0) {
      precision = 7;
    } else if (radiusInKm <= 5.0) {
      precision = 6;
    } else if (radiusInKm <= 20.0) {
      precision = 5;
    } else if (radiusInKm <= 80.0) {
      precision = 4;
    } else {
      precision = 3;
    }
    final centerHash = Geohash.encode(latitude, longitude);
    final prefix = centerHash.substring(0, precision);

    var query = _dataSource
        .collection(_col)
        .where('isEmergencyDonor', isEqualTo: true)
        .where('geohash', isGreaterThanOrEqualTo: prefix)
        .where('geohash', isLessThanOrEqualTo: '$prefix\uf8ff')
        .orderBy('geohash')
        .limit(limit);
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }
    return query.get();
  }

  @override
  Future<QuerySnapshot<Map<String, dynamic>>> getUsersByCountry(
    String country,
  ) =>
      _dataSource
          .collection(_col)
          .where('country', isEqualTo: country)
          .get();

  @override
  Future<void> updateToken(String uid, String token) =>
      updateUser(uid, {'token': token});

  @override
  Future<void> updateOnlineStatus(String uid, bool isOnline) =>
      updateUser(uid, {'isOnline': isOnline});

  @override
  CollectionReference<Map<String, dynamic>> donationCollection() =>
      _dataSource.collection('donations');

  @override
  Future<DocumentReference<Map<String, dynamic>>> addDonation(
      String uid, Map<String, dynamic> data) {
    // Ensure the uid field is always set for top-level queries.
    data['uid'] = uid;
    return donationCollection().add(data);
  }

  @override
  Future<void> deleteDonation(String uid, String docId) =>
      donationCollection().doc(docId).delete();

  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> donationsStream(String uid) =>
      donationCollection()
          .where('uid', isEqualTo: uid)
          .orderBy('donationDate', descending: true)
          .snapshots();
}
