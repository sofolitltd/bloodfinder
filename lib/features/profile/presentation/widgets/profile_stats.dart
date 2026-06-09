import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

class ProfileStats extends StatelessWidget {
  final String bloodGroup;
  final int lifeSavedCount;
  final String nextDonationDay;
  final String nextDonationMonth;
  final String nextDonationText;
  final bool isEligible;
  final VoidCallback? onDonateTap;

  const ProfileStats({
    super.key,
    required this.bloodGroup,
    required this.lifeSavedCount,
    required this.nextDonationDay,
    required this.nextDonationMonth,
    required this.nextDonationText,
    this.isEligible = false,
    this.onDonateTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Transform.translate(
      offset: const Offset(0, -24),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        width: double.infinity,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _StatItem(
              icon: PhosphorIcons.drop,
              color: Colors.red.shade600,
              value: bloodGroup,
              label: 'Blood Group',
            ),
            _Divider(isDark: isDark),
            _StatItem(
              icon: PhosphorIcons.heart,
              color: Colors.red.shade600,
              value: '$lifeSavedCount',
              label: 'Lives Saved',
            ),
            _Divider(isDark: isDark),
            isEligible
                ? GestureDetector(
                    onTap: onDonateTap,
                    child: _StatItem(
                      icon: PhosphorIcons.checkCircle,
                      color: Colors.green,
                      value: 'Eligible',
                      label: 'Tap to view',
                    ),
                  )
                : _StatItem(
                    icon: PhosphorIcons.calendarBlank,
                    color: Colors.red.shade600,
                    value: nextDonationDay.isNotEmpty
                        ? '$nextDonationDay $nextDonationMonth'
                        : '-',
                    label: nextDonationText,
                  ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;

  const _StatItem({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 26),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  final bool isDark;

  const _Divider({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 48,
      color: isDark ? Colors.grey.shade700.withValues(alpha: 0.4) : Colors.grey.shade200,
    );
  }
}
