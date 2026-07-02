import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'activity_section.dart';
import 'appearance_section.dart';
import 'change_address_section.dart';
import 'donor_settings_section.dart';
import 'logout_section.dart';

class ProfileSettings extends ConsumerWidget {
  final String uid;
  final bool isDonorStatus;
  final bool isEmergencyDonorStatus;
  final String availability;
  final DateTime? snoozedUntil;
  final DateTime dateOfBirth;
  final ThemeMode themeMode;
  final String? locationAddress;

  const ProfileSettings({
    super.key,
    required this.uid,
    required this.isDonorStatus,
    required this.isEmergencyDonorStatus,
    required this.availability,
    this.snoozedUntil,
    required this.dateOfBirth,
    required this.themeMode,
    this.locationAddress,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        ChangeAddressSection(locationAddress: locationAddress),

        SizedBox(height: 16.h),

        DonorSettingsSection(
          uid: uid,
          isDonorStatus: isDonorStatus,
          isEmergencyDonorStatus: isEmergencyDonorStatus,
          availability: availability,
          snoozedUntil: snoozedUntil,
          dateOfBirth: dateOfBirth,
        ),

        const ActivitySection(),

        AppearanceSection(themeMode: themeMode),

        const LogoutSection(),
      ],
    );
  }
}
