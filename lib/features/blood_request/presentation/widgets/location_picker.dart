import 'package:bloodfinder/core/constants/app_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../community/presentation/pages/search_page.dart';

class LocationPicker extends StatefulWidget {
  final String? initialDistrict;
  final String? initialSubdistrict;
  final ValueChanged<String?> onDistrictChanged;
  final ValueChanged<String?> onSubdistrictChanged;

  const LocationPicker({
    super.key,
    this.initialDistrict,
    this.initialSubdistrict,
    required this.onDistrictChanged,
    required this.onSubdistrictChanged,
  });

  @override
  State<LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  String? _selectedDistrict;
  String? _selectedSubdistrict;

  @override
  void initState() {
    super.initState();
    _selectedDistrict = widget.initialDistrict;
    _selectedSubdistrict = widget.initialSubdistrict;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildDistrictDropdown(),
        SizedBox(height: 1.h),
        _buildSubDistrictDropdown(),
      ],
    );
  }

  Widget _buildDistrictDropdown() {
    return TextFormField(
      readOnly: true,
      decoration: InputDecoration(
        hintText: _selectedDistrict ?? 'Select District',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
        suffixIcon: _selectedDistrict != null
            ? IconButton(
                icon: Icon(PhosphorIcons.x),
                onPressed: () {
                  setState(() {
                    _selectedDistrict = null;
                    _selectedSubdistrict = null;
                  });
                  widget.onDistrictChanged(null);
                  widget.onSubdistrictChanged(null);
                },
              )
            : Icon(PhosphorIcons.caretDown),
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
          widget.onDistrictChanged(selectedValue);
          widget.onSubdistrictChanged(null);
        }
      },
      validator: (_) =>
          _selectedDistrict == null ? 'Please select a district' : null,
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
        hintText: _selectedSubdistrict ?? 'Select Subdistrict',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
        suffixIcon: _selectedSubdistrict != null
            ? IconButton(
                icon: Icon(PhosphorIcons.x),
                onPressed: () {
                  setState(() => _selectedSubdistrict = null);
                  widget.onSubdistrictChanged(null);
                },
              )
            : Icon(PhosphorIcons.caretDown),
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
          setState(() => _selectedSubdistrict = selectedValue);
          widget.onSubdistrictChanged(selectedValue);
        }
      },
      validator: (_) =>
          _selectedSubdistrict == null ? 'Please select a subdistrict' : null,
    );
  }
}
