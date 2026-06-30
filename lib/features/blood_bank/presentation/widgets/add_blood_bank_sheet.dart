import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
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
    return Padding(
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
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
              ),
              Row(
                spacing: 10,
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
                  Text(
                    'Add Blood Bank',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 2.h),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Blood Bank Name',
                  prefixIcon: Icon(Icons.local_hospital, size: 20.w),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              SizedBox(height: 1.h),
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: 'Address',
                  prefixIcon: Icon(Icons.location_on, size: 20.w),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              SizedBox(height: 1.h),
              Row(
                spacing: 12,
                children: [
                  Expanded(
                    child: TextFormField(
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
                  ),
                  Expanded(
                    child: TextFormField(
                      controller: _mobile2Controller,
                      decoration: InputDecoration(
                        labelText: 'Mobile 2 (optional)',
                        prefixIcon: Icon(Icons.phone, size: 20.w),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 2.h),
              Text(
                'Social Media Links',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
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
              SizedBox(height: 2.h),
              Text(
                'Blood Bank Image',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                  fontSize: 14.sp,
                ),
              ),
              SizedBox(height: 8.h),
              ImagePickerSection(
                pickedImage: _pickedImage,
                onPickImage: _pickImage,
                onClearImage: () => setState(() => _pickedImage = null),
              ),
              SizedBox(height: 1.h),
              InkWell(
                onTap: _pickLocation,
                borderRadius: BorderRadius.circular(12.r),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: _latitude != null ? Colors.red.shade300 : Colors.grey.shade300,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        PhosphorIcons.mapPin,
                        size: 20.w,
                        color: _latitude != null ? Colors.red.shade600 : Colors.grey,
                      ),
                      SizedBox(width: 1.w),
                      Expanded(
                        child: Text(
                          _locationAddress ?? 'Pick location on map',
                          style: TextStyle(
                            color: _latitude != null ? Colors.black87 : Colors.grey.shade600,
                            fontSize: 14.sp,
                          ),
                        ),
                      ),
                      if (_latitude != null)
                        IconButton(
                          icon: Icon(Icons.close, size: 18.w),
                          onPressed: () => setState(() {
                            _latitude = null;
                            _longitude = null;
                            _locationAddress = null;
                          }),
                        ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 2.h),
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
              SizedBox(height: 2.h),
            ],
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
      setState(() {
        _latitude = result.latitude;
        _longitude = result.longitude;
        _locationAddress = result.displayAddress;
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
