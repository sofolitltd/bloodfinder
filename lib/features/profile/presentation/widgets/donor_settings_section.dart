import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../../data/providers/repository_providers.dart';
import '../../../../features/auth/presentation/widgets/eligibility_bottom_sheet.dart';
import 'donation_status_tile.dart';
import 'section_header.dart';

class DonorSettingsSection extends ConsumerWidget {
  final String uid;
  final bool isDonorStatus;
  final bool isEmergencyDonorStatus;
  final String availability;
  final DateTime? snoozedUntil;
  final DateTime dateOfBirth;

  const DonorSettingsSection({
    super.key,
    required this.uid,
    required this.isDonorStatus,
    required this.isEmergencyDonorStatus,
    required this.availability,
    this.snoozedUntil,
    required this.dateOfBirth,
  });

  int _calculateAge(DateTime dob) {
    final now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age;
  }

  Future<void> _handleDonorToggle(
    BuildContext context,
    bool newValue,
    WidgetRef ref,
  ) async {
    final userRepo = ref.read(userRepositoryProvider);

    if (newValue) {
      final age = _calculateAge(dateOfBirth);
      if (age < 18) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'You must be at least 18 years old to be a donor.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      final eligible = await showEligibilityBottomSheet(context);
      if (eligible != true) return;
      if (!context.mounted) return;
    } else {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Theme.of(ctx).colorScheme.surface,
          title: const Text('Stop Being a Donor'),
          content: const Text(
            'You will no longer appear in donor searches. Are you sure?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Stop'),
            ),
          ],
        ),
      );
      if (confirmed != true || !context.mounted) return;
    }

    await userRepo.updateUser(uid, {'isDonor': newValue});
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          newValue ? 'You are now a donor.' : 'You are no longer a donor.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userRepo = ref.read(userRepositoryProvider);

    return Column(
      children: [
        SizedBox(height: 8.h),
        const SectionHeader(
          icon: Icons.bloodtype_outlined,
          title: 'Donor Settings',
        ),
        SizedBox(height: 6.h),

        Container(
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
          child: GestureDetector(
            onTap: () => _handleDonorToggle(context, !isDonorStatus, ref),
            child: Padding(
              padding: EdgeInsets.only(left: 16.w, right: 12.w),
              child: Row(
                children: [
                  Icon(PhosphorIcons.checkCircle, size: 20.w),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Text(
                      'Available to Donate',
                      style: TextStyle(fontSize: 14.sp),
                    ),
                  ),
                  Switch(
                    value: isDonorStatus,
                    onChanged: (value) =>
                        _handleDonorToggle(context, value, ref),
                    activeThumbColor: Colors.red.shade700,
                  ),
                ],
              ),
            ),
          ),
        ),

        if (isDonorStatus) ...[
          SizedBox(height: 8.h),
          DonationStatusTile(
            availability: availability,
            snoozedUntil: snoozedUntil,
            uid: uid,
            userRepo: userRepo,
          ),
        ],

        SizedBox(height: 8.h),
        Container(
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
          child: GestureDetector(
            onTap: () async {
              await userRepo.updateUser(uid, {
                'isEmergencyDonor': !isEmergencyDonorStatus,
              });
            },
            child: Padding(
              padding: EdgeInsets.only(left: 16.w, right: 12.w),
              child: Row(
                children: [
                  Icon(PhosphorIcons.checkCircle, size: 20.w),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Text(
                      'Emergency Donor',
                      style: TextStyle(fontSize: 14.sp),
                    ),
                  ),
                  Switch(
                    value: isEmergencyDonorStatus,
                    onChanged: (value) async {
                      await userRepo.updateUser(uid, {'isEmergencyDonor': value});
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              value
                                  ? 'You are now an emergency donor.'
                                  : 'You are no longer an emergency donor.',
                            ),
                          ),
                        );
                      }
                    },
                    activeThumbColor: Colors.red.shade700,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
