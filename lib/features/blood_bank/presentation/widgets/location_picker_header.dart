import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

class LocationPickerHeader extends StatelessWidget {
  final String? locationAddress;
  final double radiusInKm;
  final VoidCallback onOpenLocationPicker;
  final ValueChanged<double> onRadiusChanged;
  final VoidCallback onRadiusChangeEnd;

  const LocationPickerHeader({
    super.key,
    required this.locationAddress,
    required this.radiusInKm,
    required this.onOpenLocationPicker,
    required this.onRadiusChanged,
    required this.onRadiusChangeEnd,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
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
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: .start,
          children: [
            InkWell(
              onTap: onOpenLocationPicker,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark
                        ? Colors.grey.shade700.withValues(alpha: 0.3)
                        : Colors.grey.shade300,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(PhosphorIcons.mapPin, color: Colors.red.shade400, size: 20),
                    SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        locationAddress ?? 'Set search location',
                        style: TextStyle(
                          color: isDark ? Colors.grey.shade300 : Colors.black87,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(Icons.edit, color: Colors.grey.shade400, size: 16),
                  ],
                ),
              ),
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Search Radius',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                    fontSize: 14,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${radiusInKm.round()} km',
                    style: TextStyle(
                      color: Colors.red.shade600,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            Slider(
              value: radiusInKm,
              min: 5.0,
              max: 200.0,
              divisions: 39,
              label: '${radiusInKm.round()} km',
              activeColor: Colors.red.shade500,
              inactiveColor: Colors.red.shade100,
              onChanged: onRadiusChanged,
              onChangeEnd: (_) => onRadiusChangeEnd(),
            ),
          ],
        ),
      ),
    );
  }
}
