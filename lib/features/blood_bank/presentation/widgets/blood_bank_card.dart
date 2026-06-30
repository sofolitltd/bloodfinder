import 'package:cached_network_image/cached_network_image.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../models/blood_bank.dart';
import '../pages/blood_bank_detail_page.dart';

class BloodBankCard extends StatelessWidget {
  final BloodBank bloodBank;

  const BloodBankCard({super.key, required this.bloodBank});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BloodBankDetailPage(bloodBank: bloodBank),
        ),
      ),
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48.w,
                height: 48.h,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14.r),
                  color: Colors.red.shade50,
                ),
                clipBehavior: Clip.antiAlias,
                child: bloodBank.imageUrl != null &&
                        bloodBank.imageUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: bloodBank.imageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, _) => const CupertinoActivityIndicator(),
                        errorWidget: (_, _, _) => Icon(
                          Icons.local_hospital,
                          color: Colors.red.shade200,
                          size: 22.w,
                        ),
                      )
                    : Icon(
                        Icons.local_hospital,
                        color: Colors.red.shade200,
                        size: 22.w,
                      ),
              ),
              SizedBox(width: 1.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bloodBank.name,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.grey.shade200 : Colors.grey.shade800,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 8.h),
                    Row(
                      children: [
                        Icon(PhosphorIcons.hospital,
                            size: 14.w, color: isDark ? Colors.grey.shade500 : Colors.grey.shade400),
                        SizedBox(width: 6.w),
                        Expanded(
                          child: Text(
                            bloodBank.address,
                            style: TextStyle(
                                fontSize: 13.sp,
                                color: isDark ? Colors.grey.shade400 : Colors.grey.shade700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        Icon(PhosphorIcons.mapPin,
                            size: 14.w, color: isDark ? Colors.grey.shade500 : Colors.grey.shade400),
                        SizedBox(width: 6.w),
                        Expanded(
                          child: Text(
                            bloodBank.locationAddress ?? 'Location not set',
                            style: TextStyle(
                                fontSize: 13.sp,
                                color: isDark ? Colors.grey.shade400 : Colors.grey.shade700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        Icon(PhosphorIcons.phoneCall,
                            size: 14.w, color: isDark ? Colors.grey.shade500 : Colors.grey.shade400),
                        SizedBox(width: 6.w),
                        Text(
                          bloodBank.mobile1,
                          style: TextStyle(
                              fontSize: 13.sp,
                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade700),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.only(left: 8.w),
                child: Icon(
                  PhosphorIcons.caretRight,
                  size: 16.w,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
