import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../../data/models/address_model.dart';
import '../../../../data/providers/repository_providers.dart';
import '../widgets/address_management_section.dart';

class AddressManagementPage extends ConsumerStatefulWidget {
  const AddressManagementPage({super.key});

  @override
  ConsumerState<AddressManagementPage> createState() =>
      _AddressManagementPageState();
}

class _AddressManagementPageState
    extends ConsumerState<AddressManagementPage> {
  List<AddressModel> _savedAddresses = [];
  String? _activeGeohash;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    setState(() => _isLoading = true);
    try {
      final uid = ref.read(authRepositoryProvider).currentUser?.uid;
      if (uid == null) return;
      final doc = await ref.read(userRepositoryProvider).getUser(uid);
      if (!doc.exists) return;

      final data = doc.data()!;
      setState(() {
        _savedAddresses = (data['savedAddresses'] as List<dynamic>?)
                ?.map((e) =>
                    AddressModel.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [];
        _activeGeohash = data['geohash'] as String?;
      });
    } catch (e) {
      log('Error fetching addresses: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveAddresses() async {
    final uid = ref.read(authRepositoryProvider).currentUser?.uid;
    if (uid == null) return;

    final activeAddress = _savedAddresses.isNotEmpty && _activeGeohash != null
        ? _savedAddresses.firstWhere((a) => a.geohash == _activeGeohash,
            orElse: () => _savedAddresses.first)
        : _savedAddresses.isNotEmpty
            ? _savedAddresses.first
            : null;

    await ref.read(userRepositoryProvider).updateUser(uid, {
      'latitude': activeAddress?.latitude,
      'longitude': activeAddress?.longitude,
      'geohash': activeAddress?.geohash,
      'locationAddress': activeAddress?.addressText,
      'savedAddresses': _savedAddresses.map((a) => a.toJson()).toList(),
    });

    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32.w,
              height: 32.h,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(
                PhosphorIcons.mapPin,
                color: Colors.red.shade600,
                size: 18.w,
              ),
            ),
            SizedBox(width: 8.w),
            const Text(
              'Manage Addresses',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 32.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AddressManagementSection(
                    savedAddresses: _savedAddresses,
                    activeGeohash: _activeGeohash,
                    isDonor: true,
                    onAddressesChanged: (list) =>
                        setState(() => _savedAddresses = list),
                    onActiveAddressChanged: (addr) =>
                        setState(() => _activeGeohash = addr?.geohash),
                  ),
                  SizedBox(height: 24.h),
                  SizedBox(
                    width: double.infinity,
                    height: 52.h,
                    child: ElevatedButton(
                      onPressed: _saveAddresses,
                      style: ElevatedButton.styleFrom(elevation: 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(PhosphorIcons.check, size: 20.w),
                          SizedBox(width: 8.w),
                          Text(
                            'Save Changes',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
