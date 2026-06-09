import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'auth_section.dart';
import 'contact_section.dart';
import 'donor_info_section.dart';
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
        spacing: 16,
        children: [
          // Section 1: Profile Info
          _sectionHeader('Profile Info', Icons.person_outline),
          UserInfoSection(
            firstNameController: firstNameController,
            lastNameController: lastNameController,
            mobileController: mobileController,
            pickedImage: pickedImage,
            onPickImage: onPickImage,
          ),

          // Section 2: Medical Info
          _sectionHeader('Medical Info', Icons.medical_information_outlined),
          DonorInfoSection(
            bloodGroup: bloodGroup,
            onBloodGroupChanged: onBloodGroupChanged,
            gender: gender,
            onGenderChanged: onGenderChanged,
            dob: dob,
            onSelectDate: onSelectDate,
          ),

          // Section 3: Donor Status
          _sectionHeader('Donor Status', Icons.bloodtype_outlined),
          ContactSection(
            selectedLatitude: selectedLatitude,
            selectedLongitude: selectedLongitude,
            locationAddress: locationAddress,
            isDonor: isDonor,
            donorError: donorError,
            onDonorTap: onDonorTap,
            onLocationPicked: onLocationPicked,
          ),

          // Section 4: Authentication
          _sectionHeader('Authentication', Icons.lock_outline),
          AuthSection(
            emailController: emailController,
            passwordController: passwordController,
            obscurePassword: obscurePassword,
            onTogglePasswordVisibility: onTogglePasswordVisibility,
            isLoading: isLoading,
            onRegister: onRegister,
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 2),
      child: Row(
        spacing: 8,
        children: [
          Icon(icon, size: 20, color: Colors.red.shade600),
          Text(
            title,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }
}
