import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../../shared/widgets/map_location_picker_page.dart';

class ContactSection extends StatelessWidget {
  final double? selectedLatitude;
  final double? selectedLongitude;
  final String? locationAddress;
  final bool isDonor;
  final VoidCallback onDonorTap;
  final void Function(double lat, double lon, String address) onLocationPicked;
  final String? donorError;

  const ContactSection({
    super.key,
    required this.selectedLatitude,
    required this.selectedLongitude,
    required this.locationAddress,
    required this.isDonor,
    required this.onDonorTap,
    required this.onLocationPicked,
    this.donorError,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasLocation =
        selectedLatitude != null && selectedLongitude != null;
    final bool locationRequired = isDonor && !hasLocation;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Donor toggle
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDonor ? Colors.red.shade200 : Colors.grey.shade200,
              ),
              color: isDonor ? Colors.red.shade50 : Colors.grey.shade50,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sign up as a donor',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: isDonor
                              ? Colors.red.shade800
                              : Colors.grey.shade700,
                        ),
                      ),
                      Text(
                        isDonor
                            ? "You're ready to save lives"
                            : 'Donors must set their location below',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDonor
                              ? Colors.red.shade400
                              : Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: isDonor,
                  onChanged: (_) => onDonorTap(),
                  activeThumbColor: Colors.red.shade500,
                  activeTrackColor: Colors.red.shade200,
                ),
              ],
            ),
          ),

          // Inline error
          if (donorError != null)
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 4),
              child: Row(
                children: [
                  Icon(Icons.error_outline, size: 16, color: Colors.red.shade600),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      donorError!,
                      style: TextStyle(color: Colors.red.shade600, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 20),

          // Location
          Text(
            'Location',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          _LocationPickerTile(
            hasLocation: hasLocation,
            locationAddress: locationAddress,
            locationRequired: locationRequired,
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
          ),
        ],
      ),
    );
  }
}

class _LocationPickerTile extends StatelessWidget {
  final bool hasLocation;
  final String? locationAddress;
  final bool locationRequired;
  final VoidCallback onTap;

  const _LocationPickerTile({
    required this.hasLocation,
    required this.locationAddress,
    required this.locationRequired,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: locationRequired
                    ? Colors.red.shade300
                    : hasLocation
                        ? Colors.green.shade300
                        : Colors.grey.shade300,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  hasLocation ? Icons.location_on : Icons.location_off,
                  color: hasLocation ? Colors.green.shade600 : Colors.grey,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    hasLocation
                        ? (locationAddress ?? 'Location set')
                        : 'Tap to set location on map',
                    style: TextStyle(
                      color: hasLocation ? Colors.black87 : Colors.grey.shade600,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  PhosphorIcons.mapPin,
                  color: Colors.red.shade400,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        if (locationRequired)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              'Location is required to be listed as a donor',
              style: TextStyle(color: Colors.red.shade600, fontSize: 12),
            ),
          ),
        if (hasLocation)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Text(
              'Tap to change location',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
          ),
      ],
    );
  }
}
