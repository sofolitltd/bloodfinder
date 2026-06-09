import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/user_model.dart';
import '../../../data/providers/repository_providers.dart';

class DonorNotifier extends AsyncNotifier<List<UserModel>> {
  bool _hasMore = true;
  DocumentSnapshot<Map<String, dynamic>>? _lastDoc;
  static const int _pageSize = 10;

  @override
  Future<List<UserModel>> build() async => [];

  Future<void> fetchDonors({
    required String bloodGroup,
    required double latitude,
    required double longitude,
    required double radiusInKm,
    bool reset = false,
  }) async {
    if (!_hasMore && !reset) return;

    if (reset) {
      state = const AsyncValue.data([]);
      _hasMore = true;
      _lastDoc = null;
    }

    final userRepo = ref.read(userRepositoryProvider);
    final snapshot = await userRepo
        .usersByDonors(
          bloodGroup: bloodGroup,
          latitude: latitude,
          longitude: longitude,
          radiusInKm: radiusInKm,
          limit: _pageSize,
          startAfter: _lastDoc,
        )
        .first;

    if (snapshot.docs.isNotEmpty) {
      _lastDoc = snapshot.docs.last;
      final newList = [
        ...state.value ?? [],
        ...snapshot.docs
            .where((doc) =>
                (doc.data()['availability'] as String?) != 'unavailable')
            .map((e) => UserModel.fromJson(e.data())),
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

final donorProvider =
    AsyncNotifierProvider<DonorNotifier, List<UserModel>>(DonorNotifier.new);
