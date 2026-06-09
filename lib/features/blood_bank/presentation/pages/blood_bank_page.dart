import 'dart:async';

import 'package:bloodfinder/features/blood_bank/models/blood_bank.dart';
import 'package:bloodfinder/features/blood_bank/presentation/widgets/blood_bank_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../../data/providers/repository_providers.dart';
import '../../../../data/providers/user_providers.dart';
import '../../../../shared/widgets/map_location_picker_page.dart';
import '../widgets/add_blood_bank_sheet.dart';

const _pageSize = 15;

class BloodBankPage extends ConsumerStatefulWidget {
  const BloodBankPage({super.key});

  @override
  ConsumerState<BloodBankPage> createState() => _BloodBankPageState();
}

class _BloodBankPageState extends ConsumerState<BloodBankPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<BloodBank> _nearbyBanks = [];
  DocumentSnapshot<Map<String, dynamic>>? _nearbyLastDoc;
  bool _nearbyLoading = false;
  bool _nearbyHasMore = true;
  late ScrollController _nearbyScrollCtrl;

  final List<BloodBank> _allBanks = [];
  DocumentSnapshot<Map<String, dynamic>>? _allLastDoc;
  bool _allLoading = false;
  bool _allHasMore = true;
  late ScrollController _allScrollCtrl;

  double _radiusInKm = 25.0;

  double? _latitude;
  double? _longitude;
  String? _locationAddress;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _nearbyScrollCtrl = ScrollController()..addListener(_onNearbyScroll);
    _allScrollCtrl = ScrollController()..addListener(_onAllScroll);
    _loadAllBanks();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nearbyScrollCtrl.dispose();
    _allScrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _openLocationPicker() async {
    final result = await MapLocationPickerPage.show(
      context,
      initialLatitude: _latitude,
      initialLongitude: _longitude,
    );
    if (result != null && mounted) {
      setState(() {
        _latitude = result.latitude;
        _longitude = result.longitude;
        _locationAddress = result.displayAddress;
      });
      _resetNearby();
    }
  }

  void _resetNearby() {
    _nearbyBanks.clear();
    _nearbyLastDoc = null;
    _nearbyHasMore = true;
    _loadNearbyBanks();
  }

  Future<void> _loadNearbyBanks() async {
    if (_nearbyLoading || !_nearbyHasMore || _latitude == null || _longitude == null) return;
    setState(() => _nearbyLoading = true);

    final repo = ref.read(bloodBankRepositoryProvider);
    try {
      final snap = await repo.getPaginatedNearbyBanks(
        _latitude!,
        _longitude!,
        _radiusInKm,
        _pageSize,
        startAfter: _nearbyLastDoc,
      );
      if (!mounted) return;
      setState(() {
        _nearbyHasMore = snap.docs.length >= _pageSize;
        _nearbyLastDoc =
            snap.docs.isNotEmpty ? snap.docs.last : _nearbyLastDoc;
        for (final doc in snap.docs) {
          _nearbyBanks.add(BloodBank.fromJson({
            ...doc.data(),
            'id': doc.id,
          }));
        }
        _nearbyLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _nearbyLoading = false);
    }
  }

  Future<void> _loadAllBanks() async {
    if (_allLoading || !_allHasMore) return;
    setState(() => _allLoading = true);

    final repo = ref.read(bloodBankRepositoryProvider);
    try {
      final snap = await repo.getPaginatedAllBanks(
        _pageSize,
        startAfter: _allLastDoc,
      );
      if (!mounted) return;
      setState(() {
        _allHasMore = snap.docs.length >= _pageSize;
        _allLastDoc = snap.docs.isNotEmpty ? snap.docs.last : _allLastDoc;
        for (final doc in snap.docs) {
          _allBanks.add(BloodBank.fromJson({
            ...doc.data(),
            'id': doc.id,
          }));
        }
        _allLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _allLoading = false);
    }
  }

  void _onNearbyScroll() {
    if (_nearbyScrollCtrl.position.pixels >=
        _nearbyScrollCtrl.position.maxScrollExtent - 200) {
      _loadNearbyBanks();
    }
  }

  void _onAllScroll() {
    if (_allScrollCtrl.position.pixels >=
        _allScrollCtrl.position.maxScrollExtent - 200) {
      _loadAllBanks();
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userProvider);
    final user = userAsync.value;

    if (user != null && _latitude == null && _longitude == null) {
      if (user.latitude != null && user.longitude != null) {
        _latitude = user.latitude;
        _longitude = user.longitude;
        _locationAddress = user.locationAddress;
        WidgetsBinding.instance.addPostFrameCallback((_) => _resetNearby());
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.local_hospital,
                color: Colors.red.shade600,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Blood Bank',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.red.shade700,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.red.shade700,
          tabs: const [
            Tab(text: 'Nearby Banks'),
            Tab(text: 'All Banks'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add, size: 20),
        label: const Text('Add Bank'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (_) => const AddBloodBankSheet(),
          );
        },
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildNearbyTab(),
          _buildAllTab(),
        ],
      ),
    );
  }

  Widget _buildNearbyTab() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_latitude == null || _longitude == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(PhosphorIcons.mapPinLine, size: 48, color: Colors.grey.shade300),
              const SizedBox(height: 12),
              Text(
                'Set your location to see nearby banks',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _openLocationPicker,
                icon: const Icon(Icons.location_on, size: 20),
                label: const Text('Set Location'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.transparent : Colors.grey.shade200,
              width: 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: _openLocationPicker,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? Colors.grey.shade700.withValues(alpha: 0.3) : Colors.grey.shade300,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(PhosphorIcons.mapPin, color: Colors.red.shade400, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _locationAddress ?? 'Set search location',
                            style: TextStyle(
                              color: isDark ? Colors.grey.shade300 : Colors.black87,
                              fontSize: 14,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(Icons.edit, color: Colors.grey.shade400, size: 16),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Search Radius',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                        fontSize: 14,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${_radiusInKm.round()} km',
                        style: TextStyle(
                          color: Colors.red.shade600,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _radiusInKm,
                  min: 5.0,
                  max: 200.0,
                  divisions: 39,
                  label: '${_radiusInKm.round()} km',
                  activeColor: Colors.red.shade500,
                  inactiveColor: Colors.red.shade100,
                  onChanged: (val) {
                    setState(() => _radiusInKm = val);
                  },
                  onChangeEnd: (_) => _resetNearby(),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: _nearbyBanks.isEmpty && _nearbyLoading
              ? const Center(child: CircularProgressIndicator())
              : _nearbyBanks.isEmpty && !_nearbyLoading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(PhosphorIcons.hospital, size: 48, color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          Text(
                            'No nearby blood banks found',
                            style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _nearbyScrollCtrl,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                      itemCount: _nearbyBanks.length + (_nearbyHasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= _nearbyBanks.length) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        return Padding(
                          padding: EdgeInsets.only(top: index == 0 ? 0 : 12),
                          child: BloodBankCard(bloodBank: _nearbyBanks[index]),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildAllTab() {
    if (_allBanks.isEmpty && _allLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_allBanks.isEmpty && !_allLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(PhosphorIcons.hospital, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              'No blood banks found',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      controller: _allScrollCtrl,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      itemCount: _allBanks.length + (_allHasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _allBanks.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return Padding(
          padding: EdgeInsets.only(top: index == 0 ? 0 : 12),
          child: BloodBankCard(bloodBank: _allBanks[index]),
        );
      },
    );
  }
}
