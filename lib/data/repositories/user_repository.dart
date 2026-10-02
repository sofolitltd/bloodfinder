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

  /// Returns the single admin-added, not-yet-claimed record matching
  /// [canonicalPhone], or `null` if there's none or more than one (an
  /// ambiguous match, e.g. a shared household phone, is left unclaimed
  /// rather than guessed at).
  Future<DocumentSnapshot<Map<String, dynamic>>?> findUnclaimedByPhone(
      String canonicalPhone);
  Future<DocumentSnapshot<Map<String, dynamic>>?> findUnclaimedByEmail(
      String email);

  /// Merges an admin-added placeholder record (at [placeholderId]) into the
  /// freshly self-registered account at [newUid], reassigns the donations /
  /// blood requests / emergency-donor / community-membership records that
  /// referenced the placeholder, and removes the placeholder doc.
  Future<void> claimUnclaimedUser({
    required String placeholderId,
    required String newUid,
    required Map<String, dynamic> selfRegisteredData,
  });

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
  Future<DocumentSnapshot<Map<String, dynamic>>?> findUnclaimedByPhone(
      String canonicalPhone) async {
    final snap = await _dataSource
        .collection(_col)
        .where('mobileNumber', isEqualTo: canonicalPhone)
        .where('accountStatus', isEqualTo: 'unclaimed')
        .limit(2)
        .get();
    return snap.docs.length == 1 ? snap.docs.first : null;
  }

  @override
  Future<DocumentSnapshot<Map<String, dynamic>>?> findUnclaimedByEmail(
      String email) async {
    final snap = await _dataSource
        .collection(_col)
        .where('email', isEqualTo: email)
        .where('accountStatus', isEqualTo: 'unclaimed')
        .limit(2)
        .get();
    return snap.docs.length == 1 ? snap.docs.first : null;
  }

  @override
  Future<void> claimUnclaimedUser({
    required String placeholderId,
    required String newUid,
    required Map<String, dynamic> selfRegisteredData,
  }) async {
    final placeholderRef = userDoc(placeholderId);
    final placeholderSnap = await placeholderRef.get();
    final placeholderData = placeholderSnap.data() ?? <String, dynamic>{};

    // Fields the signup form collects (name/email/blood group/dob/etc.) take
    // priority; anything only the admin recorded (district, currentAddress,
    // isBanned, donationCount, ...) survives because selfRegisteredData
    // doesn't define those keys.
    final merged = <String, dynamic>{...placeholderData, ...selfRegisteredData};
    merged['authUid'] = newUid;
    merged['accountStatus'] = 'active';
    merged['claimedAt'] = DateTime.now().toIso8601String();
    merged['createdAt'] =
        placeholderData['createdAt'] ?? selfRegisteredData['createdAt'];
    // `selfRegisteredData` always carries its own defaults ('self'/null) for
    // these two, which would otherwise stomp on the admin-provenance audit
    // trail from the placeholder record.
    merged['createdBy'] = placeholderData['createdBy'] ?? 'self';
    merged['createdByAdminEmail'] = placeholderData['createdByAdminEmail'];

    final batch = _dataSource.batch();
    batch.set(userDoc(newUid), merged);
    batch.delete(placeholderRef);

    // Donations/blood requests reference the owner via a `uid` field on an
    // otherwise independent doc ID — just repoint that field.
    for (final col in ['donations', 'blood_requests']) {
      final snap = await _dataSource
          .collection(col)
          .where('uid', isEqualTo: placeholderId)
          .get();
      for (final doc in snap.docs) {
        batch.update(doc.reference, {'uid': newUid});
      }
    }

    // emergency_donor uses the uid itself as the doc ID, so it has to be
    // recreated under the new uid rather than field-updated.
    final emergencyDonorSnap =
        await _dataSource.document('emergency_donor/$placeholderId').get();
    if (emergencyDonorSnap.exists) {
      batch.set(_dataSource.document('emergency_donor/$newUid'), {});
      batch.delete(emergencyDonorSnap.reference);
    }

    // community_members doc IDs are `${communityId}_$uid`, so these also
    // need to be recreated under the new uid.
    final memberSnap = await _dataSource
        .collection('community_members')
        .where('uid', isEqualTo: placeholderId)
        .get();
    for (final doc in memberSnap.docs) {
      final communityId = doc.data()['communityId'] as String?;
      if (communityId == null) continue;
      batch.set(
        _dataSource.document('community_members/${communityId}_$newUid'),
        {...doc.data(), 'uid': newUid},
      );
      batch.delete(doc.reference);
    }

    await batch.commit();
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
