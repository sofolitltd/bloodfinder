import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../../data/providers/repository_providers.dart';
import '../../../../data/providers/user_providers.dart';
import '../../../events/models/blood_event.dart';
import '../../../events/presentation/pages/events_page.dart';

class HomeUpcomingEventsSection extends ConsumerWidget {
  const HomeUpcomingEventsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final userAsync = ref.watch(userProvider);
    final user = userAsync.value;
    final lat = user?.latitude;
    final lon = user?.longitude;

    if (lat == null || lon == null) return const SizedBox.shrink();

    final repo = ref.read(eventRepositoryProvider);
    final stream = repo.nearbyEventsStream(lat, lon, 100);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return const SizedBox.shrink();

        final events = docs
            .map((d) => BloodEvent.fromJson({...d.data(), 'id': d.id}))
            .where((e) => e.eventDate.isAfter(DateTime.now()))
            .take(5)
            .toList();

        if (events.isEmpty) return const SizedBox.shrink();

        final isDark = theme.brightness == Brightness.dark;

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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    spacing: 10,
                    children: [
                      Container(
                        width: 40.w,
                        height: 40.h,
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Icon(
                          PhosphorIcons.calendar,
                          color: Colors.red.shade500,
                          size: 22.w,
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Upcoming Blood Camps',
                            style: TextStyle(
                              fontSize: 17.sp,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.grey.shade200 : Colors.grey.shade800,
                            ),
                          ),
                          Text(
                            'Events near you',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const EventsPage()),
                    ),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                      visualDensity: VisualDensity.compact,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'See All',
                      style: TextStyle(
                        color: Colors.red.shade600,
                        fontWeight: FontWeight.w600,
                        fontSize: 13.sp,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),

              // Event cards
              SizedBox(
                height: 210.h,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: events.length,
                  separatorBuilder: (_, __) => SizedBox(width: 12.w),
                  itemBuilder: (context, index) {
                    final event = events[index];
                    final dateStr = event.dateDisplay;
                    return GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EventsPage(initialEvent: event),
                        ),
                      ),
                      child: Container(
                        width: 180.w,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: isDark
                                ? Colors.grey.shade700.withValues(alpha: 0.3)
                                : Colors.grey.shade200,
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 12,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(12)),
                              child: Container(
                                height: 110.h,
                                width: double.infinity,
                                color: Colors.red.shade50,
                                child: event.imageUrl != null &&
                                        event.imageUrl!.isNotEmpty
                                    ? Image.network(
                                        event.imageUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            _defaultEventImage(theme),
                                      )
                                    : _defaultEventImage(theme),
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.all(10.w),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      event.title,
                                      style: TextStyle(
                                        fontSize: 13.sp,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.grey.shade200 : Colors.grey.shade800,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(height: 6.h),
                                    Row(
                                      children: [
                                        Icon(PhosphorIcons.calendar,
                                            size: 12.w,
                                            color: Colors.red.shade400),
                                        SizedBox(width: 4.w),
                                        Text(
                                          dateStr,
                                          style: TextStyle(
                                            fontSize: 11.sp,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                        const Spacer(),
                                        Icon(PhosphorIcons.user,
                                            size: 12.w,
                                            color: Colors.blue.shade400),
                                        SizedBox(width: 4.w),
                                        Text(
                                          '${event.rsvpCount}',
                                          style: TextStyle(
                                            fontSize: 11.sp,
                                            color: Colors.blue.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Spacer(),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: Text(
                                        'View details',
                                        style: TextStyle(
                                          fontSize: 11.sp,
                                          color: Colors.red.shade600,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _defaultEventImage(ThemeData theme) {
    return Center(
      child: Icon(
        PhosphorIcons.drop,
        size: 32.w,
        color: Colors.red.shade300,
      ),
    );
  }
}
