import 'dart:developer';
import '../../../../core/utils/geohash.dart';
import '../../../../core/utils/phone_utils.dart';

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';

import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';


import '../../../../data/providers/repository_providers.dart';
import '../../../../shared/models/social_media_link.dart';
import '../../../../shared/widgets/map_location_picker_page.dart';
import '../../../../shared/widgets/social_media_input.dart';

import '../../models/community.dart';

import 'image_picker_section.dart';

class CommunityForm extends ConsumerStatefulWidget {
  final VoidCallback onCommunityCreated;

  const CommunityForm({super.key, required this.onCommunityCreated});

  @override
  ConsumerState<CommunityForm> createState() => _CommunityFormState();
}

class _CommunityFormState extends ConsumerState<CommunityForm> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  List<SocialMediaLink> _socialMediaLinks = [];

  double? _selectedLatitude;
  double? _selectedLongitude;
  String? _selectedLocationAddress;
  XFile? _pickedImage;

  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final compressed = await _compressImage(File(pickedFile.path));
      setState(() {
        _pickedImage = compressed;
      });
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

  Future<String> _generateCommunityCode() async {
    final firestore = ref.read(firebaseDataSourceProvider).firestore;
    final counterRef = firestore.collection('settings').doc('communityCounter');

    return firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(counterRef);

      int current = 0;
      if (snapshot.exists && snapshot.data()?['count'] is int) {
        current = snapshot['count'];
      }

      int next = current + 1;
      transaction.set(counterRef, {'count': next}, SetOptions(merge: true));
      return '$next';
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasLocation = _selectedLatitude != null;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Community Info section
          _SectionHeader(
            icon: PhosphorIcons.usersFour,
            title: 'Community Information',
          ),
          SizedBox(height: 8.h),
          _SectionCard(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Community Name',
                  hintText: 'Enter community name',
                  prefixIcon: Icon(PhosphorIcons.usersFour, size: 20.w),
                ),
                keyboardType: TextInputType.name,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a community name';
                  }
                  return null;
                },
              ),
              SizedBox(height: 8.h),
              TextFormField(
                controller: _mobileController,
                decoration: InputDecoration(
                  labelText: 'Admin Mobile',
                  hintText: 'Enter mobile number',
                  prefixIcon: Icon(PhosphorIcons.phone, size: 20.w),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a mobile number';
                  }
                  return null;
                },
              ),
            ],
          ),

          SizedBox(height: 2.h),

          // Location section
          _SectionHeader(
            icon: PhosphorIcons.mapPin,
            title: 'Location',
          ),
          SizedBox(height: 8.h),
          _SectionCard(
            children: [
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: 'Address',
                  hintText: 'Enter community address',
                  prefixIcon: Icon(PhosphorIcons.mapPin, size: 20.w),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the address';
                  }
                  return null;
                },
              ),
              SizedBox(height: 8.h),
              FormField<double>(
                validator: (_) =>
                    _selectedLatitude == null ? 'Please pick a location' : null,
                builder: (state) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () async {
                          final result = await MapLocationPickerPage.show(
                            context,
                          );
                          if (result != null) {
                            setState(() {
                              _selectedLatitude = result.latitude;
                              _selectedLongitude = result.longitude;
                              _selectedLocationAddress =
                                  result.displayAddress;
                            });
                            state.didChange(result.latitude);
                          }
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 14.w, vertical: 14.h),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: state.hasError
                                  ? Theme.of(context).colorScheme.error
                                  : Colors.red.shade200,
                              width: state.hasError ? 1.5 : 1,
                            ),
                            borderRadius: BorderRadius.circular(12.r),
                            color: Colors.red.shade50,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                PhosphorIcons.mapPin,
                                size: 20.w,
                                color: hasLocation
                                    ? Colors.red.shade600
                                    : Colors.red.shade300,
                              ),
                              SizedBox(width: 8.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      hasLocation
                                          ? 'Location Picked'
                                          : 'Pick Community Location',
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        fontWeight: hasLocation
                                            ? FontWeight.w500
                                            : FontWeight.normal,
                                        color: hasLocation
                                            ? Colors.grey.shade800
                                            : Colors.grey.shade500,
                                      ),
                                    ),
                                    if (_selectedLocationAddress != null &&
                                        _selectedLocationAddress!.isNotEmpty)
                                      Padding(
                                        padding:
                                            EdgeInsets.only(top: 2.h),
                                        child: Text(
                                          _selectedLocationAddress!,
                                          style: TextStyle(
                                            fontSize: 12.sp,
                                            color: Colors.grey.shade500,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Icon(
                                hasLocation
                                    ? PhosphorIcons.pencilSimple
                                    : PhosphorIcons.mapPinArea,
                                size: 18.w,
                                color: Colors.red.shade400,
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (state.hasError)
                        Padding(
                          padding: EdgeInsets.only(top: 6.h, left: 12.w),
                          child: Text(
                            state.errorText!,
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),

          SizedBox(height: 2.h),

          // Social Media section
          _SectionHeader(
            icon: PhosphorIcons.shareNetwork,
            title: 'Social Media Links',
          ),
          SizedBox(height: 8.h),
          _SectionCard(
            children: [
              SocialMediaInput(
                initialLinks: _socialMediaLinks,
                onLinksChanged: (links) {
                  setState(() => _socialMediaLinks = links);
                },
              ),
            ],
          ),

          SizedBox(height: 2.h),

          // Community Image section
          _SectionHeader(
            icon: PhosphorIcons.image,
            title: 'Community Image',
          ),
          SizedBox(height: 8.h),
          _SectionCard(
            children: [
              ImagePickerSection(
                pickedImage: _pickedImage,
                onPickImage: _pickImage,
                onClearImage: () {
                  setState(() {
                    _pickedImage = null;
                  });
                },
              ),
            ],
          ),

          SizedBox(height: 3.h),

          SizedBox(
            width: double.infinity,
            height: 52.h,
            child: ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : () async {
                      if (_formKey.currentState!.validate()) {
                        if (_selectedLatitude == null ||
                            _selectedLongitude == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text(
                                'Please pick a location from the map',
                              ),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                            ),
                          );
                          return;
                        }

                        setState(() => _isLoading = true);

                        try {
                          final uid = ref
                              .read(authRepositoryProvider)
                              .currentUser!
                              .uid;

                          final userRepo =
                              ref.read(userRepositoryProvider);
                          final userDoc =
                              await userRepo.getUser(uid);
                          final adminBloodGroup =
                              userDoc.data()?['bloodGroup'] as String?;

                          final dataSource =
                              ref.read(firebaseDataSourceProvider);
                          final docRef = dataSource
                              .collection('communities')
                              .doc();

                          final generatedId = docRef.id;

                          String imageUrl = '';

                          if (_pickedImage != null) {
                            final storageRepo =
                                ref.read(storageRepositoryProvider);
                            imageUrl = await storageRepo.uploadFile(
                              File(_pickedImage!.path),
                              'communities/$generatedId.jpg',
                            );
                          }

                          var communityCode =
                              await _generateCommunityCode();

                          Community newCommunity = Community(
                            id: generatedId.toString(),
                            code: communityCode.toString(),
                            name: _nameController.text.trim(),
                            mobile: PhoneUtils.toCanonical(_mobileController.text.trim()),
                            address: _addressController.text.trim(),
                            latitude: _selectedLatitude,
                            longitude: _selectedLongitude,
                            locationAddress: _selectedLocationAddress,
                            geohash: _selectedLatitude != null &&
                                    _selectedLongitude != null
                                ? Geohash.encode(_selectedLatitude!,
                                    _selectedLongitude!)
                                : null,
                            admin: [uid],
                            images: imageUrl == "" ? [] : [imageUrl],
                            createdAt: Timestamp.now(),
                            memberCount: 1,
                            bloodGroupCounts: adminBloodGroup != null
                                ? {adminBloodGroup: 1}
                                : null,
                            socialMediaLinks:
                                _socialMediaLinks.isNotEmpty
                                    ? _socialMediaLinks
                                    : null,
                          );

                          await docRef.set(newCommunity.toJson());

                          final communityRepo =
                              ref.read(communityRepositoryProvider);
                          await communityRepo.addMember(
                            generatedId,
                            uid,
                            {
                              'uid': uid,
                              'member': true,
                              'createdAt': Timestamp.now(),
                            },
                          );

                          await dataSource
                              .subscribeToTopic(generatedId);

                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text(
                                'Community created successfully!',
                              ),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(12.r),
                              ),
                            ),
                          );
                          widget.onCommunityCreated();
                        } catch (e) {
                          log('Error creating community: $e');
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Failed to create community: $e',
                              ),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(12.r),
                              ),
                            ),
                          );
                        } finally {
                          if (mounted) {
                            setState(() => _isLoading = false);
                          }
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(elevation: 0),
              child: _isLoading
                  ? SizedBox(
                      height: 22.h,
                      width: 22.w,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(PhosphorIcons.usersFour, size: 20.w),
                        SizedBox(width: 8.w),
                        Text(
                          'Create Community',
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
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28.w,
          height: 28.h,
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(icon, size: 15.w, color: Colors.red.shade600),
        ),
        SizedBox(width: 8.w),
        Text(
          title,
          style: TextStyle(
            fontSize: 15.sp,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final List<Widget> children;

  const _SectionCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}
