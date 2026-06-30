import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../community/presentation/pages/create_community_page.dart';
import '../../../blood_bank/presentation/widgets/add_blood_bank_sheet.dart';
import 'feedback_sheet.dart';

class HomeCommunityContributionSection extends StatelessWidget {
  const HomeCommunityContributionSection({super.key});

  void _showAddOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'What do you want to add?',
              style: Theme.of(ctx).textTheme.titleMedium,
            ),
            SizedBox(height: 20.h),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const CreateCommunityScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.people),
              label: const Text('Community'),
            ),
            SizedBox(height: 12.h),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(ctx).pop();
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => const AddBloodBankSheet(),
                );
              },
              icon: const Icon(Icons.local_hospital),
              label: const Text('Blood Bank'),
            ),
            SizedBox(height: 12.h),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(16.r),
          bottomRight: Radius.circular(16.r),
        ),
        border: Border.all(
          color: isDark ? Colors.transparent : Colors.grey.shade200,
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
      children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 3.5,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.red.shade700,
                    Colors.red.shade400,
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  spacing: 10,
                  children: [
                    Container(
                      width: 40.w,
                      height: 48.h,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.red.shade600, Colors.red.shade400],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(
                        PhosphorIcons.globeHemisphereWest,
                        color: Colors.white,
                        size: 22.w,
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Help Us Expand',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.grey.shade200 : Colors.grey.shade800,
                          ),
                        ),
                        Text(
                          'Community-driven growth',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Text(
                  'BloodFinder is community-driven. Help us grow by adding local resources or sharing your feedback.',
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    height: 1.4,
                  ),
                ),
                SizedBox(height: 16.h),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 44.h,
                        child: ElevatedButton.icon(
                          onPressed: () => _showAddOptions(context),
                          icon: Icon(Icons.add_location_alt, size: 18.w),
                          label: Text(
                            'Add Local Resource',
                            style: TextStyle(fontSize: 12.sp),
                            overflow: TextOverflow.ellipsis,
                          ),
                          style: ElevatedButton.styleFrom(elevation: 0),
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: SizedBox(
                        height: 44.h,
                        child: OutlinedButton.icon(
                          onPressed: () => showFeedbackSheet(context),
                          icon: Icon(Icons.feedback_outlined, size: 18.w),
                          label: Text(
                            'Share Feedback',
                            style: TextStyle(fontSize: 12.sp),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
