import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../../shared/widgets/map_location_picker_page.dart';

class LocationSection extends StatelessWidget {
  final double? selectedLatitude;
  final double? selectedLongitude;
  final String? locationAddress;

  final void Function(double lat, double lon, String address) onLocationPicked;

  const LocationSection({
    super.key,
    required this.selectedLatitude,
    required this.selectedLongitude,
    required this.locationAddress,
    required this.onLocationPicked,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasLocation =
        selectedLatitude != null && selectedLongitude != null;

    return _LocationPickerTile(
      hasLocation: hasLocation,
      locationAddress: locationAddress,
      onTap: () async {
        final result = await MapLocationPickerPage.show(
          context,
          initialLatitude: selectedLatitude,
          initialLongitude: selectedLongitude,
        );
        if (result != null) {
          onLocationPicked(
            result.latitude,
            result.longitude,
            result.displayAddress,
          );
        }
      },
    );
  }
}

class _LocationPickerTile extends StatelessWidget {
  final bool hasLocation;
  final String? locationAddress;
  final VoidCallback onTap;

  const _LocationPickerTile({
    required this.hasLocation,
    required this.locationAddress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.red.shade200,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: Colors.red.shade50,
        ),
        child: Row(
          children: [
            Icon(
              PhosphorIcons.mapPin,
              size: 20,
              color: hasLocation
                  ? Colors.red.shade600
                  : Colors.red.shade300,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                hasLocation
                    ? (locationAddress ?? 'Location selected')
                    : 'Pick location on map',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight:
                      hasLocation ? FontWeight.w500 : FontWeight.normal,
                  color: hasLocation
                      ? Colors.grey.shade800
                      : Colors.grey.shade500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(width: 8),
            Icon(
              hasLocation
                  ? PhosphorIcons.pencilSimple
                  : PhosphorIcons.mapPinArea,
              size: 18,
              color: Colors.red.shade400,
            ),
          ],
        ),
      ),
    );
  }
}
