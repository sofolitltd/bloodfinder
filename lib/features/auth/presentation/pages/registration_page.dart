import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../providers/registration_provider.dart';
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

  bool _obscurePassword = true;

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
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
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

  Future<void> _selectDate() async {
    final state = ref.read(registrationProvider);
    final picked = await showDatePicker(
      context: context,
      initialDate: state.dob ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      ref.read(registrationProvider.notifier).setDob(picked);
    }
  }

  Future<void> _handleDonorToggle() async {
    final notifier = ref.read(registrationProvider.notifier);
    final state = ref.read(registrationProvider);

    final error = notifier.validateDonorEligibility(state.dob);
    if (error != null) {
      notifier.setDonorError(error);
      return;
    }

    final eligible = await showEligibilityBottomSheet(context);
    if (eligible == true && mounted) {
      notifier.setDonor(true);
    }
  }

  Future<void> _handleRegistration() async {
    if (!_formKey.currentState!.validate()) return;

    final state = ref.read(registrationProvider);

    if (state.isDonor && (state.latitude == null || state.longitude == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Please set your location on the map to register as a donor',
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.r),
          ),
        ),
      );
      return;
    }

    try {
      final notifier = ref.read(registrationProvider.notifier);
      await notifier.register(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        mobileNumber: _mobileController.text.trim(),
      );

      if (mounted) Navigator.pushReplacementNamed(context, '/');
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message ?? 'Authentication error'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.r),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Unexpected error occurred'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final regState = ref.watch(registrationProvider);

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Hero section
            Container(
              width: size.width,
              height: size.height * 0.25,
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
                borderRadius: BorderRadius.vertical(
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
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 32.w,
                                  height: 32.h,
                                  decoration: const BoxDecoration(
                                    color: Colors.white24,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.person_add_outlined,
                                    color: Colors.white,
                                    size: 16.w,
                                  ),
                                ),
                                SizedBox(width: 4.h),
                                Text(
                                  'Create Account',
                                  style: TextStyle(
                                    fontSize: 26.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              'Join BloodFinder and start saving lives',
                              style: TextStyle(
                                fontSize: 13.sp,
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
                  padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 24.h),
                  child: RegistrationForm(
                    formKey: _formKey,
                    firstNameController: _firstNameController,
                    lastNameController: _lastNameController,
                    emailController: _emailController,
                    passwordController: _passwordController,
                    mobileController: _mobileController,
                    dob: regState.dob,
                    gender: regState.gender,
                    selectedLatitude: regState.latitude,
                    selectedLongitude: regState.longitude,
                    locationAddress: regState.locationAddress,
                    bloodGroup: regState.bloodGroup,
                    isDonor: regState.isDonor,
                    donorError: regState.donorError,
                    pickedImage: regState.pickedImage,
                    obscurePassword: _obscurePassword,
                    isLoading: regState.isLoading,
                    onPickImage: () =>
                        ref.read(registrationProvider.notifier).pickImage(),
                    onSelectDate: _selectDate,
                    onGenderChanged: (v) =>
                        ref.read(registrationProvider.notifier).setGender(v),
                    onBloodGroupChanged: (v) =>
                        ref.read(registrationProvider.notifier).setBloodGroup(v),
                    onDonorTap: _handleDonorToggle,
                    onLocationPicked: (lat, lon, address) =>
                        ref.read(registrationProvider.notifier)
                            .setLocation(lat, lon, address),
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
