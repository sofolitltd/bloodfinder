import 'dart:io';

import '../../data/datasources/remote/firebase_datasource.dart';

abstract class StorageRepository {
  Future<String> uploadFile(File file, String storagePath);
  Future<void> deleteFile(String storagePath);
}

class FirebaseStorageRepository implements StorageRepository {
  FirebaseStorageRepository(this._dataSource);

  final FirebaseDataSource _dataSource;

  @override
  Future<String> uploadFile(File file, String storagePath) async {
    final ref = _dataSource.storageRef(storagePath);
    await ref.putFile(file);
    return ref.getDownloadURL();
  }

  @override
  Future<void> deleteFile(String storagePath) async {
    await _dataSource.storageRef(storagePath).delete();
  }
}
