import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import 'image_picker_section.dart';
import '../../../../shared/widgets/map_location_picker_page.dart';
import '../../../../shared/models/social_media_link.dart';
import '../../../../shared/widgets/social_media_input.dart';

class FormFieldsSection extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController mobileController;
  final TextEditingController addressController;
  final List<SocialMediaLink> socialMediaLinks;
  final ValueChanged<List<SocialMediaLink>> onSocialLinksChanged;
  final double? selectedLatitude;
  final double? selectedLongitude;
  final String? selectedLocationAddress;
  final XFile? pickedImage;
  final void Function(double lat, double lng, String address) onLocationPicked;
  final VoidCallback onPickImage;
  final VoidCallback onClearImage;

  const FormFieldsSection({
    super.key,
    required this.nameController,
    required this.mobileController,
    required this.addressController,
    required this.socialMediaLinks,
    required this.onSocialLinksChanged,
    required this.selectedLatitude,
    required this.selectedLongitude,
    required this.selectedLocationAddress,
    required this.pickedImage,
    required this.onLocationPicked,
    required this.onPickImage,
    required this.onClearImage,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Community Information',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16.sp,
          ),
        ),

        SizedBox(height: 16.h),

        // Community Name
        TextFormField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Community name',
            hintText: 'Enter community name',
          ),
          keyboardType: TextInputType.name,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a community name';
            }
            return null;
          },
        ),
        SizedBox(height: 16.h),

        // Mobile Number
        TextFormField(
          controller: mobileController,
          decoration: const InputDecoration(
            labelText: 'Admin Mobile',
            hintText: 'Enter mobile number',
          ),
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a mobile number';
            }
            return null;
          },
        ),
        SizedBox(height: 16.h),

        // Address
        TextFormField(
          controller: addressController,
          decoration: const InputDecoration(
            labelText: 'Address',
            hintText: 'Enter community address',
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter the address';
            }
            return null;
          },
        ),
                    SizedBox(height: 16.h),

                    // ── Map Location Picker ─────────────────────────────────────────────
        FormField<double>(
          validator: (_) =>
              selectedLatitude == null ? 'Please pick a location' : null,
          builder: (state) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () async {
                    final result = await MapLocationPickerPage.show(context);
                    if (result != null) {
                      onLocationPicked(
                        result.latitude,
                        result.longitude,
                        result.displayAddress,
                      );
                      state.didChange(result.latitude);
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 12.w, vertical: 14.h),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: state.hasError
                            ? Theme.of(context).colorScheme.error
                            : Colors.grey.shade400,
                      ),
                      borderRadius: BorderRadius.circular(8.r),
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey.shade900
                          : Colors.grey.shade50,
                    ),
                    child: Row(
                      children: [
                        Icon(PhosphorIcons.mapPin,
                            color: selectedLatitude != null
                                ? Colors.red.shade600
                                : Colors.grey.shade600),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                selectedLatitude != null
                                    ? 'Location Picked'
                                    : 'Pick Community Location on Map',
                                style: TextStyle(
                                  color: selectedLatitude != null
                                      ? (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87)
                                      : Colors.grey.shade600,
                                  fontWeight: selectedLatitude != null
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                              if (selectedLocationAddress != null &&
                                  selectedLocationAddress!.isNotEmpty) ...[
                                SizedBox(height: 4.h),
                                Text(
                                  selectedLocationAddress!,
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: Colors.grey.shade600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (selectedLatitude != null)
                          Icon(PhosphorIcons.checkCircle,
                              color: Colors.green.shade600),
                      ],
                    ),
                  ),
                ),
                if (state.hasError)
                  Padding(
                    padding: EdgeInsets.only(left: 12.w, top: 8.h),
                    child: Text(
                      state.errorText!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 12.sp,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),

        SizedBox(height: 16.h),

        Text(
          'Social Media Links',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp),
        ),
        SizedBox(height: 8.h),
        SocialMediaInput(
          initialLinks: socialMediaLinks,
          onLinksChanged: onSocialLinksChanged,
        ),

        SizedBox(height: 24.h),

        Text(
          'Community Image',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16.sp,
          ),
        ),
        SizedBox(height: 16.h),

        //Image Picker
        ImagePickerSection(
          pickedImage: pickedImage,
          onPickImage: onPickImage,
          onClearImage: onClearImage,
        ),
      ],
    );
  }
}
