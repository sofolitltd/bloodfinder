import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

class ExpiryDurationSelector extends StatelessWidget {
  final DateTime? selectedExpiresAt;
  final ValueChanged<DateTime?> onExpiryChanged;

  const ExpiryDurationSelector({
    super.key,
    this.selectedExpiresAt,
    required this.onExpiryChanged,
  });

  static const _presetDays = [1, 2, 3, 5, 7];

  int? get _matchingPresetDays {
    if (selectedExpiresAt == null) return null;
    final now = DateTime.now();
    for (final days in _presetDays) {
      final target = now.add(Duration(days: days));
      if (selectedExpiresAt!.difference(target).abs() <
          const Duration(minutes: 2)) {
        return days;
      }
    }
    return null;
  }

  Future<void> _pickCustom(BuildContext context) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      initialDate: selectedExpiresAt ?? now,
    );
    if (date == null) return;
    if (!context.mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: selectedExpiresAt != null
          ? TimeOfDay.fromDateTime(selectedExpiresAt!)
          : TimeOfDay.now(),
    );
    if (time == null) return;

    onExpiryChanged(
      DateTime(date.year, date.month, date.day, time.hour, time.minute),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final matchingPreset = _matchingPresetDays;
    final isCustom = selectedExpiresAt != null && matchingPreset == null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: [
            for (final days in _presetDays)
              ChoiceChip(
                label: Text(days == 1 ? '1 Day' : '$days Days'),
                selected: matchingPreset == days,
                onSelected: (_) => onExpiryChanged(
                  DateTime.now().add(Duration(days: days)),
                ),
              ),
            ChoiceChip(
              label: const Text('Custom'),
              selected: isCustom,
              onSelected: (_) => _pickCustom(context),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        Row(
          children: [
            Icon(PhosphorIcons.hourglass,
                size: 16.w, color: Colors.grey.shade500),
            SizedBox(width: 6.w),
            Text(
              selectedExpiresAt == null
                  ? 'Choose how long this request stays active'
                  : 'Expires: ${DateFormat('d MMM, yyyy - h:mm a').format(selectedExpiresAt!)}',
              style: TextStyle(
                fontSize: 12.sp,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
