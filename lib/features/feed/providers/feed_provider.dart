import '../../blood_request/models/blood_request.dart';
import 'package:bloodfinder/data/providers/user_providers.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/providers/repository_providers.dart';

final feedPaginationProvider =
    AsyncNotifierProvider<FeedPaginationNotifier, List<BloodRequest>>(
  FeedPaginationNotifier.new,
);

class FeedPaginationNotifier extends AsyncNotifier<List<BloodRequest>> {
  String? _bloodGroup;
  double _radiusInKm = 50.0;
  bool _proximityEnabled = true;
  DocumentSnapshot<Map<String, dynamic>>? _lastDocument;
  bool _hasMore = true;
  bool _isLoading = false;

  bool get hasMore => _hasMore;
  String? get bloodGroup => _bloodGroup;
  double get radiusInKm => _radiusInKm;
  bool get proximityEnabled => _proximityEnabled;

  /// Whether any filter is active
  bool get hasActiveFilters =>
      _bloodGroup != null || _radiusInKm != 50.0 || !_proximityEnabled;

  @override
  Future<List<BloodRequest>> build() async {
    _lastDocument = null;
    _hasMore = true;
    _isLoading = false;
    return _fetchPage();
  }

  void updateFilters({
    String? bloodGroup,
    double? radiusInKm,
    bool? proximityEnabled,
  }) {
    bool changed = false;

    if (bloodGroup != _bloodGroup) {
      _bloodGroup = bloodGroup;
      changed = true;
    }
    if (radiusInKm != null && radiusInKm != _radiusInKm) {
      _radiusInKm = radiusInKm;
      changed = true;
    }
    if (proximityEnabled != null && proximityEnabled != _proximityEnabled) {
      _proximityEnabled = proximityEnabled;
      changed = true;
    }

    if (changed) refetch();
  }

  void clearFilters() {
    if (_bloodGroup == null && _radiusInKm == 50.0 && _proximityEnabled) {
      return;
    }
    _bloodGroup = null;
    _radiusInKm = 50.0;
    _proximityEnabled = true;
    refetch();
  }

  Future<void> loadNextPage() async {
    if (!_hasMore || _isLoading) return;

    _isLoading = true;

    try {
      final newItems = await _fetchPage();

      if (newItems.isNotEmpty && state.hasValue) {
        final currentList = state.requireValue;
        state = AsyncValue.data([...currentList, ...newItems]);
      }
    } catch (_) {
    } finally {
      _isLoading = false;
    }
  }

  Future<void> refetch() async {
    _lastDocument = null;
    _hasMore = true;
    _isLoading = false;

    state = const AsyncValue.loading();

    try {
      final items = await _fetchPage();
      state = AsyncValue.data(items);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<List<BloodRequest>> _fetchPage() async {
    try {
      final feedRepo = ref.read(feedRepositoryProvider);

      // Get current user's location for proximity search
      double? lat;
      double? lng;

      if (_proximityEnabled) {
        final userAsync = ref.read(userProvider);
        final user = userAsync.value;
        lat = user?.latitude;
        lng = user?.longitude;
      }

      final snapshot = await feedRepo.getRequests(
        bloodGroup: _bloodGroup,
        latitude: lat,
        longitude: lng,
        radiusInKm: (lat != null && lng != null) ? _radiusInKm : null,
        startAfter: _lastDocument,
        limit: 10,
      );

      if (snapshot.docs.isNotEmpty) {
        _lastDocument = snapshot.docs.last;
      }

      if (snapshot.docs.length < 10) {
        _hasMore = false;
      }

      final items = snapshot.docs
          .map((doc) => BloodRequest.fromFirestore(doc))
          .toList();

      return items;
    } catch (e) {
      rethrow;
    }
  }
}
