import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geocoding/geocoding.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/utils/geohash.dart';
import '../../../../data/models/address_model.dart';
import '../../../../data/providers/repository_providers.dart';
import '../../../../shared/widgets/map_location_picker_page.dart';

class LocationOnboardingPage extends ConsumerStatefulWidget {
  const LocationOnboardingPage({super.key});

  @override
  ConsumerState<LocationOnboardingPage> createState() =>
      _LocationOnboardingPageState();
}

class _LocationOnboardingPageState
    extends ConsumerState<LocationOnboardingPage> {
  List<AddressModel> _savedAddresses = [];
  bool _isSaving = false;

  Future<void> _addAddress() async {
    final result = await MapLocationPickerPage.show(context);
    if (result == null || !mounted) return;

    final labelController = TextEditingController();
    final String? label = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Address Label'),
        content: TextField(
          controller: labelController,
          decoration: const InputDecoration(
            hintText: 'e.g., Home, Office, University',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (labelController.text.trim().isNotEmpty) {
                Navigator.pop(ctx, labelController.text.trim());
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (label != null && label.isNotEmpty && mounted) {
      final newAddress = AddressModel(
        id: const Uuid().v4(),
        label: label,
        latitude: result.latitude,
        longitude: result.longitude,
        geohash: Geohash.encode(result.latitude, result.longitude),
        addressText: result.displayAddress,
      );

      setState(() {
        _savedAddresses = List.from(_savedAddresses)..add(newAddress);
      });
    }
  }

  Future<void> _removeAddress(AddressModel address) async {
    if (_savedAddresses.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must save at least one address.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _savedAddresses = List.from(_savedAddresses)
        ..removeWhere((a) => a.id == address.id);
    });
  }

  Future<void> _saveAndContinue() async {
    if (_savedAddresses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one location address.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final uid =
          ref.read(authRepositoryProvider).currentUser?.uid;
      if (uid == null) return;

      final activeAddress = _savedAddresses.first;

      // Reverse geocode for country
      String? country;
      try {
        final placemarks = await placemarkFromCoordinates(
          activeAddress.latitude,
          activeAddress.longitude,
        );
        country = placemarks.firstOrNull?.country;
      } catch (_) {}

      await ref.read(userRepositoryProvider).updateUser(uid, {
        'latitude': activeAddress.latitude,
        'longitude': activeAddress.longitude,
        'geohash': activeAddress.geohash,
        'locationAddress': activeAddress.addressText,
        'country': country,
        'savedAddresses':
            _savedAddresses.map((a) => a.toJson()).toList(),
      });

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Up Your Location'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 32.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero icon area
            Center(
              child: Container(
                width: 80.w,
                height: 80.h,
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  PhosphorIcons.mapPin,
                  size: 40.w,
                  color: Colors.red.shade600,
                ),
              ),
            ),
            SizedBox(height: 16.h),

            // Title
            Center(
              child: Text(
                'Update Your Location',
                style: TextStyle(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 8.h),
            Center(
              child: Text(
                'We need your location to connect you with nearby\nblood seekers and donors in your area.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              ),
            ),
            SizedBox(height: 32.h),

            // Saved addresses list
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Your Addresses',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: _addAddress,
                  icon: Icon(Icons.add_location_alt, size: 18.w),
                  label: const Text('Add'),
                ),
              ],
            ),
            SizedBox(height: 8.h),

            if (_savedAddresses.isEmpty)
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 40.h),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Column(
                  children: [
                    Icon(
                      PhosphorIcons.mapPinLine,
                      size: 40.w,
                      color: Colors.grey.shade400,
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      'No addresses added yet',
                      style: TextStyle(
                        fontSize: 15.sp,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'Tap "Add" to set up your first location',
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _savedAddresses.length,
                separatorBuilder: (_, _) => Divider(height: 8.h),
                itemBuilder: (context, index) {
                  final address = _savedAddresses[index];
                  final isFirst = index == 0;

                  return Container(
                    decoration: BoxDecoration(
                      color: isFirst
                          ? Colors.green.shade50
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8.r),
                      border: isFirst
                          ? Border.all(color: Colors.green.shade200)
                          : null,
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.only(
                        left: 12.w,
                        right: 4.w,
                        top: 4.h,
                        bottom: 4.h,
                      ),
                      leading: Container(
                        width: 36.w,
                        height: 36.h,
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Icon(
                          PhosphorIcons.mapPin,
                          color: Colors.red.shade600,
                          size: 18.w,
                        ),
                      ),
                      title: Row(
                        children: [
                          Text(
                            address.label,
                            style:
                                TextStyle(fontWeight: FontWeight.w600),
                          ),
                          if (isFirst)
                            Container(
                              margin: EdgeInsets.only(left: 8.w),
                              padding: EdgeInsets.symmetric(
                                  horizontal: 6.w, vertical: 2.h),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius:
                                    BorderRadius.circular(4.r),
                                border: Border.all(
                                    color: Colors.green.shade200),
                              ),
                              child: Text(
                                'Active',
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  color: Colors.green,
                                ),
                              ),
                            ),
                        ],
                      ),
                      subtitle: Text(
                        address.addressText,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12.sp),
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.delete_outline,
                            color: Colors.redAccent, size: 20.w),
                        onPressed: () => _removeAddress(address),
                      ),
                    ),
                  );
                },
              ),

            SizedBox(height: 32.h),

            SizedBox(
              width: double.infinity,
              height: 52.h,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveAndContinue,
                icon: _isSaving
                    ? SizedBox(
                        width: 20.w,
                        height: 20.h,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_circle_outline),
                label: Text(
                  _isSaving ? 'Saving...' : 'Save & Continue',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
