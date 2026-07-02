import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/user_model.dart';
import '../../../../core/utils/string_utils.dart';
import '../../../../data/providers/repository_providers.dart';
import '../../../../data/providers/theme_provider.dart';
import '../../../../data/providers/user_providers.dart';
import '../../../donation/presentation/pages/donation_history_page.dart';
import '../../providers/profile_provider.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_settings.dart';
import '../widgets/profile_stats.dart';
import 'edit_profile_page.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    ));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userProvider);
    final userDocAsync = ref.watch(userDocProvider);
    final donationInfo = ref.watch(profileDonationInfoProvider);
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (UserModel? user) {
          if (user == null) {
            return const Center(child: Text('User data not found.'));
          }

          final rawData = userDocAsync.value?.data();
          final availability =
              rawData?['availability'] as String? ?? 'available';
          final snoozedUntil = rawData?['snoozedUntil'] as Timestamp?;

          if (snoozedUntil != null &&
              snoozedUntil.toDate().isBefore(DateTime.now())) {
            ref.read(userRepositoryProvider).updateUser(user.uid, {
              'availability': 'available',
              'snoozedUntil': FieldValue.delete(),
            });
          }

          final fullName = StringUtils.formatFullName(user.firstName, user.lastName);
          final address = user.locationAddress ?? '';
          final bloodGroup = user.bloodGroup;
          final isDonorStatus = user.isDonor;
          final isEmergencyDonorStatus = user.isEmergencyDonor;
          final isVerified = rawData?['isVerifiedDonor'] as bool? ?? false;
          final badges = (rawData?['badges'] as List<dynamic>?)
                  ?.cast<String>() ??
              [];

          void navigateToDonationHistory() {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DonationHistoryPage()),
            );
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                //
                ProfileHeader(
                  user: user,
                  fullName: fullName,
                  address: address,
                  isVerified: isVerified,
                  badges: badges,
                  onEditTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const EditProfilePage()),
                    );
                  },
                ),

                // Stats card
                ProfileStats(
                  bloodGroup: bloodGroup,
                  lifeSavedCount: donationInfo.lifeSavedCount,
                  nextDonationDay: donationInfo.nextDonationDay,
                  nextDonationMonth: donationInfo.nextDonationMonth,
                  nextDonationText: donationInfo.nextDonationText,
                  isEligible: donationInfo.isEligible,
                  onDonateTap: navigateToDonationHistory,
                ),

                Transform.translate(
                  offset: const Offset(0, -80),
                  child: Column(
                    children: [
                      SizedBox(height: 28.h),

                      // Animated settings
                      FadeTransition(
                        opacity: _fadeAnim,
                        child: SlideTransition(
                          position: _slideAnim,
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.w),
                            child: ProfileSettings(
                              uid: user.uid,
                              isDonorStatus: isDonorStatus,
                              isEmergencyDonorStatus: isEmergencyDonorStatus,
                              availability: availability,
                              snoozedUntil: snoozedUntil?.toDate(),
                              dateOfBirth: user.dateOfBirth,
                              themeMode: themeMode,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
