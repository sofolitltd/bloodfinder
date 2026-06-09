import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/utils/geohash.dart';
import '../../../../data/models/address_model.dart';
import '../../../../shared/widgets/map_location_picker_page.dart';

class AddressManagementSection extends StatefulWidget {
  final List<AddressModel> savedAddresses;
  final String? activeGeohash;
  final bool isDonor;
  final ValueChanged<List<AddressModel>> onAddressesChanged;
  final ValueChanged<AddressModel?> onActiveAddressChanged;

  const AddressManagementSection({
    super.key,
    required this.savedAddresses,
    required this.activeGeohash,
    required this.isDonor,
    required this.onAddressesChanged,
    required this.onActiveAddressChanged,
  });

  @override
  State<AddressManagementSection> createState() =>
      _AddressManagementSectionState();
}

class _AddressManagementSectionState extends State<AddressManagementSection> {
  Future<void> _addNewAddress() async {
    final result = await MapLocationPickerPage.show(context);
    if (result == null || !mounted) return;

    final labelController = TextEditingController();
    final String? label = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Address Label'),
        content: TextField(
          controller: labelController,
          decoration: const InputDecoration(
            hintText: 'e.g., Home, Office, University',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (labelController.text.trim().isNotEmpty) {
                Navigator.pop(ctx, labelController.text.trim());
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (label != null && label.isNotEmpty) {
      final newAddress = AddressModel(
        id: const Uuid().v4(),
        label: label,
        latitude: result.latitude,
        longitude: result.longitude,
        geohash: Geohash.encode(result.latitude, result.longitude),
        addressText: result.displayAddress,
      );

      final newList = List<AddressModel>.from(widget.savedAddresses)..add(newAddress);
      widget.onAddressesChanged(newList);

      // If it's the first address added, make it active
      if (widget.activeGeohash == null || widget.savedAddresses.isEmpty) {
        widget.onActiveAddressChanged(newAddress);
      }
    }
  }

  void _removeAddress(AddressModel address) {
    if (widget.savedAddresses.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must have at least one saved address.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final newList = List<AddressModel>.from(widget.savedAddresses)
      ..removeWhere((a) => a.id == address.id);

    widget.onAddressesChanged(newList);

    // If the removed address was the active one, fallback to the first available
    if (widget.activeGeohash == address.geohash) {
      widget.onActiveAddressChanged(newList.first);
    }
  }

  void _setActiveAddress(AddressModel address) {
    widget.onActiveAddressChanged(address);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool hasNoLocation = widget.activeGeohash == null;
    final bool isWarning = widget.isDonor && hasNoLocation;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(
          color: isWarning ? Colors.red : (isDark ? Colors.grey.shade700.withValues(alpha: 0.3) : Colors.grey.shade300),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'My Locations',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton.icon(
                onPressed: _addNewAddress,
                icon: const Icon(Icons.add_location_alt, size: 18),
                label: const Text('Add New'),
              ),
            ],
          ),
          if (isWarning)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text(
                'Location is required to be visible as a donor. Please add and select a location.',
                style: TextStyle(color: Colors.red, fontSize: 13),
              ),
            ),
          const Divider(height: 1),
          if (widget.savedAddresses.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No saved addresses.\nAdd a new one to be visible in searches.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.savedAddresses.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final address = widget.savedAddresses[index];
                // In case of multiple exact same geohashes (rare but possible),
                // we compare ID if available, else fallback to geohash match for active state.
                final bool isActive = widget.activeGeohash == address.geohash;

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Radio<String>(
                    value: address.geohash,
                    groupValue: widget.activeGeohash,
                    activeColor: Colors.green,
                    onChanged: (_) => _setActiveAddress(address),
                  ),
                  title: Row(
                    children: [
                      Text(
                        address.label,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      if (isActive)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: const Text(
                            'Active',
                            style: TextStyle(fontSize: 10, color: Colors.green),
                          ),
                        ),
                    ],
                  ),
                  subtitle: Text(
                    address.addressText,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: Colors.redAccent, size: 20),
                    onPressed: () => _removeAddress(address),
                  ),
                  onTap: () => _setActiveAddress(address),
                );
              },
            ),
        ],
      ),
    );
  }
}
