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
        title: const Text('Address Label', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: labelController,
          decoration: const InputDecoration(
            hintText: 'e.g., Home, Office, University',
          ),
          autofocus: true,
        ),
        actions: [
          Row(
            spacing: 8,
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
              ),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    if (labelController.text.trim().isNotEmpty) {
                      Navigator.pop(ctx, labelController.text.trim());
                    }
                  },
                  child: const Text('Save'),
                ),
              ),
            ],
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

      final newList = List<AddressModel>.from(widget.savedAddresses)
        ..add(newAddress);
      widget.onAddressesChanged(newList);

      // If it's the first address added, make it active
      if (widget.activeGeohash == null || widget.savedAddresses.isEmpty) {
        widget.onActiveAddressChanged(newAddress);
      }
    }
  }

  Future<void> _removeAddress(AddressModel address) async {
    if (widget.savedAddresses.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You must have at least one saved address.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).colorScheme.surface,
        title: const Text('Remove Address', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        content: Text('Remove "${address.label}" from your saved addresses?'),
        actions: [
          Row(
            spacing:8,
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel'),
                ),
              ),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Remove'),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final newList = List<AddressModel>.from(widget.savedAddresses)
      ..removeWhere((a) => a.id == address.id);

    widget.onAddressesChanged(newList);

    // If the removed address was the active one, fallback to the first available
    if (widget.activeGeohash == address.geohash) {
      widget.onActiveAddressChanged(newList.first);
    }
  }

  Future<void> _setActiveAddress(AddressModel address) async {
    if (widget.activeGeohash == address.geohash) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).colorScheme.surface,
        title: const Text('Change Active Address', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        content: Text('Set "${address.label}" as your active location?'),
        actions: [
          Row(
            spacing:8,
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel'),
                ),
              ),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Set Active'),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    widget.onActiveAddressChanged(address);
  }

  @override
  Widget build(BuildContext context) {
    final bool hasNoLocation = widget.activeGeohash == null;
    final bool isWarning = widget.isDonor && hasNoLocation;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'My Locations',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            TextButton.icon(
              onPressed: _addNewAddress,
              style: TextButton.styleFrom(foregroundColor: Colors.red.shade700),
              icon: Icon(Icons.add_location_alt, size: 18),
              label: const Text('Add New'),
            ),
          ],
        ),
        if (isWarning)
          Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text(
              'Location is required to be visible as a donor. Please add and select a location.',
              style: TextStyle(color: Colors.red, fontSize: 13),
            ),
          ),
        Divider(height: 8),
        // const SizedBox(height: 8),
        if (widget.savedAddresses.isEmpty)
          Padding(
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
            padding: EdgeInsets.symmetric(vertical: 8),
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.savedAddresses.length,
            separatorBuilder: (_, _) => Container(height: 12),
            itemBuilder: (context, index) {
              final address = widget.savedAddresses[index];
              // In case of multiple exact same geohashes (rare but possible),
              // we compare ID if available, else fallback to geohash match for active state.
              final bool isActive = widget.activeGeohash == address.geohash;

              return InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => _setActiveAddress(address),
                child: Container(
                  decoration: BoxDecoration(
                    color: isActive ? Colors.green.shade50 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isActive ? Colors.green : Colors.grey.shade300,
                      width: 1,
                    ),
                  ),
                  padding: const EdgeInsets.only(
                    bottom: 8,
                    // vertical: 8,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: .only(left:8),
                        child: Row(
                          children: [
                            Icon(
                              isActive
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_off,
                              color: isActive ? Colors.green : Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              address.label,
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                            if (isActive)
                              Container(
                                margin: EdgeInsets.only(left: 16),
                                padding: EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(4),
                               
                                ),
                                child: Text(
                                  'Active',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            const Spacer(),
                            IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              icon: Icon(
                                Icons.delete_outline,
                                color: Colors.redAccent,
                                size: 20,
                              ),
                              onPressed: () => _removeAddress(address),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: .only(left:12),
                        child: Text(
                          address.addressText,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
