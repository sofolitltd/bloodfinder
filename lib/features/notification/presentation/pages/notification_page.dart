import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../models/notification.dart';
import '../../models/announcement_model.dart';

import '../../../../data/providers/notification_provider.dart';
import '../../../../data/providers/repository_providers.dart';

import '../../../../routes/router_config.dart';

class NotificationPage extends ConsumerStatefulWidget {
  final String userId;

  const NotificationPage({super.key, required this.userId});

  @override
  ConsumerState<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends ConsumerState<NotificationPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Notification pagination
  final ScrollController _scrollCtrl = ScrollController();
  DocumentSnapshot<Map<String, dynamic>>? _lastDoc;
  bool _isLoadingMore = false;
  List<NotificationModel> _notifications = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore) return;
    _isLoadingMore = true;

    final repo = ref.read(notificationRepositoryProvider);
    final stream = repo.getNotifications(
      userId: widget.userId,
      startAfter: _lastDoc,
    );
    final snapshot = await stream.first;
    if (snapshot.isNotEmpty) {
      _lastDoc = await FirebaseFirestore.instance
          .collection('notifications')
          .doc(snapshot.last.id)
          .get();
      _notifications.addAll(snapshot);
      setState(() {});
    }

    _isLoadingMore = false;
  }

  @override
  Widget build(BuildContext context) {
    final asyncNotifications = ref.watch(
      notificationsStreamProvider(widget.userId),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.red.shade700,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.red.shade700,
          tabs: const [
            Tab(text: 'Notifications'),
            Tab(text: 'Announcements'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Personal notifications
          asyncNotifications.when(
            data: (list) {
              _notifications = list;

              if (_notifications.isEmpty) {
                return _emptyState('No notifications yet.');
              }

              return ListView.separated(
                separatorBuilder: (_, _) => Divider(height: 10.h),
                controller: _scrollCtrl,
                itemCount: _notifications.length,
                padding: .symmetric(vertical: 8.h),
                itemBuilder: (context, index) {
                  final n = _notifications[index];

                  return Card(
                    color: n.read ? null : Colors.red.shade50,
                    child: ListTile(
                      title: Row(
                        children: [
                          Expanded(child: Text(n.title)),
                          Text(
                            timeAgo(n.createdAt),
                            style: TextStyle(fontSize: 12.sp),
                          ),
                        ],
                      ),
                      subtitle: Text(n.body),
                      onTap: () {
                        routerConfig.push(
                          '/notification-detail',
                          extra: n,
                        );
                      },
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),

          // Tab 2: Admin announcements
          _announcementsTab(),
        ],
      ),
    );
  }

  Widget _announcementsTab() {
    final dataSource = ref.watch(firebaseDataSourceProvider);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: dataSource
          .collection('announcements')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return _emptyState('No announcements yet.');
        }

        // Extract unique country values for the filter dropdown
        final countries = <String>{};
        for (final doc in docs) {
          final b = AnnouncementModel.fromDoc(doc);
          if (b.country != null && b.country!.isNotEmpty) {
            countries.add(b.country!);
          }
        }
        final sortedCountries = countries.toList()..sort();

        return _AnnouncementsList(
          docs: docs,
          countries: sortedCountries,
        );
      },
    );
  }

  Widget _emptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 48.w,
            color: Colors.grey.shade300,
          ),
          SizedBox(height: 8.h),
          Text(
            message,
            style: TextStyle(
              fontSize: 16.sp,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Separate StatefulWidget to hold the country filter state for announcements.
class _AnnouncementsList extends StatefulWidget {
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;
  final List<String> countries;

  const _AnnouncementsList({
    required this.docs,
    required this.countries,
  });

  @override
  State<_AnnouncementsList> createState() => _AnnouncementsListState();
}

class _AnnouncementsListState extends State<_AnnouncementsList> {
  String? _selectedCountry;

  Widget _buildEmpty(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 48.w,
            color: Colors.grey.shade300,
          ),
          SizedBox(height: 8.h),
          Text(
            message,
            style: TextStyle(
              fontSize: 16.sp,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Filter broadcasts
    final filtered = _selectedCountry == null || _selectedCountry!.isEmpty
        ? widget.docs
        : widget.docs.where((doc) {
            final data = doc.data();
            return data['country'] == _selectedCountry;
          }).toList();

    return Column(
      children: [
        // Country filter bar
        if (widget.countries.isNotEmpty)
          Container(
            padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0),
            child: Row(
              children: [
                Icon(Icons.filter_list, size: 16.w, color: Colors.grey.shade600),
                SizedBox(width: 6.w),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _filterChip(
                          label: 'All',
                          selected: _selectedCountry == null,
                          onTap: () => setState(() => _selectedCountry = null),
                        ),
                        SizedBox(width: 6.w),
                        ...widget.countries.map((c) => Padding(
                          padding: EdgeInsets.only(right: 6.w),
                          child: _filterChip(
                            label: c,
                            selected: _selectedCountry == c,
                            onTap: () => setState(() => _selectedCountry = c),
                          ),
                        )),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Announcement list
        Expanded(
          child: filtered.isEmpty
              ? _buildEmpty('No announcements for this country.')
              : ListView.separated(
                  padding: EdgeInsets.symmetric(vertical: 8.w),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => SizedBox(height: 10.h),
                  itemBuilder: (context, index) {
                    final broadcast = AnnouncementModel.fromDoc(filtered[index]);
                    return Card(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12.r),
                        onTap: () {
                          routerConfig.push(
                            '/announcement-detail',
                            extra: broadcast,
                          );
                        },
                        child: Padding(
                        padding: EdgeInsets.all(12.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8.w,
                                    vertical: 4.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.shade50,
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.campaign,
                                        size: 14.w,
                                        color: Colors.amber.shade700,
                                      ),
                                      SizedBox(width: 4.w),
                                      Text(
                                        'Announcement',
                                        style: TextStyle(
                                          fontSize: 11.sp,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.amber.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Spacer(),
                                if (broadcast.country != null)
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 6.w,
                                      vertical: 2.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(6.r),
                                    ),
                                    child: Text(
                                      broadcast.country!,
                                      style: TextStyle(
                                        fontSize: 10.sp,
                                        color: Colors.blue.shade700,
                                      ),
                                    ),
                                  ),
                                SizedBox(width: 6.w),
                                Text(
                                  timeAgo(broadcast.createdAt),
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 10.h),
                            Text(
                              broadcast.title,
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 6.h),
                            Text(
                              broadcast.body,
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: Colors.grey.shade700,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _filterChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: selected ? Colors.red.shade50 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: selected ? Colors.red.shade400 : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            color: selected ? Colors.red.shade700 : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }
}

String timeAgo(DateTime dt) {
  final now = DateTime.now();
  final diff = now.difference(dt);
  if (diff.inMinutes < 1) return 'now';
  if (diff.inHours < 1) return '${diff.inMinutes}m ago';
  if (diff.inDays < 1) return '${diff.inHours}h ago';
  return '${diff.inDays}d ago';
}
