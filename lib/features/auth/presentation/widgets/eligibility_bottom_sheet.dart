import 'package:flutter/material.dart';

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
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Are you eligible to be a donor?',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'To ensure your safety and the safety of others, please confirm that:',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          _ChecklistItem(
            icon: Icons.monitor_weight,
            text: 'I weigh at least 50 kg (110 lbs).',
          ),
          const SizedBox(height: 8),
          _ChecklistItem(
            icon: Icons.favorite,
            text: 'I am generally in good health.',
          ),
          const SizedBox(height: 8),
          _ChecklistItem(
            icon: Icons.healing,
            text: 'I haven\'t had a tattoo or major surgery in the last 6 months.',
          ),
          const SizedBox(height: 6),
          TextButton(
            onPressed: () => _showLearnMore(context),
            child: const Text('Learn More about eligibility'),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
            child: const Text('I Confirm'),
          ),
          const SizedBox(height: 12),
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
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Basic eligibility guidelines based on WHO recommendations:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 12),
              Text('• Be at least 18 years old'),
              SizedBox(height: 6),
              Text('• Weigh at least 50 kg (110 lbs)'),
              SizedBox(height: 6),
              Text('• Be in good general health'),
              SizedBox(height: 6),
              Text('• Have adequate hemoglobin levels'),
              SizedBox(height: 6),
              Text('• No new tattoo or piercing in last 6 months'),
              SizedBox(height: 6),
              Text('• No major surgery in last 6 months'),
              SizedBox(height: 6),
              Text('• Not pregnant or breastfeeding'),
              SizedBox(height: 6),
              Text('• No high-risk activities or recent travel to malaria-endemic areas'),
              SizedBox(height: 16),
              Text(
                'These are general guidelines. Final eligibility may vary based on local regulations and health screening at the donation center.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
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
        Icon(icon, size: 22, color: Colors.red.shade400),
        const SizedBox(width: 12),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
  }
}
