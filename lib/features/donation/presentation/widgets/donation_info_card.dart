import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import 'package:bloodfinder/features/blood_request/models/blood_request.dart';
import 'package:bloodfinder/shared/widgets/info_tile.dart';

class DonationInfoCard extends StatelessWidget {
  final BloodRequest request;
  final bool isDark;

  DonationInfoCard({super.key, required this.request, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                children: [
                  InfoTile(
                    icon: PhosphorIcons.drop,
                    iconColor: Colors.red.shade400,
                    label: 'Blood Group',
                    value: request.bloodGroup,
                    isDark: isDark,
                  ),
                  SizedBox(height: 1.h),
                  InfoTile(
                    icon: PhosphorIcons.calendar,
                    iconColor: Colors.orange.shade400,
                    label: 'Date',
                    value: request.date,
                    isDark: isDark,
                  ),
                ],
              ),
            ),
            SizedBox(width: 1.w),
            Expanded(
              child: Column(
                children: [
                  InfoTile(
                    icon: PhosphorIcons.heartbeat,
                    iconColor: Colors.red.shade400,
                    label: 'Bags Needed',
                    value: request.bag,
                    isDark: isDark,
                  ),
                  SizedBox(height: 1.h),
                  InfoTile(
                    icon: PhosphorIcons.clock,
                    iconColor: Colors.orange.shade400,
                    label: 'Time',
                    value: request.time,
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 1.h),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.grey.shade700.withValues(alpha: 0.15)
                : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AddressTile(
                icon: PhosphorIcons.hospital,
                iconColor: Colors.grey.shade500,
                label: 'Clinic / Address',
                value: request.address,
                isDark: isDark,
              ),
              if (request.locationAddress != null &&
                  request.locationAddress!.isNotEmpty) ...[
                SizedBox(height: 8.h),
                AddressTile(
                  icon: PhosphorIcons.mapPin,
                  iconColor: Colors.grey.shade500,
                  label: 'Location',
                  value: request.locationAddress!,
                  isDark: isDark,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
