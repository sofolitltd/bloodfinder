import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
Future<bool?> showEligibilityBottomSheet(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => _EligibilityBottomSheet(),
  );
}

class _EligibilityBottomSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(24.w, 24.h, 24.w, 32.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            'Are you eligible to be a donor?',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'To ensure your safety and the safety of others, please confirm that:',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 16.h),
          _ChecklistItem(
            icon: Icons.monitor_weight,
            text: 'I weigh at least 50 kg (110 lbs).',
          ),
          SizedBox(height: 12.h),
          _ChecklistItem(
            icon: Icons.favorite,
            text: 'I am generally in good health.',
          ),
          SizedBox(height: 12.h),
          _ChecklistItem(
            icon: Icons.healing,
            text: 'I haven\'t had a tattoo or major surgery in the last 6 months.',
          ),
          SizedBox(height: 12.h),
          TextButton(
            onPressed: () => _showLearnMore(context),
            child: const Text('Learn More about eligibility'),
          ),
          SizedBox(height: 16.h),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
            child: const Text('I Confirm'),
          ),
          SizedBox(height: 12.h),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
            child: const Text('I am not eligible'),
          ),
        ],
      ),
    );
  }

  void _showLearnMore(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Blood Donation Eligibility'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Basic eligibility guidelines based on WHO recommendations:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 8.h),
              Text('• Be at least 18 years old'),
              SizedBox(height: 8.h),
              Text('• Weigh at least 50 kg (110 lbs)'),
              SizedBox(height: 8.h),
              Text('• Be in good general health'),
              SizedBox(height: 8.h),
              Text('• Have adequate hemoglobin levels'),
              SizedBox(height: 8.h),
              Text('• No new tattoo or piercing in last 6 months'),
              SizedBox(height: 8.h),
              Text('• No major surgery in last 6 months'),
              SizedBox(height: 8.h),
              Text('• Not pregnant or breastfeeding'),
              SizedBox(height: 8.h),
              Text('• No high-risk activities or recent travel to malaria-endemic areas'),
              SizedBox(height: 8.h),
              Text(
                'These are general guidelines. Final eligibility may vary based on local regulations and health screening at the donation center.',
                style: TextStyle(fontSize: 12.sp, color: Colors.grey),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _ChecklistItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _ChecklistItem({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 22.w, color: Colors.red.shade400),
        SizedBox(width: 12.w),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
  }
}
