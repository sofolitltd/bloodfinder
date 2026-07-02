import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../../data/providers/repository_providers.dart';
import '../../../../data/providers/user_providers.dart';
import '../../../../shared/widgets/location_picker_header.dart';
import '../../../../shared/widgets/map_location_picker_page.dart';
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

  // ── Nearby tab state ──
  final List<BloodEvent> _nearbyEvents = [];
  DocumentSnapshot<Map<String, dynamic>>? _nearbyLastDoc;
  bool _nearbyLoading = false;
  bool _nearbyHasMore = true;
  late ScrollController _nearbyScrollCtrl;

  // ── Other (country) tab state ──
  final List<BloodEvent> _otherEvents = [];
  DocumentSnapshot<Map<String, dynamic>>? _otherLastDoc;
  bool _otherLoading = false;
  bool _otherHasMore = true;
  late ScrollController _otherScrollCtrl;

  // ── Filter state ──
  double _radiusInKm = 25.0;
  bool _showFilter = false;
  double? _latitude;
  double? _longitude;
  String? _locationAddress;

  // ── Country state ──
  String? _selectedCountry;
  bool _countryInitialized = false;

  // ── Tab constants (for readability) ──
  static const int _tabMyEvents = 0;
  static const int _tabNearby = 1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
    _nearbyScrollCtrl = ScrollController()..addListener(_onNearbyScroll);
    _otherScrollCtrl = ScrollController()..addListener(_onOtherScroll);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nearbyScrollCtrl.dispose();
    _otherScrollCtrl.dispose();
    super.dispose();
  }

  // ── Location picker (reused by filter) ──
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
      _resetNearby();
    }
  }

  void _resetNearby() {
    _nearbyEvents.clear();
    _nearbyLastDoc = null;
    _nearbyHasMore = true;
    _loadNearbyEvents();
  }

  Future<void> _loadNearbyEvents() async {
    if (_nearbyLoading || !_nearbyHasMore ||
        _latitude == null || _longitude == null) return;
    setState(() => _nearbyLoading = true);

    final repo = ref.read(eventRepositoryProvider);
    try {
      final snap = await repo.getPaginatedNearbyEvents(
        _latitude!,
        _longitude!,
        _radiusInKm,
        15,
        startAfter: _nearbyLastDoc,
      );
      if (!mounted) return;
      setState(() {
        _nearbyHasMore = snap.docs.length >= 15;
        _nearbyLastDoc =
            snap.docs.isNotEmpty ? snap.docs.last : _nearbyLastDoc;
        for (final doc in snap.docs) {
          _nearbyEvents.add(
            BloodEvent.fromJson({...doc.data(), 'id': doc.id}),
          );
        }
        _nearbyLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _nearbyLoading = false);
    }
  }

  Future<void> _loadOtherEvents() async {
    if (_otherLoading || !_otherHasMore || _selectedCountry == null) return;
    setState(() => _otherLoading = true);

    final repo = ref.read(eventRepositoryProvider);
    try {
      final snap = await repo.getPaginatedEventsByCountry(
        _selectedCountry!,
        15,
        startAfter: _otherLastDoc,
      );
      if (!mounted) return;
      setState(() {
        _otherHasMore = snap.docs.length >= 15;
        _otherLastDoc =
            snap.docs.isNotEmpty ? snap.docs.last : _otherLastDoc;
        for (final doc in snap.docs) {
          _otherEvents.add(
            BloodEvent.fromJson({...doc.data(), 'id': doc.id}),
          );
        }
        _otherLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _otherLoading = false);
    }
  }

  void _onNearbyScroll() {
    if (_nearbyScrollCtrl.position.pixels >=
        _nearbyScrollCtrl.position.maxScrollExtent - 200) {
      _loadNearbyEvents();
    }
  }

  void _onOtherScroll() {
    if (_otherScrollCtrl.position.pixels >=
        _otherScrollCtrl.position.maxScrollExtent - 200) {
      _loadOtherEvents();
    }
  }

  // ── Country options for the dropdown ──
  List<String> _getCountryOptions() {
    final userAsync = ref.read(userProvider);
    final user = userAsync.value;
    final userCountry = user?.country ?? '';
    final countries = <String>{};
    if (userCountry.isNotEmpty) countries.add(userCountry);
    for (final e in _otherEvents) {
      if (e.country.isNotEmpty) countries.add(e.country);
    }
    if (countries.isEmpty) {
      return ['Bangladesh', 'India', 'USA', 'UK', 'Canada'];
    }
    return countries.toList()..sort();
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userProvider);
    final user = userAsync.value;
    final uid = user?.uid;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Set default location from user profile (once)
    if (user != null && _latitude == null && _longitude == null) {
      if (user.latitude != null && user.longitude != null) {
        _latitude = user.latitude;
        _longitude = user.longitude;
        _locationAddress = user.locationAddress;
        WidgetsBinding.instance.addPostFrameCallback((_) => _resetNearby());
      }
    }

    // Set default country from user profile (once)
    if (user != null && !_countryInitialized) {
      _countryInitialized = true;
      final country = user.country;
      if (country != null && country.isNotEmpty) {
        _selectedCountry = country;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _otherEvents.clear();
          _otherLastDoc = null;
          _otherHasMore = true;
          _loadOtherEvents();
        });
      }
    }

    // Navigate directly to initial event detail
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
        actions: [
          // Filter icon – only on Nearby tab
          if (_latitude != null && _tabController.index == _tabNearby)
            IconButton(
              icon: Icon(
                PhosphorIcons.funnel,
                size: 20.w,
                color: _showFilter ? Colors.red.shade600 : null,
              ),
              tooltip: _showFilter ? 'Hide filters' : 'Show filters',
              onPressed: () =>
                  setState(() => _showFilter = !_showFilter),
            ),
        ],
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
      floatingActionButton: user != null && _tabController.index == _tabMyEvents
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
          // ── Tab 0: My Events (stream, unchanged) ──
          _MyEventsTab(uid: uid),

          // ── Tab 1: Nearby (paginated + filter) ──
          _buildNearbyTab(isDark: isDark),

          // ── Tab 2: Other (country-based, paginated) ──
          _buildOtherTab(isDark: isDark),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  Nearby Tab
  // ─────────────────────────────────────────────
  Widget _buildNearbyTab({required bool isDark}) {
    if (_latitude == null || _longitude == null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(PhosphorIcons.mapPinLine,
                  size: 48.w, color: Colors.grey.shade300),
              SizedBox(height: 8.h),
              Text(
                'Set your location to see nearby events',
                style: TextStyle(fontSize: 16.sp, color: Colors.grey.shade500),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12.h),
              ElevatedButton.icon(
                onPressed: _openLocationPicker,
                icon: Icon(Icons.location_on, size: 20.w),
                label: const Text('Set Location'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Animated filter panel
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: _showFilter
              ? LocationPickerHeader(
                  locationAddress: _locationAddress,
                  radiusInKm: _radiusInKm,
                  onOpenLocationPicker: _openLocationPicker,
                  onRadiusChanged: (val) =>
                      setState(() => _radiusInKm = val),
                  onRadiusChangeEnd: _resetNearby,
                )
              : const SizedBox.shrink(),
        ),
        // Events list
        Expanded(
          child: _buildEventsList(
            events: _nearbyEvents,
            isLoading: _nearbyLoading,
            hasMore: _nearbyHasMore,
            scrollController: _nearbyScrollCtrl,
            emptyText: 'No blood camp events nearby',
            onLocationMissing: () => _openLocationPicker(),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  //  Other (country) Tab
  // ─────────────────────────────────────────────
  Widget _buildOtherTab({required bool isDark}) {
    if (_selectedCountry == null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Text(
            'Set your country in profile to see events.',
            style: TextStyle(fontSize: 16.sp, color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Column(
      children: [
        // Country filter row
        Container(
          padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0),
          child: Row(
            children: [
              Icon(PhosphorIcons.globe,
                  size: 18.w, color: Colors.grey.shade600),
              SizedBox(width: 8.w),
              Text(
                'Country:',
                style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade600),
              ),
              SizedBox(width: 8.w),
              DropdownButton<String>(
                value: _selectedCountry,
                underline: const SizedBox(),
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey.shade200 : Colors.grey.shade800,
                ),
                onChanged: (val) {
                  if (val != null && val != _selectedCountry) {
                    setState(() {
                      _selectedCountry = val;
                      _otherEvents.clear();
                      _otherLastDoc = null;
                      _otherHasMore = true;
                    });
                    _loadOtherEvents();
                  }
                },
                items: _getCountryOptions().map((c) {
                  return DropdownMenuItem(value: c, child: Text(c));
                }).toList(),
              ),
            ],
          ),
        ),
        // Events list
        Expanded(
          child: _buildEventsList(
            events: _otherEvents,
            isLoading: _otherLoading,
            hasMore: _otherHasMore,
            scrollController: _otherScrollCtrl,
            emptyText: 'No events found in $_selectedCountry',
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  //  Shared Events List
  // ─────────────────────────────────────────────
  Widget _buildEventsList({
    required List<BloodEvent> events,
    required bool isLoading,
    required bool hasMore,
    required ScrollController scrollController,
    required String emptyText,
    VoidCallback? onLocationMissing,
  }) {
    if (events.isEmpty && !isLoading) {
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
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            if (onLocationMissing != null) ...[
              SizedBox(height: 16.h),
              ElevatedButton.icon(
                onPressed: onLocationMissing,
                icon: Icon(Icons.location_on, size: 20.w),
                label: const Text('Set Location'),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      controller: scrollController,
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 96.h),
      itemCount: events.length + (isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == events.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          );
        }
        final event = events[index];
        return Padding(
          padding: EdgeInsets.only(top: index == 0 ? 0 : 12.h),
          child: _EventCard(event: event),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════
//  My Events Tab (unchanged)
// ═══════════════════════════════════════════════
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

// ═══════════════════════════════════════════════
//  Events List (shared between tabs)
// ═══════════════════════════════════════════════
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

// ═══════════════════════════════════════════════
//  Event Card (unchanged)
// ═══════════════════════════════════════════════
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
                      color: isDark
                          ? Colors.grey.shade200
                          : Colors.grey.shade800,
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
                      if (event.country.isNotEmpty) ...[
                        SizedBox(width: 12.w),
                        Icon(PhosphorIcons.globe,
                            size: 14.w, color: Colors.grey.shade400),
                        SizedBox(width: 4.w),
                        Text(
                          event.country,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
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
