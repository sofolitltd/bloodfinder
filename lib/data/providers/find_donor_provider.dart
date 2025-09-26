import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_model.dart';

class DonorNotifier extends AsyncNotifier<List<UserModel>> {
  bool _hasMore = true;
  DocumentSnapshot? _lastDoc;
  static const int _pageSize = 10;

  @override
  Future<List<UserModel>> build() async {
    // initial empty state
    return [];
  }

  Future<void> fetchDonors({
    required String bloodGroup,
    String? district,
    String? subdistrict,
    bool reset = false,
  }) async {
    if (!_hasMore && !reset) return;

    if (reset) {
      state = const AsyncValue.data([]);
      _hasMore = true;
      _lastDoc = null;
    }

    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('users')
        .where('isDonor', isEqualTo: true)
        .where('bloodGroup', isEqualTo: bloodGroup)
        .limit(_pageSize);

    if (district?.isNotEmpty ?? false) {
      query = query.where('district', isEqualTo: district);
    }
    if (subdistrict?.isNotEmpty ?? false) {
      query = query.where('subdistrict', isEqualTo: subdistrict);
    }
    if (_lastDoc != null) {
      query = query.startAfterDocument(_lastDoc!);
    }

    final snapshot = await query.get();

    if (snapshot.docs.isNotEmpty) {
      _lastDoc = snapshot.docs.last;
      final newList = [
        ...state.value ?? [],
        ...snapshot.docs.map((e) => UserModel.fromJson(e.data())),
      ];
      state = AsyncValue.data(newList);
    }

    if (snapshot.docs.length < _pageSize) {
      _hasMore = false;
    }
  }

  void reset() {
    state = const AsyncValue.data([]);
    _hasMore = true;
    _lastDoc = null;
  }
}

// ✅ Riverpod Provider (new API)
final donorProvider = AsyncNotifierProvider<DonorNotifier, List<UserModel>>(
  DonorNotifier.new,
);
