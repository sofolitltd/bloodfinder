import 'dart:developer';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:uuid/uuid.dart';

import '../../../../core/utils/geohash.dart';
import '../../../../data/models/address_model.dart';
import '../../../../data/models/user_model.dart';
import '../../../../data/providers/repository_providers.dart';
import '../widgets/eligibility_bottom_sheet.dart';
import '../widgets/registration_form.dart';

class RegistrationPage extends ConsumerStatefulWidget {
  const RegistrationPage({super.key});

  @override
  ConsumerState<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends ConsumerState<RegistrationPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _mobileController = TextEditingController();

  DateTime? _dob;
  String? _gender;
  double? _latitude;
  double? _longitude;
  String? _locationAddress;
  String? _bloodGroup;
  bool isDonor = false;
  String? _donorError;
  XFile? _pickedImage;

  bool _obscurePassword = true;
  bool _isLoading = false;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));
    _fadeController.forward();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _mobileController.dispose();
    _fadeController.dispose();
    super.dispose();
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

  Future<String> _uploadImage(File file, String uid) async {
    final storageRepo = ref.read(storageRepositoryProvider);
    return await storageRepo.uploadFile(file, 'users/$uid.jpg');
  }

  int _calculateAge(DateTime dob) {
    final now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age;
  }

  Future<void> _handleDonorToggle() async {
    if (_dob == null) {
      setState(() => _donorError = 'Date of Birth is required');
      return;
    }

    final age = _calculateAge(_dob!);
    if (age < 18) {
      setState(
        () => _donorError =
            'You must be at least 18 years old to register as a donor.',
      );
      return;
    }

    final eligible = await showEligibilityBottomSheet(context);
    if (eligible == true && mounted) {
      setState(() {
        isDonor = true;
        _donorError = null;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _dob = picked);
  }

  Future<void> _handleRegistration() async {
    if (!_formKey.currentState!.validate()) return;

    if (isDonor && (_latitude == null || _longitude == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Please set your location on the map to register as a donor',
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    try {
      setState(() => _isLoading = true);

      final userCredential = await ref.read(authRepositoryProvider).signUp(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

      final uid = userCredential.user!.uid;
      String imageUrl = '';

      if (_pickedImage != null) {
        imageUrl = await _uploadImage(File(_pickedImage!.path), uid);
      }

      final createdAt = DateTime.now().toIso8601String();
      final token =
          await ref.read(firebaseDataSourceProvider).messaging.getToken();

      final geohash = (_latitude != null && _longitude != null)
          ? Geohash.encode(_latitude!, _longitude!)
          : null;

      final savedAddresses = <AddressModel>[];
      if (_latitude != null && _longitude != null && geohash != null) {
        savedAddresses.add(AddressModel(
          id: const Uuid().v4(),
          label: 'Home',
          latitude: _latitude!,
          longitude: _longitude!,
          geohash: geohash,
          addressText: _locationAddress ?? 'Selected Location',
        ));
      }

      final user = UserModel(
        uid: uid,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        mobileNumber: _mobileController.text.trim(),
        gender: _gender!,
        dateOfBirth: _dob!,
        communities: [],
        bloodGroup: _bloodGroup!,
        isDonor: isDonor,
        isEmergencyDonor: false,
        token: token ?? '',
        createdAt: createdAt,
        isOnline: false,
        image: imageUrl,
        latitude: _latitude,
        longitude: _longitude,
        geohash: geohash,
        locationAddress: _locationAddress,
        savedAddresses: savedAddresses,
      );

      await ref.read(userRepositoryProvider).createUser(uid, user.toJson());

      setState(() => _isLoading = false);
      if (mounted) Navigator.pushReplacementNamed(context, '/');
    } on FirebaseAuthException catch (e) {
      log('FirebaseAuth Error: ${e.code} - ${e.message}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message ?? 'Authentication error'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
      setState(() => _isLoading = false);
    } catch (e) {
      log('Registration Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unexpected error occurred'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Hero section
            Container(
              width: size.width,
              height: size.height * 0.3,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.red.shade800,
                    Colors.red.shade600,
                    Colors.red.shade400,
                  ],
                ),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.elliptical(300, 45),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Stack(
                  children: [
                    Positioned(
                      top: 8,
                      left: 8,
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_rounded),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white24,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    Center(
                      child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 12),
                          Container(
                        width: 64,
                        height: 64,
                        decoration: const BoxDecoration(
                          color: Colors.white24,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person_add_outlined,
                          color: Colors.white,
                          size: 34,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Create Account',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Join BloodFinder and start saving lives',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.8),
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

            // Form
            SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                  child: RegistrationForm(
                    formKey: _formKey,
                    firstNameController: _firstNameController,
                    lastNameController: _lastNameController,
                    emailController: _emailController,
                    passwordController: _passwordController,
                    mobileController: _mobileController,
                    dob: _dob,
                    gender: _gender,
                    selectedLatitude: _latitude,
                    selectedLongitude: _longitude,
                    locationAddress: _locationAddress,
                    bloodGroup: _bloodGroup,
                    isDonor: isDonor,
                    donorError: _donorError,
                    pickedImage: _pickedImage,
                    obscurePassword: _obscurePassword,
                    isLoading: _isLoading,
                    onPickImage: _pickImage,
                    onSelectDate: () => _selectDate(context),
                    onGenderChanged: (v) => setState(() => _gender = v),
                    onBloodGroupChanged: (v) => setState(() => _bloodGroup = v),
                    onDonorTap: _handleDonorToggle,
                    onLocationPicked: (lat, lon, address) => setState(() {
                      _latitude = lat;
                      _longitude = lon;
                      _locationAddress = address;
                    }),
                    onTogglePasswordVisibility: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                    onRegister: _handleRegistration,
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
