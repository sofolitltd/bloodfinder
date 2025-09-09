import 'dart:developer';

import 'package:flutter/material.dart';

import '../../../data/db/app_data.dart';
import '../../community/search_page.dart';
import '../../donation/find_donor.dart';

class HomeFindDonorSection extends StatefulWidget {
  const HomeFindDonorSection({super.key});

  @override
  State<HomeFindDonorSection> createState() => _HomeFindDonorSectionState();
}

class _HomeFindDonorSectionState extends State<HomeFindDonorSection> {
  String? _selectedBloodGroup;
  String? _selectedDistrict;
  String? _selectedSubdistrict;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Are you looking for blood?",
              style: TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 16),

            // Blood Group Dropdown (Required)
            ButtonTheme(
              alignedDropdown: true,
              child: DropdownButtonFormField<String>(
                initialValue: _selectedBloodGroup,
                decoration: const InputDecoration(labelText: 'Blood Group *'),
                items: AppData.bloodGroups
                    .map((bg) => DropdownMenuItem(value: bg, child: Text(bg)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedBloodGroup = val),
              ),
            ),
            const SizedBox(height: 12),

            // District Dropdown (Optional now)
            _buildDistrictDropdown(),

            // Subdistrict Dropdown (Optional, only if district selected)
            if (_selectedDistrict != null) ...[
              const SizedBox(height: 12),

              _buildSubDistrictDropdown(),
            ],
            const SizedBox(height: 16),

            // Search Button
            ElevatedButton(
              onPressed: () {
                if (_selectedBloodGroup == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please select a blood group'),
                    ),
                  );
                  return;
                }

                log(
                  "Blood: $_selectedBloodGroup, District: $_selectedDistrict, Subdistrict: $_selectedSubdistrict",
                );

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FindDonorPage(
                      bloodGroup: _selectedBloodGroup!,
                      district: _selectedDistrict, // can be null
                      subdistrict: _selectedSubdistrict, // can be null
                    ),
                  ),
                );
              },
              child: const Text('Find Donors'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDistrictDropdown() {
    return TextFormField(
      readOnly: true,
      decoration: InputDecoration(
        hintText: _selectedDistrict ?? 'Select District (Optional)',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        suffixIcon: _selectedDistrict != null
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    _selectedDistrict = null;
                    _selectedSubdistrict = null;
                  });
                },
              )
            : const Icon(Icons.arrow_drop_down),
      ),
      onTap: () async {
        final selectedValue = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SearchPage(
              title: 'District',
              items: AppData.districts.map((d) => d.name).toList()..sort(),
            ),
          ),
        );

        if (selectedValue != null) {
          setState(() {
            _selectedDistrict = selectedValue;
            _selectedSubdistrict = null;
          });
        }
      },
    );
  }

  Widget _buildSubDistrictDropdown() {
    final subDistricts = _selectedDistrict != null
        ? AppData.districts
              .firstWhere((d) => d.name == _selectedDistrict)
              .subDistricts
        : <String>[];

    return TextFormField(
      readOnly: true,
      enabled: _selectedDistrict != null,
      decoration: InputDecoration(
        hintText: _selectedSubdistrict ?? 'Select Subdistrict (Optional)',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        suffixIcon: _selectedSubdistrict != null
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() => _selectedSubdistrict = null);
                },
              )
            : const Icon(Icons.arrow_drop_down),
      ),
      onTap: () async {
        if (_selectedDistrict == null) return;

        final selectedValue = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                SearchPage(title: 'Subdistrict', items: subDistricts),
          ),
        );

        if (selectedValue != null) {
          setState(() => _selectedSubdistrict = selectedValue);
        }
      },
    );
  }
}
