import 'package:bloodfinder/core/constants/app_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

class BloodGroupSelector extends StatelessWidget {
  final String? selectedBloodGroup;
  final String? selectedBag;
  final List<String> bagOptions;
  final ValueChanged<String?> onBloodGroupChanged;
  final ValueChanged<String?> onBagChanged;

  const BloodGroupSelector({
    super.key,
    this.selectedBloodGroup,
    this.selectedBag,
    required this.bagOptions,
    required this.onBloodGroupChanged,
    required this.onBagChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: 'Blood Group',
              prefixIcon: Icon(PhosphorIcons.drop, size: 20.w),
            ),
            initialValue: selectedBloodGroup,
            items: AppData.bloodGroups
                .map(
                  (e) => DropdownMenuItem(
                    value: e,
                    child: Text(e),
                  ),
                )
                .toList(),
            onChanged: onBloodGroupChanged,
            validator: (val) => val == null ? 'Required' : null,
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: 'Bag(s)',
              prefixIcon: Icon(PhosphorIcons.dropHalf, size: 20.w),
            ),
            initialValue: selectedBag,
            items: bagOptions
                .map(
                  (e) => DropdownMenuItem(
                    value: e,
                    child: Text(e),
                  ),
                )
                .toList(),
            onChanged: onBagChanged,
            validator: (val) => val == null ? 'Required' : null,
          ),
        ),
      ],
    );
  }
}
