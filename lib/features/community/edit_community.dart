import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';

import '/data/db/app_data.dart';
import '/data/models/community.dart';
import '/features/community/search_page.dart';

class EditCommunity extends StatefulWidget {
  final Community community;

  const EditCommunity({super.key, required this.community});

  @override
  State<EditCommunity> createState() => _EditCommunityState();
}

class _EditCommunityState extends State<EditCommunity> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _facebookController = TextEditingController();
  final TextEditingController _whatsappController = TextEditingController();

  String? _selectedDistrict;
  String? _selectedSubDistrict;
  XFile? _pickedImage;
  bool _isLoading = false;
  String? _existingImageUrl;

  @override
  void initState() {
    super.initState();
    final c = widget.community;
    _nameController.text = c.name;
    _mobileController.text = c.mobile;
    _addressController.text = c.address;
    _facebookController.text = c.facebook ?? '';
    _whatsappController.text = c.whatsapp ?? '';
    _selectedDistrict = c.district;
    _selectedSubDistrict = c.subDistrict;
    _existingImageUrl = c.images.isNotEmpty ? c.images.first : null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _addressController.dispose();
    _facebookController.dispose();
    _whatsappController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Community'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Community name',
                  hintText: 'Enter community name',
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Enter a name' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _mobileController,
                decoration: const InputDecoration(
                  labelText: 'Admin Mobile',
                  hintText: 'Enter mobile number',
                ),
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) =>
                    v == null || v.isEmpty ? 'Enter mobile number' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  hintText: 'Enter address',
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Enter address' : null,
              ),
              const SizedBox(height: 16),

              _buildDistrictDropdown(),
              const SizedBox(height: 16),
              _buildSubDistrictDropdown(),
              const SizedBox(height: 16),

              TextFormField(
                controller: _facebookController,
                decoration: const InputDecoration(
                  labelText: 'Facebook Link (Optional)',
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _whatsappController,
                decoration: const InputDecoration(
                  labelText: 'WhatsApp Link (Optional)',
                ),
              ),
              const SizedBox(height: 24),

              Text(
                'Community Image',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),

              GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      height: 140,
                      width: 140,
                      color: Colors.red.shade50.withValues(alpha: 0.4),
                      child: _pickedImage != null
                          ? Image.file(
                              File(_pickedImage!.path),
                              fit: BoxFit.cover,
                            )
                          : _existingImageUrl != null
                          ? Image.network(_existingImageUrl!, fit: BoxFit.cover)
                          : Icon(
                              Icons.image,
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
                          child: const CircleAvatar(
                            radius: 12,
                            child: Icon(Icons.close, size: 14),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: _isLoading ? null : _updateCommunity,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'Save Changes',
                        style: TextStyle(color: Colors.white),
                      ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _updateCommunity() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDistrict == null || _selectedSubDistrict == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select District and Subdistrict')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      String imageUrl = _existingImageUrl ?? '';
      if (_pickedImage != null) {
        imageUrl = await _uploadImage(File(_pickedImage!.path));
      }

      final updatedData = {
        'name': _nameController.text.trim(),
        'mobile': _mobileController.text.trim(),
        'address': _addressController.text.trim(),
        'district': _selectedDistrict,
        'subDistrict': _selectedSubDistrict,
        'facebook': _facebookController.text.trim(),
        'whatsapp': _whatsappController.text.trim(),
        'images': imageUrl == "" ? [] : [imageUrl],
        'updatedAt': Timestamp.now(),
      };

      await FirebaseFirestore.instance
          .collection('communities')
          .doc(widget.community.id)
          .update(updatedData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Community updated successfully!')),
      );

      Navigator.pop(context, true);
    } catch (e) {
      log('Error updating: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error updating: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Image handling
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final compressed = await _compressImage(File(picked.path));
      setState(() => _pickedImage = compressed);
    }
  }

  Future<XFile?> _compressImage(File file) async {
    // Get extension (e.g. jpg, png, jpeg)
    final ext = file.path.split('.').last.toLowerCase();

    // Determine format and extension
    final isPng = ext == 'png';
    final format = isPng ? CompressFormat.png : CompressFormat.jpeg;

    // Ensure proper output path
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

  Future<String> _uploadImage(File file) async {
    final ref = FirebaseStorage.instance.ref().child(
      'communities/${widget.community.id}.jpg',
    );
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  // Dropdowns
  Widget _buildDistrictDropdown() {
    return TextFormField(
      readOnly: true,
      decoration: InputDecoration(
        hintText: _selectedDistrict ?? 'Select District',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        suffixIcon: _selectedDistrict != null
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(
                  () => _selectedDistrict = _selectedSubDistrict = null,
                ),
              )
            : const Icon(Icons.arrow_drop_down),
      ),
      onTap: () async {
        final selected = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SearchPage(
              title: 'District',
              items: (AppData.districts.map((e) => e.name).toList()..sort()),
            ),
          ),
        );
        if (selected != null) {
          setState(() {
            _selectedDistrict = selected;
            _selectedSubDistrict = null;
          });
        }
      },
    );
  }

  Widget _buildSubDistrictDropdown() {
    final subDistricts = _selectedDistrict != null
        ? AppData.districts
              .firstWhere((d) => d.name == _selectedDistrict)
              .subDistricts
        : <String>[];

    return TextFormField(
      readOnly: true,
      enabled: _selectedDistrict != null,
      decoration: InputDecoration(
        hintText: _selectedSubDistrict ?? 'Select Subdistrict',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        suffixIcon: _selectedSubDistrict != null
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() => _selectedSubDistrict = null),
              )
            : const Icon(Icons.arrow_drop_down),
      ),
      onTap: () async {
        if (_selectedDistrict == null) return;
        final selected = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                SearchPage(title: 'Subdistrict', items: subDistricts),
          ),
        );
        if (selected != null) setState(() => _selectedSubDistrict = selected);
      },
    );
  }
}
