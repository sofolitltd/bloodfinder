import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/utils/geohash.dart';
import '../../../data/datasources/remote/firebase_datasource.dart';

abstract class FeedRepository {
  Future<QuerySnapshot<Map<String, dynamic>>> getRequests({
    String? bloodGroup,
    double? latitude,
    double? longitude,
    double? radiusInKm,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
    int limit = 10,
  });
}

class FirebaseFeedRepository implements FeedRepository {
  FirebaseFeedRepository(this._dataSource);

  final FirebaseDataSource _dataSource;

  @override
  Future<QuerySnapshot<Map<String, dynamic>>> getRequests({
    String? bloodGroup,
    double? latitude,
    double? longitude,
    double? radiusInKm,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
    int limit = 10,
  }) {
    var query = _dataSource
        .collection('blood_requests') as Query<Map<String, dynamic>>;

    // Blood group filter
    if (bloodGroup != null && bloodGroup.isNotEmpty) {
      query = query.where('bloodGroup', isEqualTo: bloodGroup);
    }

    // Proximity filter via geohash prefix
    if (latitude != null && longitude != null && radiusInKm != null) {
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

      query = query
          .where('geohash', isGreaterThanOrEqualTo: prefix)
          .where('geohash', isLessThanOrEqualTo: '$prefix\uf8ff')
          .orderBy('geohash');
    } else {
      // No proximity — just sort by newest first
      query = query.orderBy('createdAt', descending: true);
    }

    query = query.limit(limit);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    return query.get();
  }
}
