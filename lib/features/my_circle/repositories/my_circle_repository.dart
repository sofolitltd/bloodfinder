import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/utils/phone_utils.dart';
import '../../../data/datasources/remote/firebase_datasource.dart';

abstract class MyCircleRepository {
  Stream<List<Map<String, dynamic>>> contactsStream(String ownerId);
  Future<String> addContact(String ownerId, Map<String, dynamic> data);
  Future<void> removeContact(String ownerId, String contactId);

  /// Add multiple contacts atomically via WriteBatch.
  /// Returns the list of created document IDs.
  Future<List<String>> addContactsBatch(
      String ownerId, List<Map<String, dynamic>> contactsData);

  /// Given a list of phone numbers (raw or normalized), queries the `users`
  /// collection and returns a map of normalizedPhone → userId for matches.
  ///
  /// Queries in batches of 10 since Firestore `whereIn` caps at 10 values.
  Future<Map<String, String>> findRegisteredUsersByPhones(List<String> phones);

  /// Update a single contact document to link it to a registered user.
  Future<void> linkContactToUser(String contactId, String userId);

  /// Check if a single phone belongs to a registered user and update the
  /// contact document in place.
  Future<bool> checkAndLinkAppUser(
      String ownerId, String contactId, String phone);
}

class FirebaseMyCircleRepository implements MyCircleRepository {
  FirebaseMyCircleRepository(this._dataSource);

  final FirebaseDataSource _dataSource;

  static const int _batchSize = 10;

  CollectionReference<Map<String, dynamic>> get _contacts =>
      _dataSource.collection('contacts');

  @override
  Stream<List<Map<String, dynamic>>> contactsStream(String ownerId) =>
      _contacts
          .where('ownerId', isEqualTo: ownerId)
          .snapshots()
          .map((snap) => snap.docs.map((doc) {
                final data = doc.data();
                data['id'] = doc.id;
                return data;
              }).toList()
            ..sort((a, b) {
              final aTime = (a['createdAt'] as Timestamp?)?.toDate();
              final bTime = (b['createdAt'] as Timestamp?)?.toDate();
              return bTime!.compareTo(aTime!);
            }));

  @override
  Future<String> addContact(String ownerId, Map<String, dynamic> data) async {
    final docRef = await _contacts.add(data);
    return docRef.id;
  }

  @override
  Future<void> removeContact(String ownerId, String contactId) =>
      _contacts.doc(contactId).delete();

  @override
  Future<List<String>> addContactsBatch(
      String ownerId, List<Map<String, dynamic>> contactsData) async {
    final batch = _dataSource.firestore.batch();
    final ids = <String>[];

    for (final data in contactsData) {
      final docRef = _contacts.doc();
      batch.set(docRef, data);
      ids.add(docRef.id);
    }

    await batch.commit();
    return ids;
  }

  @override
  Future<Map<String, String>> findRegisteredUsersByPhones(
      List<String> phones) async {
    if (phones.isEmpty) return {};

    // Normalize all phones and deduplicate
    final normalizedSet = PhoneUtils.normalizedSet(phones);
    final normalizedList = normalizedSet.toList();

    final result = <String, String>{};
    final usersRef = _dataSource.collection('users');

    // Firestore whereIn supports up to 10 values per query
    for (var i = 0; i < normalizedList.length; i += _batchSize) {
      final chunk = normalizedList.sublist(
        i,
        i + _batchSize > normalizedList.length
            ? normalizedList.length
            : i + _batchSize,
      );

      // Try matching by normalized number
      final snap1 = await usersRef
          .where('mobileNumber', whereIn: chunk)
          .get();

      for (final doc in snap1.docs) {
        final storedPhone = doc.data()['mobileNumber'] as String? ?? '';
        final normalizedStored = PhoneUtils.normalize(storedPhone);
        result[normalizedStored] = doc.id;
      }

      // Also try with the +880 prefix variant for any that didn't match
      final missing = chunk.where((n) => !result.containsKey(n)).toList();
      if (missing.isNotEmpty) {
        final withPrefix = missing.map((n) {
          if (n.startsWith('880')) return '+$n';
          return n;
        }).toList();

        final snap2 = await usersRef
            .where('mobileNumber', whereIn: withPrefix)
            .get();

        for (final doc in snap2.docs) {
          final storedPhone = doc.data()['mobileNumber'] as String? ?? '';
          final normalizedStored = PhoneUtils.normalize(storedPhone);
          result[normalizedStored] = doc.id;
        }
      }
    }

    return result;
  }

  @override
  Future<void> linkContactToUser(String contactId, String userId) async {
    await _contacts.doc(contactId).update({
      'isAppUser': true,
      'linkedUserId': userId,
    });
  }

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
    await _contacts.doc(contactId).update({
      'isAppUser': true,
      'linkedUserId': linkedUserId,
    });
    return true;
  }
}
