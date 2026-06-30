import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../../shared/widgets/map_location_picker_page.dart';
import 'blood_group_selector.dart';

class RequestForm extends StatefulWidget {
  final TextEditingController nameController;
  final TextEditingController mobileController;
  final TextEditingController addressController;
  final TextEditingController noteController;
  final String? selectedBloodGroup;
  final String? selectedBag;
  final List<String> bagOptions;
  final DateTime? selectedDate;
  final TimeOfDay? selectedTime;
  final bool isLoading;
  final VoidCallback onSubmit;
  final bool isEditing;
  final bool hasChanges;
  final ValueChanged<String?> onBloodGroupChanged;
  final ValueChanged<String?> onBagChanged;
  final ValueChanged<DateTime?> onDateChanged;
  final ValueChanged<TimeOfDay?> onTimeChanged;

  final double? selectedLatitude;
  final double? selectedLongitude;
  final String? locationAddress;
  final void Function(double lat, double lng, String address) onLocationPicked;

  RequestForm({
    super.key,
    required this.nameController,
    required this.mobileController,
    required this.addressController,
    required this.noteController,
    this.selectedBloodGroup,
    this.selectedBag,
    required this.bagOptions,
    this.selectedDate,
    this.selectedTime,
    required this.isLoading,
    required this.onSubmit,
    required this.isEditing,
    required this.hasChanges,
    required this.onBloodGroupChanged,
    required this.onBagChanged,
    required this.onDateChanged,
    required this.onTimeChanged,
    this.selectedLatitude,
    this.selectedLongitude,
    this.locationAddress,
    required this.onLocationPicked,
  });

  @override
  State<RequestForm> createState() => _RequestFormState();
}

