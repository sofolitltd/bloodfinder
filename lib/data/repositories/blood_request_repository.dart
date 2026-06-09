import 'package:cloud_firestore/cloud_firestore.dart';

import '../../data/datasources/remote/firebase_datasource.dart';

abstract class BloodRequestRepository {
  Future<DocumentReference<Map<String, dynamic>>> createRequest(
      Map<String, dynamic> data);
  Future<void> updateRequest(String requestId, Map<String, dynamic> data);
  Future<void> deleteRequest(String requestId);
  Future<void> updateRequestStatus(String requestId, String status);

  Stream<QuerySnapshot<Map<String, dynamic>>> userRequestsStream(String uid);
  Stream<DocumentSnapshot<Map<String, dynamic>>> requestStream(String requestId);

  Stream<QuerySnapshot<Map<String, dynamic>>> requestsByDistrict(
      String district,
      {String? subdistrict});
  Future<QuerySnapshot<Map<String, dynamic>>> getSubdistricts(String district);
}

class FirebaseBloodRequestRepository implements BloodRequestRepository {
  FirebaseBloodRequestRepository(this._dataSource);

  final FirebaseDataSource _dataSource;

  @override
  Future<DocumentReference<Map<String, dynamic>>> createRequest(
          Map<String, dynamic> data) async {
    final docRef = _dataSource.collection('blood_requests').doc();
    data['id'] = docRef.id;
    await docRef.set(data);
    return docRef;
  }

  @override
  Future<void> deleteRequest(String requestId) =>
      _dataSource.document('blood_requests/$requestId').delete();

  @override
  Future<void> updateRequest(String requestId, Map<String, dynamic> data) =>
      _dataSource.document('blood_requests/$requestId').update(data);

  @override
  Future<void> updateRequestStatus(String requestId, String status) =>
      _dataSource.document('blood_requests/$requestId').update({'status': status});

  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> userRequestsStream(String uid) =>
      _dataSource
          .collection('blood_requests')
          .where('uid', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .snapshots();

  @override
  Stream<DocumentSnapshot<Map<String, dynamic>>> requestStream(
          String requestId) =>
      _dataSource.document('blood_requests/$requestId').snapshots();

  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> requestsByDistrict(
      String district,
      {String? subdistrict}) {
    var query = _dataSource
        .collection('blood_requests')
        .where('district', isEqualTo: district)
        .orderBy('createdAt', descending: true);
    if (subdistrict != null && subdistrict.isNotEmpty) {
      query = query.where('subdistrict', isEqualTo: subdistrict);
    }
    return query.snapshots();
  }

  @override
  Future<QuerySnapshot<Map<String, dynamic>>> getSubdistricts(
          String district) =>
      _dataSource
          .collection('blood_requests')
          .where('district', isEqualTo: district)
          .get();
}
