import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/utils/geohash.dart';
import '../../../data/datasources/remote/firebase_datasource.dart';

abstract class EventRepository {
  Stream<QuerySnapshot<Map<String, dynamic>>> nearbyEventsStream(
    double latitude,
    double longitude,
    double radiusInKm,
  );
  Stream<QuerySnapshot<Map<String, dynamic>>> userEventsStream(String uid);
  Future<DocumentReference<Map<String, dynamic>>> createEvent(
      Map<String, dynamic> data);
  Future<void> updateEvent(String eventId, Map<String, dynamic> data);
  Future<void> deleteEvent(String eventId);
  Future<void> rsvpEvent(String eventId, String uid);
  Future<void> cancelRsvp(String eventId, String uid);
  Stream<DocumentSnapshot<Map<String, dynamic>>> rsvpStream(
      String eventId, String uid);
  Stream<DocumentSnapshot<Map<String, dynamic>>> eventStream(String eventId);
  Stream<QuerySnapshot<Map<String, dynamic>>> allEventsStream();

  // Paginated queries
  Future<QuerySnapshot<Map<String, dynamic>>> getPaginatedNearbyEvents(
    double latitude,
    double longitude,
    double radiusInKm,
    int limit, {
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  });
  Future<QuerySnapshot<Map<String, dynamic>>> getPaginatedEventsByCountry(
    String country,
    int limit, {
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  });
}

class FirebaseEventRepository implements EventRepository {
  FirebaseEventRepository(this._dataSource);

  final FirebaseDataSource _dataSource;

  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> nearbyEventsStream(
    double latitude,
    double longitude,
    double radiusInKm,
  ) {
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

    return _dataSource
        .collection('events')
        .where('geohash', isGreaterThanOrEqualTo: prefix)
        .where('geohash', isLessThanOrEqualTo: '$prefix\uf8ff')
        .orderBy('geohash')
        .orderBy('eventDate', descending: true)
        .snapshots();
  }

  @override
  Future<DocumentReference<Map<String, dynamic>>> createEvent(
          Map<String, dynamic> data) =>
      _dataSource.collection('events').add(data);

  @override
  Future<void> updateEvent(String eventId, Map<String, dynamic> data) async {
    await _dataSource.document('events/$eventId').update(data);
  }

  @override
  Future<void> deleteEvent(String eventId) async {
    final rsvps = await _dataSource
        .collection('event_rsvps')
        .where('eventId', isEqualTo: eventId)
        .get();
    final batch = _dataSource.batch();
    for (final doc in rsvps.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_dataSource.document('events/$eventId'));
    await batch.commit();
  }

  @override
  Future<void> rsvpEvent(String eventId, String uid) async {
    final batch = _dataSource.batch();
    final eventRef = _dataSource.document('events/$eventId');
    final rsvpRef =
        _dataSource.document('event_rsvps/${eventId}_$uid');
    batch.update(eventRef, {'rsvpCount': FieldValue.increment(1)});
    batch.set(rsvpRef, {
      'eventId': eventId,
      'uid': uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  @override
  Future<void> cancelRsvp(String eventId, String uid) async {
    final batch = _dataSource.batch();
    final eventRef = _dataSource.document('events/$eventId');
    final rsvpRef =
        _dataSource.document('event_rsvps/${eventId}_$uid');
    batch.update(eventRef, {'rsvpCount': FieldValue.increment(-1)});
    batch.delete(rsvpRef);
    await batch.commit();
  }

  @override
  Stream<DocumentSnapshot<Map<String, dynamic>>> rsvpStream(
          String eventId, String uid) =>
      _dataSource.document('event_rsvps/${eventId}_$uid').snapshots();

  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> userEventsStream(String uid) =>
      _dataSource
          .collection('events')
          .where('organizerUid', isEqualTo: uid)
          .snapshots();

  @override
  Stream<DocumentSnapshot<Map<String, dynamic>>> eventStream(
          String eventId) =>
      _dataSource.document('events/$eventId').snapshots();

  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> allEventsStream() =>
      _dataSource
          .collection('events')
          .snapshots();

  @override
  Future<QuerySnapshot<Map<String, dynamic>>> getPaginatedNearbyEvents(
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
        .collection('events')
        .where('geohash', isGreaterThanOrEqualTo: prefix)
        .where('geohash', isLessThanOrEqualTo: '$prefix')
        .orderBy('geohash')
        .orderBy('eventDate', descending: true)
        .limit(limit);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }
    return query.get();
  }

  @override
  Future<QuerySnapshot<Map<String, dynamic>>> getPaginatedEventsByCountry(
    String country,
    int limit, {
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  }) {
    var query = _dataSource
        .collection('events')
        .where('country', isEqualTo: country)
        .orderBy('eventDate', descending: true)
        .limit(limit);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }
    return query.get();
  }
}
