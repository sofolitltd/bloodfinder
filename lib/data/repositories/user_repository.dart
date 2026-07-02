import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/config/app_config.dart';
import '../../core/utils/geohash.dart';
import '../../data/datasources/remote/firebase_datasource.dart';

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
  Stream<QuerySnapshot<Map<String, dynamic>>> emergencyDonorsStream();
  Future<QuerySnapshot<Map<String, dynamic>>> getPaginatedEmergencyDonors(
    int limit, {
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
  Stream<QuerySnapshot<Map<String, dynamic>>> emergencyDonorsStream() =>
      _dataSource
          .collection(_col)
          .where('isEmergencyDonor', isEqualTo: true)
          .snapshots();

  @override
  Future<QuerySnapshot<Map<String, dynamic>>> getPaginatedEmergencyDonors(
    int limit, {
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  }) {
    var query = _dataSource
        .collection(_col)
        .where('isEmergencyDonor', isEqualTo: true)
        .orderBy('name')
        .limit(limit);
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
