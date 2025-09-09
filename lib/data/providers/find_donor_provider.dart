import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_model.dart';

// Donor StateNotifier
class DonorNotifier extends StateNotifier<List<UserModel>> {
  DonorNotifier() : super([]);

  bool _hasMore = true;
  DocumentSnapshot? _lastDoc;
  static const int _pageSize = 10;

  Future<void> fetchDonors({
    required String bloodGroup,
    String? district,
    String? subdistrict,
    bool reset = false,
  }) async {
    if (!_hasMore && !reset) return;

    if (reset) {
      state = [];
      _hasMore = true;
      _lastDoc = null;
    }

    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('users')
        .where('isDonor', isEqualTo: true)
        .where('bloodGroup', isEqualTo: bloodGroup)
        .limit(_pageSize);

    if (district != null && district.isNotEmpty) {
      query = query.where('district', isEqualTo: district);
    }

    if (subdistrict != null && subdistrict.isNotEmpty) {
      query = query.where('subdistrict', isEqualTo: subdistrict);
    }

    if (_lastDoc != null) {
      query = query.startAfterDocument(_lastDoc!);
    }

    final snapshot = await query.get();

    if (snapshot.docs.isNotEmpty) {
      _lastDoc = snapshot.docs.last;
      state = [
        ...state,
        ...snapshot.docs.map((e) => UserModel.fromJson(e.data())),
      ];
    }

    if (snapshot.docs.length < _pageSize) {
      _hasMore = false;
    }
  }

  void reset() {
    state = [];
    _hasMore = true;
    _lastDoc = null;
  }
}

// Riverpod Provider
final donorProvider = StateNotifierProvider<DonorNotifier, List<UserModel>>(
  (ref) => DonorNotifier(),
);
