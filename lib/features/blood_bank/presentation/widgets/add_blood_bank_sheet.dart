import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../../core/utils/geohash.dart';
import '../../../../data/providers/repository_providers.dart';
import '../../../../shared/models/social_media_link.dart';
import '../../../../shared/widgets/map_location_picker_page.dart';
import '../../../../shared/widgets/social_media_input.dart';
import '../../../../features/community/presentation/widgets/image_picker_section.dart';

class AddBloodBankSheet extends ConsumerStatefulWidget {
  const AddBloodBankSheet({super.key});

  @override
  ConsumerState<AddBloodBankSheet> createState() => _AddBloodBankSheetState();
}

class _AddBloodBankSheetState extends ConsumerState<AddBloodBankSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _mobile1Controller = TextEditingController();
  final _mobile2Controller = TextEditingController();
  List<SocialMediaLink> _socialMediaLinks = [];

  XFile? _pickedImage;
  double? _latitude;
  double? _longitude;
  String? _locationAddress;
  String? _country;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _mobile1Controller.dispose();
    _mobile2Controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: isDark ? null : Colors.white,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 12,
        ),
        child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  margin: EdgeInsets.only(bottom: 20.h),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 36.w,
                    height: 36.h,
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Icon(
                      PhosphorIcons.hospital,
                      color: Colors.red.shade600,
                      size: 20.w,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      'Add Blood Bank',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.grey.shade200 : Colors.grey.shade800,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, size: 20.w),
                    color: Colors.grey.shade500,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              SizedBox(height: 20.h),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Blood Bank Name',
                  prefixIcon: Icon(Icons.local_hospital, size: 20.w),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              SizedBox(height: 16.h),
              TextFormField(
                controller: _mobile1Controller,
                decoration: InputDecoration(
                  labelText: 'Mobile 1',
                  prefixIcon: Icon(Icons.phone, size: 20.w),
                ),
                keyboardType: TextInputType.phone,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Required'
                    : null,
              ),
              SizedBox(height: 12.h),
              TextFormField(
                controller: _mobile2Controller,
                decoration: InputDecoration(
                  labelText: 'Mobile 2 (optional)',
                  prefixIcon: Icon(Icons.phone, size: 20.w),
                ),
                keyboardType: TextInputType.phone,
              ),
              SizedBox(height: 20.h),
              Text(
                'Social Media Links',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
                  fontSize: 14.sp,
                ),
              ),
              SizedBox(height: 8.h),
              SocialMediaInput(
                initialLinks: _socialMediaLinks,
                onLinksChanged: (links) {
                  _socialMediaLinks = links;
                },
              ),
              SizedBox(height: 20.h),
              Text(
                'Location',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
                  fontSize: 14.sp,
                ),
              ),
              SizedBox(height: 8.h),
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: 'Address',
                  prefixIcon: Icon(Icons.location_on, size: 20.w),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              SizedBox(height: 12.h),
              GestureDetector(
                onTap: _pickLocation,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.red.shade200,
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(12.r),
                    color: Colors.red.shade50,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        PhosphorIcons.mapPin,
                        size: 20.w,
                        color: _latitude != null
                            ? Colors.red.shade600
                            : Colors.red.shade300,
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Text(
                          _latitude != null
                              ? (_locationAddress ?? 'Location selected')
                              : 'Pick location on map',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: _latitude != null
                                ? FontWeight.w500
                                : FontWeight.normal,
                            color: _latitude != null
                                ? (isDark ? Colors.grey.shade200 : Colors.grey.shade800)
                                : (isDark ? Colors.grey.shade400 : Colors.grey.shade500),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Icon(
                        _latitude != null
                            ? PhosphorIcons.pencilSimple
                            : PhosphorIcons.mapPinArea,
                        size: 18.w,
                        color: Colors.red.shade400,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20.h),
              Text(
                'Blood Bank Image',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
                  fontSize: 14.sp,
                ),
              ),
              SizedBox(height: 8.h),
              ImagePickerSection(
                pickedImage: _pickedImage,
                onPickImage: _pickImage,
                onClearImage: () => setState(() => _pickedImage = null),
              ),
              SizedBox(height: 24.h),
              SizedBox(
                height: 50.h,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _addBloodBank,
                  style: ElevatedButton.styleFrom(elevation: 0),
                  child: _isLoading
                      ? SizedBox(
                          height: 20.h,
                          width: 20.w,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          'Save Blood Bank',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              SizedBox(height: 16.h),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Future<void> _pickLocation() async {
    final result = await MapLocationPickerPage.show(
      context,
      initialLatitude: _latitude,
      initialLongitude: _longitude,
    );

    if (result != null) {
      String? country;
      try {
        final placemarks = await placemarkFromCoordinates(
          result.latitude,
          result.longitude,
        );
        country = placemarks.firstOrNull?.country;
      } catch (_) {}

      setState(() {
        _latitude = result.latitude;
        _longitude = result.longitude;
        _locationAddress = result.displayAddress;
        _country = country;
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final compressed = await _compressImage(File(pickedFile.path));
      setState(() => _pickedImage = compressed);
    }
  }

  Future<XFile?> _compressImage(File file) async {
    final compressedFile = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      '${file.parent.path}/compressed_${file.path.split('/').last}',
      quality: 70,
      minWidth: 500,
      minHeight: 500,
    );
    return compressedFile;
  }

  Future<void> _addBloodBank() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final slug = _nameController.text
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
          .replaceAll(RegExp(r'\s+'), '-')
          .trim();

      String imageUrl = '';
      if (_pickedImage != null) {
        final storageRepo = ref.read(storageRepositoryProvider);
        imageUrl = await storageRepo.uploadFile(
          File(_pickedImage!.path),
          'blood_banks/$slug.jpg',
        );
      }

      final data = {
        'name': _nameController.text.trim(),
        'slug': slug,
        'address': _addressController.text.trim(),
        'mobile1': _mobile1Controller.text.trim(),
        if (_mobile2Controller.text.trim().isNotEmpty)
          'mobile2': _mobile2Controller.text.trim(),
        if (_socialMediaLinks.any((l) => l.url.trim().isNotEmpty))
          'socialMediaLinks':
              _socialMediaLinks.map((l) => l.toJson()).toList(),
        if (imageUrl.isNotEmpty) 'imageUrl': imageUrl,
        if (_latitude != null) 'latitude': _latitude,
        if (_longitude != null) 'longitude': _longitude,
        if (_latitude != null && _longitude != null)
          'geohash': Geohash.encode(_latitude!, _longitude!),
        if (_locationAddress != null) 'locationAddress': _locationAddress,
        if (_country != null) 'country': _country,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await ref.read(bloodBankRepositoryProvider).addBank(data);

      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Blood bank added')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