class _RequestFormState extends State<RequestForm> {
  Future<void> _openMapPicker() async {
    final result = await MapLocationPickerPage.show(
      context,
      initialLatitude: widget.selectedLatitude,
      initialLongitude: widget.selectedLongitude,
    );
    if (result != null) {
      widget.onLocationPicked(
        result.latitude,
        result.longitude,
        result.displayAddress,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasLocation = widget.selectedLatitude != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          icon: PhosphorIcons.user,
          title: 'Patient Information',
        ),
        SizedBox(height: 12.h),
        _SectionCard(
          children: [
            TextFormField(
              controller: widget.nameController,
              decoration: InputDecoration(
                labelText: 'Patient Name',
                hintText: 'Enter patient name',
                prefixIcon: Icon(PhosphorIcons.user, size: 20.w),
              ),
              validator: (val) =>
                  (val == null || val.trim().isEmpty) ? 'Required' : null,
            ),
            SizedBox(height: 14.h),
            TextFormField(
              controller: widget.mobileController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Contact Number',
                hintText: 'Enter contact number',
                prefixIcon: Icon(PhosphorIcons.phone, size: 20.w),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Required';
                return null;
              },
            ),
          ],
        ),

        SizedBox(height: 24.h),

        _SectionHeader(
          icon: PhosphorIcons.drop,
          title: 'Blood Details',
        ),
        SizedBox(height: 12.h),
        _SectionCard(
          children: [
            BloodGroupSelector(
              selectedBloodGroup: widget.selectedBloodGroup,
              selectedBag: widget.selectedBag,
              bagOptions: widget.bagOptions,
              onBloodGroupChanged: widget.onBloodGroupChanged,
              onBagChanged: widget.onBagChanged,
            ),
          ],
        ),

        SizedBox(height: 24.h),

        _SectionHeader(
          icon: PhosphorIcons.hospital,
          title: 'Location',
        ),
        SizedBox(height: 12.h),
        _SectionCard(
          children: [
            TextFormField(
              controller: widget.addressController,
              minLines: 1,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Hospital / Clinic Name',
                hintText: 'Enter hospital or clinic name',
                prefixIcon: Icon(PhosphorIcons.hospital, size: 20.w),
              ),
              validator: (val) =>
                  (val == null || val.trim().isEmpty) ? 'Required' : null,
            ),
            SizedBox(height: 14.h),
            FormField<double>(
              validator: (_) => widget.selectedLatitude == null
                  ? 'Please pick a location'
                  : null,
              builder: (state) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: _openMapPicker,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 14.w, vertical: 14.h),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: state.hasError
                                ? Theme.of(context).colorScheme.error
                                : Colors.red.shade200,
                            width: state.hasError ? 1.5 : 1,
                          ),
                          borderRadius: BorderRadius.circular(12.r),
                          color: Colors.red.shade50,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              PhosphorIcons.mapPin,
                              size: 20,
                              color: hasLocation
                                  ? Colors.red.shade600
                                  : Colors.red.shade300,
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Text(
                                hasLocation
                                    ? (widget.locationAddress ??
                                        'Location selected')
                                    : 'Pick location on map',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: hasLocation
                                      ? FontWeight.w500
                                      : FontWeight.normal,
                                  color: hasLocation
                                      ? Colors.grey.shade800
                                      : Colors.grey.shade500,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Icon(
                              hasLocation
                                  ? PhosphorIcons.pencilSimple
                                  : PhosphorIcons.mapPinArea,
                              size: 18,
                              color: Colors.red.shade400,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (state.hasError)
                      Padding(
                        padding: EdgeInsets.only(top: 6.h, left: 12.w),
                        child: Text(
                          state.errorText!,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),

        SizedBox(height: 24.h),

        _SectionHeader(
          icon: PhosphorIcons.calendar,
          title: 'Date & Time',
        ),
        SizedBox(height: 12.h),
        _SectionCard(
          children: [
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                        initialDate:
                            widget.selectedDate ?? DateTime.now(),
                      );
                      if (date != null) {
                        widget.onDateChanged(date);
                      }
                    },
                    borderRadius: BorderRadius.circular(12.r),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 14.w, vertical: 14.h),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            PhosphorIcons.calendarBlank,
                            size: 20,
                            color: widget.selectedDate != null
                                ? Colors.red.shade600
                                : Colors.grey.shade400,
                          ),
                          SizedBox(width: 10.w),
                          Text(
                            widget.selectedDate == null
                                ? 'Select Date'
                                : DateFormat('d/M/yyy')
                                    .format(widget.selectedDate!),
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: widget.selectedDate != null
                                  ? Colors.grey.shade800
                                  : Colors.grey.shade500,
                              fontWeight: widget.selectedDate != null
                                  ? FontWeight.w500
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime:
                            widget.selectedTime ?? TimeOfDay.now(),
                      );
                      if (time != null) {
                        widget.onTimeChanged(time);
                      }
                    },
                    borderRadius: BorderRadius.circular(12.r),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 14.w, vertical: 14.h),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            PhosphorIcons.clock,
                            size: 20,
                            color: widget.selectedTime != null
                                ? Colors.red.shade600
                                : Colors.grey.shade400,
                          ),
                          SizedBox(width: 10.w),
                          Text(
                            widget.selectedTime == null
                                ? 'Select Time'
                                : widget.selectedTime!.format(context),
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: widget.selectedTime != null
                                  ? Colors.grey.shade800
                                  : Colors.grey.shade500,
                              fontWeight: widget.selectedTime != null
                                  ? FontWeight.w500
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),

        SizedBox(height: 24.h),

        _SectionHeader(
          icon: PhosphorIcons.notePencil,
          title: 'Note (optional)',
        ),
        SizedBox(height: 12.h),
        _SectionCard(
          children: [
            TextFormField(
              controller: widget.noteController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Add any additional information...',
              ),
            ),
          ],
        ),

        SizedBox(height: 32.h),
        SizedBox(
          width: double.infinity,
          height: 52.h,
          child: ElevatedButton(
            onPressed: (widget.isLoading || (widget.isEditing && !widget.hasChanges))
                ? null
                : widget.onSubmit,
            style: ElevatedButton.styleFrom(elevation: 0),
            child: widget.isLoading
                ? SizedBox(
                    height: 22.h,
                    width: 22.w,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Text(
                    widget.isEditing ? 'Update Request' : 'Submit Request',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28.w,
          height: 28.h,
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(icon, size: 15, color: Colors.red.shade600),
        ),
        SizedBox(width: 8.w),
        Text(
          title,
          style: TextStyle(
            fontSize: 15.sp,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final List<Widget> children;

  const _SectionCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}
