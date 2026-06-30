import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:bloodfinder/data/providers/repository_providers.dart';
import 'package:bloodfinder/features/blood_request/models/blood_request.dart';

class DonationPosterCard extends ConsumerWidget {
  final BloodRequest request;

  DonationPosterCard({super.key, required this.request});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return FutureBuilder(
      future: ref.read(userRepositoryProvider).getUser(request.uid),
      builder: (context, userSnapshot) {
        final posterName = userSnapshot.hasData && userSnapshot.data!.exists
            ? () {
                final data = userSnapshot.data!.data() as Map<String, dynamic>;
                return '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}'.trim();
              }()
            : 'Unknown';
        final posterImage = userSnapshot.hasData && userSnapshot.data!.exists
            ? (userSnapshot.data!.data() as Map<String, dynamic>)['image'] ?? ''
            : '';

        return Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.red.shade100,
              backgroundImage: posterImage.isNotEmpty
                  ? CachedNetworkImageProvider(posterImage)
                  : null,
              child: posterImage.isEmpty
                  ? Text(
                      posterName.isNotEmpty ? posterName[0].toUpperCase() : '?',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade600,
                      ),
                    )
                  : null,
            ),
            SizedBox(width: 1.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    posterName,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.grey.shade200 : Colors.grey.shade800,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    DateFormat('dd MMM yyy - hh:mm a').format(request.createdAt),
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
