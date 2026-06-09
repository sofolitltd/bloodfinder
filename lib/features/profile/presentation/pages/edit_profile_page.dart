import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../../core/utils/geohash.dart';
import '../../../../data/models/address_model.dart';
import '../../../../data/models/user_model.dart';
import '../../../../data/providers/repository_providers.dart';
import '../widgets/address_management_section.dart';
import '../widgets/avatar_picker.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _mobileNumberController = TextEditingController();

  String? _selectedGender;
  DateTime? _selectedDOB;
  List<AddressModel> _savedAddresses = [];
  String? _activeGeohash;
  String? _selectedBloodGroup;
  bool isDonor = true;
  String? _profileImageUrl;
  File? _selectedImage;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _mobileNumberController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserData() async {
    setState(() => _isLoading = true);
    try {
      final uid = ref.read(authRepositoryProvider).currentUser?.uid;
      if (uid == null) return;
      final doc = await ref.read(userRepositoryProvider).getUser(uid);
      if (!doc.exists) return;

      final data = doc.data()!;
      final user = UserModel.fromJson(data);

      setState(() {
        _firstNameController.text = user.firstName;
        _lastNameController.text = user.lastName;
        _mobileNumberController.text = user.mobileNumber;
        _selectedGender = user.gender;
        _selectedDOB =
            DateTime.tryParse(data['dateOfBirth']?.toString() ?? '');
        _selectedBloodGroup = user.bloodGroup;
        isDonor = user.isDonor;
        _profileImageUrl = user.image;
        _savedAddresses = List.from(user.savedAddresses);
        _activeGeohash = user.geohash;
      });
    } catch (e) {
      log('Error fetching user data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to load profile data'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateUser() async {
    if (!_formKey.currentState!.validate()) return;

    if (isDonor && _activeGeohash == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Please add and select a location to be visible as a donor'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final uid = ref.read(authRepositoryProvider).currentUser?.uid;
    if (uid == null) return;

    try {
      String? imageUrl = _profileImageUrl;
      if (_selectedImage != null) {
        imageUrl = await _uploadImage(_selectedImage!);
      }

      final activeAddress = _savedAddresses.isNotEmpty && _activeGeohash != null
          ? _savedAddresses.firstWhere((a) => a.geohash == _activeGeohash,
              orElse: () => _savedAddresses.first)
          : null;

      await ref.read(userRepositoryProvider).updateUser(uid, {
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'mobileNumber': _mobileNumberController.text.trim(),
        'gender': _selectedGender,
        'dateOfBirth': _selectedDOB?.toIso8601String(),
        'bloodGroup': _selectedBloodGroup,
        'isDonor': isDonor,
        'image': imageUrl,
        'latitude': activeAddress?.latitude,
        'longitude': activeAddress?.longitude,
        'geohash': activeAddress?.geohash,
        'locationAddress': activeAddress?.addressText,
        'savedAddresses': _savedAddresses.map((a) => a.toJson()).toList(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      log('Error updating user: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update profile'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<String?> _uploadImage(File image) async {
    try {
      final uid = ref.read(authRepositoryProvider).currentUser?.uid;
      if (uid == null) return null;
      return await ref
          .read(storageRepositoryProvider)
          .uploadFile(image, 'users/$uid.jpg');
    } catch (e) {
      log('Error uploading image: $e');
      return null;
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDOB ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _selectedDOB = picked);
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _selectedImage = File(image.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    final showLocationBanner =
        isDonor && _activeGeohash == null && !_isLoading;

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
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
                PhosphorIcons.user,
                color: Colors.red.shade600,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Edit Profile',
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
              if (showLocationBanner)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    border: Border.all(color: Colors.orange),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning_amber, color: Colors.orange),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'You are not visible to blood seekers.\nSet your location on the map below.',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),

              _SectionHeader(
                icon: PhosphorIcons.userCircle,
                title: 'Profile Image',
              ),
              const SizedBox(height: 12),
              _SectionCard(
                children: [
                  Center(
                    child: AvatarPicker(
                      selectedImage: _selectedImage,
                      profileImageUrl: _profileImageUrl,
                      onPickImage: _pickImage,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              _SectionHeader(
                icon: PhosphorIcons.user,
                title: 'Personal Information',
              ),
              const SizedBox(height: 12),
              _SectionCard(
                children: [
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          controller: _firstNameController,
                          decoration: const InputDecoration(
                            labelText: 'First Name',
                            prefixIcon:
                                Icon(PhosphorIcons.user, size: 20),
                          ),
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _lastNameController,
                          decoration: const InputDecoration(
                            labelText: 'Last Name',
                          ),
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Required' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: DropdownButtonFormField<String>(
                          value: _selectedGender,
                          decoration: const InputDecoration(
                            labelText: 'Gender',
                            prefixIcon:
                                Icon(PhosphorIcons.genderIntersex, size: 20),
                          ),
                          items: ['Male', 'Female']
                              .map((g) => DropdownMenuItem(
                                  value: g, child: Text(g)))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _selectedGender = v),
                          validator: (v) =>
                              v == null ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: GestureDetector(
                          onTap: _selectDate,
                          child: AbsorbPointer(
                            child: TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'Date of Birth',
                                prefixIcon: Icon(
                                    PhosphorIcons.calendarBlank, size: 20),
                              ),
                              controller: TextEditingController(
                                text: _selectedDOB == null
                                    ? ''
                                    : '${_selectedDOB!.day}/${_selectedDOB!.month}/${_selectedDOB!.year}',
                              ),
                              validator: (v) =>
                                  _selectedDOB == null ? 'Required' : null,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _mobileNumberController,
                    decoration: const InputDecoration(
                      labelText: 'Mobile Number',
                      prefixIcon:
                          Icon(PhosphorIcons.phone, size: 20),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      return null;
                    },
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
                  AddressManagementSection(
                    savedAddresses: _savedAddresses,
                    activeGeohash: _activeGeohash,
                    isDonor: isDonor,
                    onAddressesChanged: (list) =>
                        setState(() => _savedAddresses = list),
                    onActiveAddressChanged: (addr) =>
                        setState(() => _activeGeohash = addr?.geohash),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              _SectionHeader(
                icon: PhosphorIcons.drop,
                title: 'Blood Group & Donor Status',
              ),
              const SizedBox(height: 12),
              _SectionCard(
                children: [
                  DropdownButtonFormField<String>(
                    value: _selectedBloodGroup,
                    decoration: const InputDecoration(
                      labelText: 'Blood Group',
                      prefixIcon:
                          Icon(PhosphorIcons.drop, size: 20),
                    ),
                    items: ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-']
                        .map((b) =>
                            DropdownMenuItem(value: b, child: Text(b)))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _selectedBloodGroup = v),
                    validator: (v) => v == null ? 'Required' : null,
                  ),
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    title: const Text('Listed as Donor'),
                    value: isDonor,
                    controlAffinity: ListTileControlAffinity.leading,
                    onChanged: (v) => setState(() => isDonor = v!),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updateUser,
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
                            Icon(PhosphorIcons.check, size: 20),
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
        color: Theme.of(context).colorScheme.surface,
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
