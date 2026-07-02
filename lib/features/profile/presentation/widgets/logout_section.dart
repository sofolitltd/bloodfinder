import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../../data/providers/repository_providers.dart';
import '/routes/app_route.dart';
import 'section_header.dart';

class LogoutSection extends ConsumerWidget {
  const LogoutSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        SizedBox(height: 24.h),
        const SectionHeader(
          icon: Icons.shield_outlined,
          title: 'Account',
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
          child: GestureDetector(
            onTap: () => context.pushNamed(AppRoute.changePassword.name),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
              child: Row(
                children: [
                  Icon(PhosphorIcons.lock, size: 22.w),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      'Change Password',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    size: 20.w,
                    color: Colors.grey.shade400,
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(height: 12.h),
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
}
