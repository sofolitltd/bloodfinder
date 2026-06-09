import 'package:flutter/material.dart';

import '../../../../data/models/address_model.dart';
import 'address_management_section.dart';

class ProfileForm extends StatelessWidget {
  const ProfileForm({
    super.key,
    required this.firstNameController,
    required this.lastNameController,
    required this.mobileNumberController,
    required this.selectedGender,
    required this.selectedDOB,
    required this.savedAddresses,
    required this.activeGeohash,
    required this.selectedBloodGroup,
    required this.isDonor,
    required this.isLoading,
    required this.onGenderChanged,
    required this.onBloodGroupChanged,
    required this.onDonorChanged,
    required this.onAddressesChanged,
    required this.onActiveAddressChanged,
    required this.onSelectDate,
    required this.onUpdate,
  });

  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController mobileNumberController;
  final String? selectedGender;
  final DateTime? selectedDOB;
  final List<AddressModel> savedAddresses;
  final String? activeGeohash;
  final String? selectedBloodGroup;
  final bool isDonor;
  final bool isLoading;
  final ValueChanged<String?> onGenderChanged;
  final ValueChanged<String?> onBloodGroupChanged;
  final ValueChanged<bool> onDonorChanged;
  final ValueChanged<List<AddressModel>> onAddressesChanged;
  final ValueChanged<AddressModel?> onActiveAddressChanged;
  final VoidCallback onSelectDate;
  final VoidCallback onUpdate;

  @override
  Widget build(BuildContext context) {


    return Column(
      children: [
        // Name row
        Row(
          children: [
            Expanded(
              flex: 3,
              child: TextFormField(
                controller: firstNameController,
                decoration: const InputDecoration(labelText: 'First Name'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: lastNameController,
                decoration: const InputDecoration(labelText: 'Last Name'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Gender + DOB row
        Row(
          children: [
            Expanded(
              flex: 3,
              child: ButtonTheme(
                alignedDropdown: true,
                child: DropdownButtonFormField<String>(
                  value: selectedGender,
                  hint: const Text('Gender'),
                  items: ['Male', 'Female'].map((g) {
                    return DropdownMenuItem(value: g, child: Text(g));
                  }).toList(),
                  onChanged: onGenderChanged,
                  validator: (v) => v == null ? 'Required' : null,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: GestureDetector(
                onTap: onSelectDate,
                child: AbsorbPointer(
                  child: TextFormField(
                    decoration:
                        const InputDecoration(labelText: 'Date of Birth'),
                    controller: TextEditingController(
                      text: selectedDOB == null
                          ? ''
                          : '${selectedDOB!.day}/${selectedDOB!.month}/${selectedDOB!.year}',
                    ),
                    validator: (v) => selectedDOB == null ? 'Required' : null,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Mobile
        TextFormField(
          controller: mobileNumberController,
          decoration: const InputDecoration(labelText: 'Mobile Number'),
          keyboardType: TextInputType.phone,
          validator: (v) {
            if (v == null || v.isEmpty) return 'Required';
            return null;
          },
        ),
        const SizedBox(height: 12),

        // Address Management Section
        AddressManagementSection(
          savedAddresses: savedAddresses,
          activeGeohash: activeGeohash,
          isDonor: isDonor,
          onAddressesChanged: onAddressesChanged,
          onActiveAddressChanged: onActiveAddressChanged,
        ),
        const SizedBox(height: 12),

        // Blood Group
        DropdownButtonFormField<String>(
          value: selectedBloodGroup,
          hint: const Text('Blood Group'),
          items: ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-']
              .map((b) => DropdownMenuItem(value: b, child: Text(b)))
              .toList(),
          onChanged: onBloodGroupChanged,
          validator: (v) => v == null ? 'Required' : null,
        ),
        const SizedBox(height: 12),

        // Donor toggle
        CheckboxListTile(
          title: const Text('Listed as Donor'),
          value: isDonor,
          controlAffinity: ListTileControlAffinity.leading,
          onChanged: (v) => onDonorChanged(v!),
        ),
        const SizedBox(height: 24),

        // Submit
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: isLoading ? null : onUpdate,
            child: isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Update Profile'),
          ),
        ),
      ],
    );
  }
}

