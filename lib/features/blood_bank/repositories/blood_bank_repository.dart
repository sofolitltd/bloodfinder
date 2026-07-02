import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/utils/geohash.dart';
import '../../../data/datasources/remote/firebase_datasource.dart';

abstract class BloodBankRepository {
  Stream<QuerySnapshot<Map<String, dynamic>>> allBanksStream();
  Stream<QuerySnapshot<Map<String, dynamic>>> banksByProximityStream(
    double latitude,
    double longitude,
    double radiusInKm,
  );
  Future<QuerySnapshot<Map<String, dynamic>>> getPaginatedAllBanks(
    int limit, {
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
    String? country,
  });
  Future<QuerySnapshot<Map<String, dynamic>>> getPaginatedNearbyBanks(
    double latitude,
    double longitude,
    double radiusInKm,
    int limit, {
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  });
  Future<DocumentReference<Map<String, dynamic>>> addBank(
      Map<String, dynamic> data);
  Future<bool> isNameUnique(String name);
}

class FirebaseBloodBankRepository implements BloodBankRepository {
  FirebaseBloodBankRepository(this._dataSource);

  final FirebaseDataSource _dataSource;

  CollectionReference<Map<String, dynamic>> get _col =>
      _dataSource.collection('blood_bank');

  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> allBanksStream() =>
      _col.snapshots();

  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> banksByProximityStream(
    double latitude,
    double longitude,
    double radiusInKm,
  ) {
    final prefix = _geohashPrefix(latitude, longitude, radiusInKm);
    return _col
        .where('geohash', isGreaterThanOrEqualTo: prefix)
        .where('geohash', isLessThanOrEqualTo: '$prefix\uf8ff')
        .orderBy('geohash')
        .snapshots();
  }

  @override
  Future<QuerySnapshot<Map<String, dynamic>>> getPaginatedAllBanks(
    int limit, {
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
    String? country,
  }) {
    Query<Map<String, dynamic>> query;
    if (country != null) {
      query = _col
          .where('country', isEqualTo: country)
          .orderBy('name')
          .limit(limit);
    } else {
      query = _col.orderBy('name').limit(limit);
    }
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }
    return query.get();
  }

  @override
  Future<QuerySnapshot<Map<String, dynamic>>> getPaginatedNearbyBanks(
    double latitude,
    double longitude,
    double radiusInKm,
    int limit, {
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  }) {
    final prefix = _geohashPrefix(latitude, longitude, radiusInKm);
    var query = _col
        .where('geohash', isGreaterThanOrEqualTo: prefix)
        .where('geohash', isLessThanOrEqualTo: '$prefix\uf8ff')
        .orderBy('geohash')
        .limit(limit);
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }
    return query.get();
  }

  String _geohashPrefix(double latitude, double longitude, double radiusInKm) {
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
    return centerHash.substring(0, precision);
  }

  @override
  Future<DocumentReference<Map<String, dynamic>>> addBank(
          Map<String, dynamic> data) =>
      _col.add(data);

  @override
  Future<bool> isNameUnique(String name) =>
      _col
          .where('name', isEqualTo: name)
          .get()
          .then((snap) => snap.docs.isEmpty);
}
