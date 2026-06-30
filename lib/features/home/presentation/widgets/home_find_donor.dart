import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../../core/constants/app_data.dart';
import '../../../donation/presentation/pages/find_donor_page.dart';
import '../../../../shared/widgets/map_location_picker_page.dart';

class HomeFindDonorSection extends StatefulWidget {
  const HomeFindDonorSection({super.key});

  @override
  State<HomeFindDonorSection> createState() => _HomeFindDonorSectionState();
}

class _HomeFindDonorSectionState extends State<HomeFindDonorSection> {
  String? _selectedBloodGroup;

  double? _latitude;
  double? _longitude;
  String? _locationAddress;
  double _radiusInKm = 25.0;

  Future<void> _openLocationPicker() async {
    final result = await MapLocationPickerPage.show(
      context,
      initialLatitude: _latitude,
      initialLongitude: _longitude,
    );
    if (result != null && mounted) {
      setState(() {
        _latitude = result.latitude;
        _longitude = result.longitude;
        _locationAddress = result.displayAddress;
      });
    }
  }

  void _search() {
    if (_selectedBloodGroup == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a blood group'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        ),
      );
      return;
    }
    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please set a search location on the map'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FindDonorPage(
          bloodGroup: _selectedBloodGroup!,
          latitude: _latitude!,
          longitude: _longitude!,
          radiusInKm: _radiusInKm,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bool hasLocation = _latitude != null && _longitude != null;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isDark ? Colors.transparent : Colors.grey.shade200,
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            spacing: 10,
            children: [
              Container(
                width: 40.w,
                height: 48.h,
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  PhosphorIcons.drop,
                  color: Colors.red.shade500,
                  size: 22.w,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Find a Blood Donor',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.grey.shade200 : Colors.grey.shade800,
                    ),
                  ),
                  Text(
                    'Search for donors near you',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 20.h),

          // Blood Group
          ButtonTheme(
            alignedDropdown: true,
            child: DropdownButtonFormField<String>(
              initialValue: _selectedBloodGroup,
              decoration: InputDecoration(
                labelText: 'Blood Group *',
                prefixIcon: Icon(PhosphorIcons.dropHalfBottom, size: 20.w),
              ),
              items: AppData.bloodGroups
                  .map((bg) => DropdownMenuItem(value: bg, child: Text(bg)))
                  .toList(),
              onChanged: (val) => setState(() => _selectedBloodGroup = val),
            ),
          ),
          SizedBox(height: 16.h),

          // Location picker
          InkWell(
            onTap: _openLocationPicker,
            borderRadius: BorderRadius.circular(12.r),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: hasLocation ? Colors.green.shade300 : Colors.grey.shade300,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    hasLocation ? Icons.location_on : Icons.location_off,
                    color: hasLocation ? Colors.green.shade600 : Colors.grey,
                    size: 20.w,
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      hasLocation
                          ? (_locationAddress ?? 'Location set')
                          : 'Tap to set search location',
                      style: TextStyle(
                        color: hasLocation ? Colors.black87 : Colors.grey.shade600,
                        fontSize: 14.sp,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    PhosphorIcons.mapPin,
                    color: Colors.red.shade400,
                    size: 20.w,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16.h),

          // Radius slider
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Search Radius',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                  fontSize: 14.sp,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  '${_radiusInKm.round()} km',
                  style: TextStyle(
                    color: Colors.red.shade600,
                    fontWeight: FontWeight.bold,
                    fontSize: 13.sp,
                  ),
                ),
              ),
            ],
          ),
          Slider(
            value: _radiusInKm,
            min: 5.0,
            max: 200.0,
            divisions: 39,
            label: '${_radiusInKm.round()} km',
            activeColor: Colors.red.shade500,
            inactiveColor: Colors.red.shade100,
            onChanged: (val) => setState(() => _radiusInKm = val),
          ),
          SizedBox(height: 4.h),

          // Search button
          SizedBox(
            width: double.infinity,
            height: 50.h,
            child: ElevatedButton(
              onPressed: _search,
              style: ElevatedButton.styleFrom(elevation: 0),
              child: Text(
                'Find Donors',
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
