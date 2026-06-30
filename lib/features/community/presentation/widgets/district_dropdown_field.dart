import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_data.dart';
import '../pages/search_page.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

class DistrictDropdownField extends StatelessWidget {
  final String? selectedDistrict;
  final ValueChanged<String?> onDistrictChanged;
  final VoidCallback onClear;

  const DistrictDropdownField({
    super.key,
    required this.selectedDistrict,
    required this.onDistrictChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      readOnly: true,
      decoration: InputDecoration(
        hintText: selectedDistrict ?? 'Select District',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
        suffixIcon: selectedDistrict != null
            ? IconButton(
                icon: Icon(PhosphorIcons.x),
                onPressed: onClear,
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
          onDistrictChanged(selectedValue);
        }
      },
      validator: (value) {
        if (selectedDistrict == null) {
          return 'Please select a district';
        }
        return null;
      },
    );
  }
}
