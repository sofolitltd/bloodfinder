import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_data.dart';
import '../pages/search_page.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

class SubDistrictDropdownField extends StatelessWidget {
  final String? selectedDistrict;
  final String? selectedSubDistrict;
  final ValueChanged<String?> onSubDistrictChanged;
  final VoidCallback onClear;

  const SubDistrictDropdownField({
    super.key,
    required this.selectedDistrict,
    required this.selectedSubDistrict,
    required this.onSubDistrictChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final subDistricts = selectedDistrict != null
        ? AppData.districts
              .firstWhere((d) => d.name == selectedDistrict)
              .subDistricts
        : <String>[];
    return TextFormField(
      readOnly: true,
      enabled: selectedDistrict != null,
      decoration: InputDecoration(
        hintText: selectedSubDistrict ?? 'Select Subdistrict',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
        suffixIcon: selectedSubDistrict != null
            ? IconButton(
                icon: Icon(PhosphorIcons.x),
                onPressed: onClear,
              )
            : Icon(PhosphorIcons.caretDown),
      ),
      onTap: () async {
        if (selectedDistrict == null) return;
        final selectedValue = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                SearchPage(title: 'Subdistrict', items: subDistricts),
          ),
        );
        if (selectedValue != null) {
          onSubDistrictChanged(selectedValue);
        }
      },
      validator: (value) {
        if (selectedSubDistrict == null) {
          return 'Please select a subdistrict';
        }
        return null;
      },
    );
  }
}
