import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../../data/providers/repository_providers.dart';
import '../../../../data/providers/theme_provider.dart';
import '../../../../features/auth/presentation/widgets/eligibility_bottom_sheet.dart';
import '/routes/app_route.dart';

class ProfileSettings extends ConsumerWidget {
  final String uid;
  final bool isDonorStatus;
  final bool isEmergencyDonorStatus;
  final String availability;
  final DateTime? snoozedUntil;
  final DateTime dateOfBirth;
  final ThemeMode themeMode;

  const ProfileSettings({
    super.key,
    required this.uid,
    required this.isDonorStatus,
    required this.isEmergencyDonorStatus,
    required this.availability,
    this.snoozedUntil,
    required this.dateOfBirth,
    required this.themeMode,
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
    dynamic userRepo,
  ) async {
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
    final themeNotifier = ref.read(themeModeProvider.notifier);
    final userRepo = ref.read(userRepositoryProvider);

    return Column(
      children: [
        // Donor Settings section header
        SizedBox(height: 8.h),
        const _SectionHeader(
          icon: Icons.bloodtype_outlined,
          title: 'Donor Settings',
        ),
        SizedBox(height: 6.h),

        // Donor is
        Ink(
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
          child: Material(
            color: Colors.transparent,
            child: ListTile(
              contentPadding: EdgeInsets.only(left: 16.w, right: 12.w),
              leading: Icon(PhosphorIcons.checkCircle, size: 20.w),
              title: Text(
                'Available to Donate',
                style: TextStyle(fontSize: 14.sp),
              ),
              trailing: Switch(
                value: isDonorStatus,
                onChanged: (value) =>
                    _handleDonorToggle(context, value, userRepo),
                activeThumbColor: Colors.red.shade700,
              ),
              onTap: () =>
                  _handleDonorToggle(context, !isDonorStatus, userRepo),
            ),
          ),
        ),

        if (isDonorStatus) ...[
          SizedBox(height: 8.h),
          _DonationStatusTile(
            availability: availability,
            snoozedUntil: snoozedUntil,
            uid: uid,
            userRepo: userRepo,
          ),
        ],

        SizedBox(height: 8.h),
        Ink(
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
          child: Material(
            color: Colors.transparent,
            child: ListTile(
              contentPadding: EdgeInsets.only(left: 16.w, right: 12.w),
              leading: Icon(PhosphorIcons.checkCircle, size: 20.w),
              title: Text(
                'Emergency Donor',
                style: TextStyle(fontSize: 14.sp),
              ),
              trailing: Switch(
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
              onTap: () async {
                await userRepo.updateUser(uid, {
                  'isEmergencyDonor': !isEmergencyDonorStatus,
                });
              },
            ),
          ),
        ),

        // Appearance section header
        SizedBox(height: 24.h),
        const _SectionHeader(
          icon: Icons.palette_outlined,
          title: 'Appearance',
        ),
        SizedBox(height: 8.h),
        Ink(
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
          child: Material(
            color: Colors.transparent,
            child: ListTile(
              contentPadding: EdgeInsets.only(left: 16.w, right: 12.w),
              leading: Icon(
              themeMode == ThemeMode.light
                  ? Icons.light_mode
                  : Icons.dark_mode,
              color: themeMode == ThemeMode.light
                  ? Colors.orange
                  : Colors.red,
            ),
            title: Text(
              'Change Theme',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
            trailing: Switch.adaptive(
              value: themeMode == ThemeMode.dark,
              onChanged: (_) => themeNotifier.toggleTheme(),
            ),
          ),
        ),
        ),

        // Activity section header
        SizedBox(height: 24.h),
        const _SectionHeader(
          icon: Icons.menu,
          title: 'Activity',
        ),
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
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 16.h),
            child: Column(
              spacing: 8,
              children: [
                _buildProfileOption(
                  Icons.scatter_plot,
                  'My Blood Requests',
                  () {
                    context.pushNamed(
                      AppRoute.bloodRequestHistory.name,
                    );
                  },
                ),
                _buildProfileOption(
                  Icons.history,
                  'My Donation History',
                  () {
                    context.pushNamed(AppRoute.donationHistory.name);
                  },
                ),
                _buildProfileOption(
                  Icons.history,
                  'Community Page',
                  () {
                    context.pushNamed(AppRoute.community.name);
                  },
                ),
                _buildProfileOption(
                  PhosphorIcons.calendar,
                  'Events Page',
                  () {
                    context.pushNamed(AppRoute.events.name);
                  },
                ),
              ],
            ),
          ),
        ),

        SizedBox(height: 24.h),
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
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: ElevatedButton.icon(
              onPressed: () => _showLogoutConfirm(context, ref),
              icon: const Icon(PhosphorIcons.signOut),
              label: const Text('Log Out'),
            ),
          ),
        ),
      ],
    );
  }

  void _showLogoutConfirm(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _performLogout(context, ref);
            },
            child: Text('Log Out', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _performLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (_) => Dialog(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16.w),
              Text('Logging out...'),
            ],
          ),
        ),
      ),
    );

    ref.read(firebaseDataSourceProvider).deleteToken().then((_) {
      ref.read(authRepositoryProvider).signOut();
    }).catchError((_) {
      if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
    });
  }

  Widget _buildProfileOption(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      visualDensity: VisualDensity.compact,
      leading: Icon(icon, size: 28.w),
      title: Text(
        title,
        style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 18,
        color: Colors.grey,
      ),
      onTap: onTap,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.only(top: 4.h, bottom: 2.h),
      child: Row(
        spacing: 8,
        children: [
          Icon(icon, size: 20, color: Colors.red.shade600),
          Text(
            title,
            style: TextStyle(
              fontSize: 17.sp,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.grey.shade200 : Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }
}

class _DonationStatusTile extends StatefulWidget {
  final String uid;
  final String availability;
  final DateTime? snoozedUntil;
  final dynamic userRepo;

  const _DonationStatusTile({
    required this.uid,
    required this.availability,
    this.snoozedUntil,
    required this.userRepo,
  });

  @override
  State<_DonationStatusTile> createState() => _DonationStatusTileState();
}

class _DonationStatusTileState extends State<_DonationStatusTile> {
  late String _selected;
  DateTime? _snoozeUntil;

  static const _options = [
    ('available', 'Available', Icons.check_circle, Colors.green),
    ('out_of_city', 'Out of City', Icons.flight_takeoff, Colors.orange),
    ('unavailable', "Can't Donate", Icons.block, Colors.red),
  ];

  @override
  void initState() {
    super.initState();
    _selected = widget.availability;
    _snoozeUntil = widget.snoozedUntil;
  }

  Future<void> _updateAvailability(String value) async {
    if (value == _selected) return;

    final labels = {
      'available': 'Available',
      'out_of_city': 'Out of City',
      'unavailable': "Can't Donate",
    };

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).colorScheme.surface,
        title: const Text('Change Donation Status'),
        content: Text('Switch your status to "${labels[value]}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _selected = value);

    final data = <String, dynamic>{'availability': value};
    if (value != 'unavailable') {
      data['snoozedUntil'] = FieldValue.delete();
      _snoozeUntil = null;
    }

    await widget.userRepo.updateUser(widget.uid, data);
    if (!mounted) return;
    setState(() {});

    if (value == 'unavailable') {
      _showSnoozePicker();
    }
  }

  Future<void> _showSnoozePicker() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (date == null || !mounted) return;

    setState(() => _snoozeUntil = date);
    await widget.userRepo.updateUser(widget.uid, {
      'snoozedUntil': Timestamp.fromDate(date),
    });
  }

  @override
  Widget build(BuildContext context) {
    final current = _options.firstWhere(
      (o) => o.$1 == _selected,
      orElse: () => _options[0],
    );

    return Container(
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
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(current.$3, size: 18, color: current.$4),
              SizedBox(width: 8.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Donation Status',
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_snoozeUntil != null)
                      Text(
                        'Snoozed until ${DateFormat.yMMMd().format(_snoozeUntil!)}',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: Colors.grey.shade600,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(vertical: 4.h),
            child: Row(
              spacing: 6,
              children: _options.map((opt) {
                final selected = opt.$1 == _selected;
                return GestureDetector(
                  onTap: () => _updateAvailability(opt.$1),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? opt.$4.withValues(alpha: 0.15)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(
                        color: selected
                            ? opt.$4
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(opt.$3, size: 14, color: selected ? opt.$4 : Colors.grey),
                        SizedBox(width: 4.w),
                        Text(
                          opt.$2,
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                            color: selected ? opt.$4 : Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    ),
    );
  }
}
