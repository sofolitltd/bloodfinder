import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../data/datasources/remote/firebase_datasource.dart';

abstract class EmergencyDonorRepository {
  Future<QuerySnapshot<Map<String, dynamic>>> getAllDonors();
  Future<void> addDonor(String uid);
  Future<void> removeDonor(String uid);
}

class FirebaseEmergencyDonorRepository implements EmergencyDonorRepository {
  FirebaseEmergencyDonorRepository(this._dataSource);

  final FirebaseDataSource _dataSource;

  @override
  Future<QuerySnapshot<Map<String, dynamic>>> getAllDonors() =>
      _dataSource.collection('emergency_donor').get();

  @override
  Future<void> addDonor(String uid) =>
      _dataSource.document('emergency_donor/$uid').set({});

  @override
  Future<void> removeDonor(String uid) =>
      _dataSource.document('emergency_donor/$uid').delete();
}
