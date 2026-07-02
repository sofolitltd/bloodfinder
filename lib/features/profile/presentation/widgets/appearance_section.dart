import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/providers/theme_provider.dart';
import 'section_header.dart';

class AppearanceSection extends ConsumerWidget {
  final ThemeMode themeMode;

  const AppearanceSection({super.key, required this.themeMode});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeNotifier = ref.read(themeModeProvider.notifier);

    return Column(
      children: [
        SizedBox(height: 24.h),
        const SectionHeader(
          icon: Icons.palette_outlined,
          title: 'Appearance',
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
            padding: EdgeInsets.only(left: 16.w, right: 12.w),
            child: Row(
              children: [
                Icon(
                  themeMode == ThemeMode.light
                      ? Icons.light_mode
                      : Icons.dark_mode,
                  color: themeMode == ThemeMode.light
                      ? Colors.orange
                      : Colors.red,
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Text(
                    'Change Theme',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Switch.adaptive(
                  value: themeMode == ThemeMode.dark,
                  onChanged: (_) => themeNotifier.toggleTheme(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
