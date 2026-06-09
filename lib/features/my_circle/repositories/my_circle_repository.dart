import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../data/datasources/remote/firebase_datasource.dart';

abstract class MyCircleRepository {
  Stream<List<Map<String, dynamic>>> contactsStream(String ownerId);
  Future<void> addContact(String ownerId, Map<String, dynamic> data);
  Future<void> removeContact(String ownerId, String contactId);
  Future<bool> checkAndLinkAppUser(String ownerId, String contactId, String phone);
}

class FirebaseMyCircleRepository implements MyCircleRepository {
  FirebaseMyCircleRepository(this._dataSource);

  final FirebaseDataSource _dataSource;

  CollectionReference<Map<String, dynamic>> _contactsRef(String ownerId) =>
      _dataSource.collection('personal_networks/$ownerId/contacts');

  @override
  Stream<List<Map<String, dynamic>>> contactsStream(String ownerId) =>
      _contactsRef(ownerId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snap) => snap.docs.map((doc) {
                final data = doc.data();
                data['id'] = doc.id;
                return data;
              }).toList());

  @override
  Future<void> addContact(String ownerId, Map<String, dynamic> data) =>
      _contactsRef(ownerId).add(data);

  @override
  Future<void> removeContact(String ownerId, String contactId) =>
      _contactsRef(ownerId).doc(contactId).delete();

  @override
  Future<bool> checkAndLinkAppUser(
      String ownerId, String contactId, String phone) async {
    final userSnap = await _dataSource
        .collection('users')
        .where('mobileNumber', isEqualTo: phone)
        .limit(1)
        .get();

    if (userSnap.docs.isEmpty) return false;

    final linkedUserId = userSnap.docs.first.id;
    await _contactsRef(ownerId).doc(contactId).update({
      'isAppUser': true,
      'linkedUserId': linkedUserId,
    });
    return true;
  }
}
