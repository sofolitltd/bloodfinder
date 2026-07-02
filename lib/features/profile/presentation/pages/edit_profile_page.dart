import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../../core/utils/phone_utils.dart';
import '../../../../data/models/address_model.dart';
import '../../../../data/models/user_model.dart';
import '../../../../data/providers/repository_providers.dart';
import '../widgets/address_management_section.dart';
import '../widgets/avatar_picker.dart';
import '../widgets/section_card.dart';

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
          SnackBar(
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
        SnackBar(
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

      // Reverse geocode active address for country
      String? country;
      if (activeAddress != null) {
        try {
          final placemarks = await placemarkFromCoordinates(
            activeAddress.latitude,
            activeAddress.longitude,
          );
          country = placemarks.firstOrNull?.country;
        } catch (_) {}
      }

      await ref.read(userRepositoryProvider).updateUser(uid, {
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'mobileNumber': PhoneUtils.toCanonical(_mobileNumberController.text.trim()),
        'gender': _selectedGender,
        'dateOfBirth': _selectedDOB?.toIso8601String(),
        'bloodGroup': _selectedBloodGroup,
        'isDonor': isDonor,
        'image': imageUrl,
        'latitude': activeAddress?.latitude,
        'longitude': activeAddress?.longitude,
        'geohash': activeAddress?.geohash,
        'locationAddress': activeAddress?.addressText,
        'country': country,
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
          SnackBar(
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
              width: 32.w,
              height: 32.h,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(
                PhosphorIcons.user,
                color: Colors.red.shade600,
                size: 18.w,
              ),
            ),
            SizedBox(width: 8.w),
            const Text(
              'Edit Profile',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 32.h),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showLocationBanner)
                Container(
                  width: double.infinity,
                  margin: EdgeInsets.only(bottom: 16.h),
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    border: Border.all(color: Colors.orange),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber, color: Colors.orange),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'You are not visible to blood seekers.\nSet your location on the map below.',
                          style: TextStyle(fontSize: 13.sp),
                        ),
                      ),
                    ],
                  ),
                ),

              // Section 1: Profile Information
              _SectionHeader(
                icon: PhosphorIcons.user,
                title: 'Profile Information',
              ),
              SizedBox(height: 12.h),
              SectionCard(
                children: [
                  AvatarPicker(
                    selectedImage: _selectedImage,
                    profileImageUrl: _profileImageUrl,
                    onPickImage: _pickImage,
                  ),
                  SizedBox(height: 14.h),
                  TextFormField(
                    controller: _firstNameController,
                    decoration: InputDecoration(
                      labelText: 'First Name',
                      prefixIcon:
                          Icon(PhosphorIcons.user, size: 20.w),
                    ),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Required' : null,
                  ),
                  SizedBox(height: 14.h),
                  TextFormField(
                    controller: _lastNameController,
                    decoration: InputDecoration(
                      labelText: 'Last Name',
                      prefixIcon:
                          Icon(PhosphorIcons.user, size: 20.w),
                    ),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Required' : null,
                  ),
                  SizedBox(height: 14.h),
                  TextFormField(
                    controller: _mobileNumberController,
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      prefixIcon:
                          Icon(PhosphorIcons.phone, size: 20.w),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      return null;
                    },
                  ),
                ],
              ),

              SizedBox(height: 24.h),

              // Section 2: Medical Info
              _SectionHeader(
                icon: PhosphorIcons.heart,
                title: 'Medical Info',
              ),
              SizedBox(height: 12.h),
              SectionCard(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedBloodGroup,
                          decoration: InputDecoration(
                            labelText: 'Blood Group',
                            prefixIcon:
                                Icon(PhosphorIcons.drop, size: 20.w),
                          ),
                          items: [
                            'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'
                          ]
                              .map((b) => DropdownMenuItem(
                                  value: b, child: Text(b)))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _selectedBloodGroup = v),
                          validator: (v) => v == null ? 'Required' : null,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedGender,
                          decoration: InputDecoration(
                            labelText: 'Gender',
                            prefixIcon: Icon(
                                PhosphorIcons.genderIntersex, size: 20.w),
                          ),
                          items: ['Male', 'Female']
                              .map((g) => DropdownMenuItem(
                                  value: g, child: Text(g)))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _selectedGender = v),
                          validator: (v) => v == null ? 'Required' : null,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 14.h),
                  GestureDetector(
                    onTap: _selectDate,
                    child: AbsorbPointer(
                      child: TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Date of Birth',
                          prefixIcon: Icon(
                              PhosphorIcons.calendarBlank, size: 20.w),
                        ),
                        controller: TextEditingController(
                          text: _selectedDOB == null
                              ? ''
                              : '${_selectedDOB!.day}/${_selectedDOB!.month}/${_selectedDOB!.year}',
                        ),
                        validator: (_) =>
                            _selectedDOB == null ? 'Required' : null,
                      ),
                    ),
                  ),
                  SizedBox(height: 14.h),
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 16.w, vertical: 12.h),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(
                        color: isDonor
                            ? Colors.red.shade200
                            : Colors.grey.shade200,
                      ),
                      color: isDonor
                          ? Colors.red.shade50
                          : Colors.grey.shade50,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Listed as a donor',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15.sp,
                                  color: isDonor
                                      ? Colors.red.shade800
                                      : Colors.grey.shade700,
                                ),
                              ),
                              Text(
                                isDonor
                                    ? "You're ready to save lives"
                                    : 'Enable to be visible to blood seekers',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: isDonor
                                      ? Colors.red.shade400
                                      : Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: isDonor,
                          onChanged: (v) =>
                              setState(() => isDonor = v),
                          activeTrackColor: Colors.red.shade200,
                          activeThumbColor: Colors.red.shade500,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: 24.h),

              // Section 3: Location
              _SectionHeader(
                icon: PhosphorIcons.mapPin,
                title: 'Location',
              ),
              SizedBox(height: 12.h),
              SectionCard(
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

              SizedBox(height: 24.h),

              SizedBox(
                width: double.infinity,
                height: 52.h,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updateUser,
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

