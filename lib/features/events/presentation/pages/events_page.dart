import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../../data/providers/repository_providers.dart';
import '../../../../data/providers/user_providers.dart';
import '../../models/blood_event.dart';
import '../widgets/create_event_sheet.dart';
import 'event_detail_page.dart';

class EventsPage extends ConsumerStatefulWidget {
  final BloodEvent? initialEvent;

  const EventsPage({super.key, this.initialEvent});

  @override
  ConsumerState<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends ConsumerState<EventsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userProvider);
    final user = userAsync.value;
    final uid = user?.uid;
    final lat = user?.latitude;
    final lon = user?.longitude;

    if (widget.initialEvent != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => EventDetailPage(event: widget.initialEvent!),
          ),
        );
      });
    }

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Events',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.red.shade700,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.red.shade700,
          tabs: const [
            Tab(text: 'My Events'),
            Tab(text: 'Nearby'),
            Tab(text: 'Other'),
          ],
        ),
      ),
      floatingActionButton: user != null && _tabController.index == 0
          ? FloatingActionButton.extended(
              heroTag: 'create_event',
              onPressed: () => showCreateEventSheet(context, ref),
              backgroundColor: Colors.red.shade600,
              icon: const Icon(PhosphorIcons.plus, color: Colors.white),
              label: const Text('Create Event',
                  style: TextStyle(color: Colors.white)),
            )
          : null,
      body: IndexedStack(
        index: _tabController.index,
        children: [
          _MyEventsTab(uid: uid),
          _NearbyEventsTab(lat: lat, lon: lon, uid: uid),
          _OtherEventsTab(uid: uid),
        ],
      ),
    );
  }
}

// ── My Events Tab ──
class _MyEventsTab extends ConsumerWidget {
  final String? uid;

  const _MyEventsTab({required this.uid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (uid == null) {
      return const Center(child: Text('Sign in to see your events.'));
    }

    final repo = ref.read(eventRepositoryProvider);
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: repo.userEventsStream(uid!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Text(
                'Something went wrong loading your events.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        final events = docs
            .map((d) => BloodEvent.fromJson({...d.data(), 'id': d.id}))
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

        return _EventsList(
          events: events,
          emptyText: 'No events created yet',
        );
      },
    );
  }
}

// ── Nearby Events Tab ──
class _NearbyEventsTab extends ConsumerWidget {
  final double? lat;
  final double? lon;
  final String? uid;

  const _NearbyEventsTab({required this.lat, required this.lon, this.uid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (lat == null || lon == null) {
      return const Center(
        child: Text('Set your location in profile to see nearby events.'),
      );
    }

    final repo = ref.read(eventRepositoryProvider);
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: repo.nearbyEventsStream(lat!, lon!, 100),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Text(
                'Something went wrong loading nearby events.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        final events = docs
            .map((d) => BloodEvent.fromJson({...d.data(), 'id': d.id}))
            .where((e) => e.organizerUid != uid)
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

        return _EventsList(
          events: events,
          emptyText: 'No blood camp events nearby',
        );
      },
    );
  }
}

// ── Other Events Tab ──
class _OtherEventsTab extends ConsumerWidget {
  final String? uid;

  const _OtherEventsTab({required this.uid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(eventRepositoryProvider);
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: repo.allEventsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Text(
                'Something went wrong loading events.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        final events = docs
            .map((d) => BloodEvent.fromJson({...d.data(), 'id': d.id}))
            .where((e) => e.organizerUid != uid)
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

        return _EventsList(
          events: events,
          emptyText: 'No other events found',
        );
      },
    );
  }
}

// ── Events List (Shared) ──
class _EventsList extends StatelessWidget {
  final List<BloodEvent> events;
  final String emptyText;

  const _EventsList({required this.events, required this.emptyText});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72.w,
              height: 72.h,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Icon(
                PhosphorIcons.calendar,
                size: 34.w,
                color: Colors.red.shade300,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              emptyText,
              style: TextStyle(
                fontSize: 17.sp,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.grey.shade200 : Colors.grey.shade800,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 96.h),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return Padding(
          padding: EdgeInsets.only(top: index == 0 ? 0 : 12.h),
          child: _EventCard(event: event),
        );
      },
    );
  }
}

// ── Event Card ──
class _EventCard extends StatelessWidget {
  final BloodEvent event;

  const _EventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dateStr = event.dateDisplay;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EventDetailPage(event: event),
        ),
      ),
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
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (event.imageUrl != null && event.imageUrl!.isNotEmpty)
              Image.network(
                event.imageUrl!,
                height: 140.h,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              )
            else
              Container(
                height: 140.h,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.red.shade700, Colors.red.shade400],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Icon(
                    PhosphorIcons.drop,
                    color: Colors.white24,
                    size: 48.w,
                  ),
                ),
              ),
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15.sp,
                      color:
                          isDark ? Colors.grey.shade200 : Colors.grey.shade800,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    event.organizerName,
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: isDark ? Colors.grey.shade400 : Colors.grey,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      Icon(PhosphorIcons.calendar,
                          size: 14.w, color: Colors.red.shade400),
                      SizedBox(width: 4.w),
                      Text(
                        dateStr,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: isDark
                              ? Colors.grey.shade400
                              : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      Icon(PhosphorIcons.mapPin,
                          size: 14.w, color: Colors.grey.shade500),
                      SizedBox(width: 4.w),
                      Expanded(
                        child: Text(
                          event.locationAddress,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: isDark
                                ? Colors.grey.shade400
                                : Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      Icon(PhosphorIcons.user,
                          size: 14.w, color: Colors.blue.shade400),
                      SizedBox(width: 4.w),
                      Text(
                        '${event.rsvpCount} attending',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.blue.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
