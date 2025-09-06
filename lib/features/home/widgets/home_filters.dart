import 'package:flutter/material.dart';

import '../../../data/db/app_data.dart';
import '../../community/search_page.dart';
import '../../donation/find_donor.dart';

class HomeFilterSection extends StatefulWidget {
  const HomeFilterSection({super.key});

  @override
  State<HomeFilterSection> createState() => _HomeFilterSectionState();
}

class _HomeFilterSectionState extends State<HomeFilterSection> {
  String? _selectedBloodGroup;
  String? _selectedDistrict;
  String? _selectedSubdistrict;
  List<String> _subDistrictList = [];

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //
            Text("Are you looking for blood ?", style: TextStyle(fontSize: 14)),

            const SizedBox(height: 12),

            // Blood Group
            ButtonTheme(
              alignedDropdown: true,
              child: DropdownButtonFormField<String>(
                initialValue: _selectedBloodGroup,
                decoration: const InputDecoration(
                  labelText: 'Blood Group',
                  border: OutlineInputBorder(),
                ),
                items: AppData.bloodGroups.map((group) {
                  return DropdownMenuItem(value: group, child: Text(group));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedBloodGroup = value;
                  });
                },
              ),
            ),
            const SizedBox(height: 12),

            // District Dropdown
            _buildDistrictDropdown(),

            const SizedBox(height: 12),

            // Sub-District Dropdown
            _buildSubDistrictDropdown(),

            const SizedBox(height: 16),

            // Find Donors
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FindDonorPage(
                      bloodGroup: _selectedBloodGroup,
                      district: _selectedDistrict,
                      subdistrict: _selectedSubdistrict,
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

  //
  Widget _buildDistrictDropdown() {
    return TextFormField(
      readOnly: true,
      decoration: InputDecoration(
        // labelText: 'District',
        hintText: _selectedDistrict ?? 'Select District',
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
            builder: (context) => SearchPage(
              title: 'District',
              items: (AppData.districts.map((d) => d.name).toList()..sort()),
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
      validator: (value) {
        if (_selectedDistrict == null) {
          return 'Please select a district';
        }
        return null;
      },
    );
  }

  //
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
        // labelText: 'Subdistrict',
        hintText: _selectedSubdistrict ?? 'Select Subdistrict',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        suffixIcon: _selectedSubdistrict != null
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    _selectedSubdistrict = null;
                  });
                },
              )
            : const Icon(Icons.arrow_drop_down),
      ),
      onTap: () async {
        if (_selectedDistrict == null) return;
        final selectedValue = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                SearchPage(title: 'Subdistrict', items: subDistricts),
          ),
        );
        if (selectedValue != null) {
          setState(() {
            _selectedSubdistrict = selectedValue;
          });
        }
      },
      validator: (value) {
        if (_selectedSubdistrict == null) {
          return 'Please select a subdistrict';
        }
        return null;
      },
    );
  }
}
