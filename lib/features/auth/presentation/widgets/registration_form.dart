import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import 'auth_section.dart';
import 'donor_info_section.dart';
import 'location_section.dart';
import 'user_info_section.dart';

class RegistrationForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController mobileController;
  final DateTime? dob;
  final String? gender;
  final double? selectedLatitude;
  final double? selectedLongitude;
  final String? locationAddress;
  final String? bloodGroup;
  final bool isDonor;
  final String? donorError;
  final XFile? pickedImage;
  final bool obscurePassword;
  final bool isLoading;
  final VoidCallback onPickImage;
  final VoidCallback onSelectDate;
  final ValueChanged<String?> onGenderChanged;
  final ValueChanged<String?> onBloodGroupChanged;
  final VoidCallback onDonorTap;
  final void Function(double lat, double lon, String address) onLocationPicked;
  final VoidCallback onTogglePasswordVisibility;
  final VoidCallback onRegister;

  const RegistrationForm({
    super.key,
    required this.formKey,
    required this.firstNameController,
    required this.lastNameController,
    required this.emailController,
    required this.passwordController,
    required this.mobileController,
    required this.dob,
    required this.gender,
    required this.selectedLatitude,
    required this.selectedLongitude,
    required this.locationAddress,
    required this.bloodGroup,
    required this.isDonor,
    this.donorError,
    required this.pickedImage,
    required this.obscurePassword,
    required this.isLoading,
    required this.onPickImage,
    required this.onSelectDate,
    required this.onGenderChanged,
    required this.onBloodGroupChanged,
    required this.onDonorTap,
    required this.onLocationPicked,
    required this.onTogglePasswordVisibility,
    required this.onRegister,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section 1: Profile Info
          _SectionHeader(icon: PhosphorIcons.user, title: 'Profile Info'),
          SizedBox(height: 12.h),
          _SectionCard(
            child: UserInfoSection(
              firstNameController: firstNameController,
              lastNameController: lastNameController,
              mobileController: mobileController,
              pickedImage: pickedImage,
              onPickImage: onPickImage,
            ),
          ),

          SizedBox(height: 24.h),

          // Section 2: Medical Info
          _SectionHeader(
            icon: PhosphorIcons.heart,
            title: 'Medical Info',
          ),
          SizedBox(height: 12.h),
          _SectionCard(
            child: DonorInfoSection(
              bloodGroup: bloodGroup,
              onBloodGroupChanged: onBloodGroupChanged,
              gender: gender,
              onGenderChanged: onGenderChanged,
              dob: dob,
              onSelectDate: onSelectDate,
              isDonor: isDonor,
              onDonorTap: onDonorTap,
              donorError: donorError,
            ),
          ),

          SizedBox(height: 24.h),

          // Section 3: Location
          _SectionHeader(icon: PhosphorIcons.mapPin, title: 'Location'),
          SizedBox(height: 12.h),
          _SectionCard(
            child: LocationSection(
              selectedLatitude: selectedLatitude,
              selectedLongitude: selectedLongitude,
              locationAddress: locationAddress,
              onLocationPicked: onLocationPicked,
            ),
          ),

          SizedBox(height: 24.h),

          // Section 4: Authentication
          _SectionHeader(icon: PhosphorIcons.lock, title: 'Authentication'),
          SizedBox(height: 12.h),
          _SectionCard(
            child: AuthSection(
              emailController: emailController,
              passwordController: passwordController,
              obscurePassword: obscurePassword,
              onTogglePasswordVisibility: onTogglePasswordVisibility,
            ),
          ),

          SizedBox(height: 32.h),

          // Create Account button
          SizedBox(
            width: double.infinity,
            height: 50.h,
            child: ElevatedButton(
              onPressed: isLoading ? null : onRegister,
              style: ElevatedButton.styleFrom(elevation: 0),
              child: isLoading
                  ? SizedBox(
                      height: 22.h,
                      width: 22.w,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Text(
                      'Create Account',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
          SizedBox(height: 20.h),

          // Back to Login
          const Center(child: _BackToLoginLink()),

          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
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
          child: Icon(icon, size: 15, color: Colors.red.shade600),
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
  final Widget child;

  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
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
      child: child,
    );
  }
}

class _BackToLoginLink extends StatelessWidget {
  const _BackToLoginLink();

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () => Navigator.pop(context),
      style: TextButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.arrow_back_rounded,
            size: 18.w,
            color: Colors.red.shade600,
          ),
          SizedBox(width: 4.w),
          Text(
            'Back to Login',
            style: TextStyle(
              color: Colors.red.shade600,
              fontWeight: FontWeight.w500,
              fontSize: 14.sp,
            ),
          ),
        ],
      ),
    );
  }
}
