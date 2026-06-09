import 'dart:developer';

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_image_compress/flutter_image_compress.dart';

import 'package:image_picker/image_picker.dart';


import '../../../../data/providers/repository_providers.dart';
import '../../../../shared/models/social_media_link.dart';
import '../../../../shared/widgets/map_location_picker_page.dart';
import '../../../../shared/widgets/social_media_input.dart';

import '../../models/community.dart';

import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

class EditCommunity extends ConsumerStatefulWidget {
  final Community community;

  const EditCommunity({super.key, required this.community});

  @override
  ConsumerState<EditCommunity> createState() => _EditCommunityState();
}

class _EditCommunityState extends ConsumerState<EditCommunity> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  List<SocialMediaLink> _socialMediaLinks = [];

  XFile? _pickedImage;
  bool _isLoading = false;
  String? _existingImageUrl;

  double? _selectedLatitude;
  double? _selectedLongitude;
  String? _selectedLocationAddress;

  @override
  void initState() {
    super.initState();
    final c = widget.community;
    _nameController.text = c.name;
    _mobileController.text = c.mobile;
    _addressController.text = c.address;
    _socialMediaLinks = c.socialMediaLinks ?? [];
    _selectedLatitude = c.latitude;
    _selectedLongitude = c.longitude;
    _selectedLocationAddress = c.locationAddress;
    _existingImageUrl = c.images.isNotEmpty ? c.images.first : null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasLocation = _selectedLatitude != null;

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
                PhosphorIcons.usersFour,
                color: Colors.red.shade600,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Edit Community',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionHeader(
                icon: PhosphorIcons.usersFour,
                title: 'Community Information',
              ),
              const SizedBox(height: 12),
              _SectionCard(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Community Name',
                      hintText: 'Enter community name',
                      prefixIcon: Icon(PhosphorIcons.usersFour, size: 20),
                    ),
                    keyboardType: TextInputType.name,
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Enter a name' : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _mobileController,
                    decoration: const InputDecoration(
                      labelText: 'Admin Mobile',
                      hintText: 'Enter mobile number',
                      prefixIcon: Icon(PhosphorIcons.phone, size: 20),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Enter mobile number' : null,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              _SectionHeader(
                icon: PhosphorIcons.mapPin,
                title: 'Location',
              ),
              const SizedBox(height: 12),
              _SectionCard(
                children: [
                  TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                      labelText: 'Address',
                      hintText: 'Enter community address',
                      prefixIcon: Icon(PhosphorIcons.mapPin, size: 20),
                    ),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Enter address' : null,
                  ),
                  const SizedBox(height: 14),
                  GestureDetector(
                    onTap: () async {
                      final result = await MapLocationPickerPage.show(context);
                      if (result != null) {
                        setState(() {
                          _selectedLatitude = result.latitude;
                          _selectedLongitude = result.longitude;
                          _selectedLocationAddress = result.displayAddress;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.red.shade200, width: 1),
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.red.shade50,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            PhosphorIcons.mapPin,
                            size: 20,
                            color: hasLocation
                                ? Colors.red.shade600
                                : Colors.red.shade300,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  hasLocation
                                      ? 'Location Picked'
                                      : 'Pick Community Location',
                                  style: TextStyle(
                                    fontSize: 14,
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
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(
                                      _selectedLocationAddress!,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            hasLocation
                                ? PhosphorIcons.pencilSimple
                                : PhosphorIcons.mapPinArea,
                            size: 18,
                            color: Colors.red.shade400,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              _SectionHeader(
                icon: PhosphorIcons.shareNetwork,
                title: 'Social Media Links',
              ),
              const SizedBox(height: 12),
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

              const SizedBox(height: 24),

              _SectionHeader(
                icon: PhosphorIcons.image,
                title: 'Community Image',
              ),
              const SizedBox(height: 12),
              _SectionCard(
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          height: 140,
                          width: 140,
                          decoration: BoxDecoration(
                            color: Colors.red.shade50.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: _pickedImage != null
                              ? Image.file(
                                  File(_pickedImage!.path),
                                  fit: BoxFit.cover,
                                )
                              : _existingImageUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    _existingImageUrl!,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Icon(
                                  PhosphorIcons.image,
                                  size: 50,
                                  color: Colors.red.shade100,
                                ),
                        ),
                        if (_pickedImage != null || _existingImageUrl != null)
                          Positioned(
                            top: -8,
                            right: -8,
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _pickedImage = null;
                                  _existingImageUrl = null;
                                });
                              },
                              child: CircleAvatar(
                                radius: 12,
                                backgroundColor: Colors.red,
                                child: Icon(PhosphorIcons.x, size: 14, color: Colors.white),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updateCommunity,
                  style: ElevatedButton.styleFrom(elevation: 0),
                  child: _isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(PhosphorIcons.usersFour, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Save Changes',
                              style: TextStyle(
                                fontSize: 16,
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
      ),
    );
  }

  Future<void> _updateCommunity() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      String imageUrl = _existingImageUrl ?? '';
      if (_pickedImage != null) {
        final storageRepo = ref.read(storageRepositoryProvider);
        imageUrl = await storageRepo.uploadFile(
          File(_pickedImage!.path),
          'communities/${widget.community.id}.jpg',
        );
      }

      final updatedData = {
        'name': _nameController.text.trim(),
        'mobile': _mobileController.text.trim(),
        'address': _addressController.text.trim(),
        if (_selectedLatitude != null) 'latitude': _selectedLatitude,
        if (_selectedLongitude != null) 'longitude': _selectedLongitude,
        if (_selectedLocationAddress != null)
          'locationAddress': _selectedLocationAddress,
        if (_socialMediaLinks.isNotEmpty)
          'socialMediaLinks':
              _socialMediaLinks.map((l) => l.toJson()).toList(),
        'images': imageUrl == "" ? [] : [imageUrl],
        'updatedAt': Timestamp.now(),
      };

      final communityRepo = ref.read(communityRepositoryProvider);
      await communityRepo.updateCommunity(widget.community.id, updatedData);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Community updated successfully!'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      log('Error updating: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: Text('Error updating: $e'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final compressed = await _compressImage(File(picked.path));
      setState(() => _pickedImage = compressed);
    }
  }

  Future<XFile?> _compressImage(File file) async {
    final ext = file.path.split('.').last.toLowerCase();

    final isPng = ext == 'png';
    final format = isPng ? CompressFormat.png : CompressFormat.jpeg;

    final newExt = isPng ? 'png' : 'jpg';
    final targetPath =
        '${file.parent.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.$newExt';

    final result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: 70,
      minWidth: 500,
      minHeight: 500,
      format: format,
    );

    return result != null ? XFile(result.path) : null;
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
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 15, color: Colors.red.shade600),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 15,
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
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}
