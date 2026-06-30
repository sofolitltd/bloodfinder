import 'package:bloodfinder/core/constants/app_data.dart';
import 'package:bloodfinder/features/feed/providers/feed_provider.dart';
import 'package:bloodfinder/shared/widgets/blood_request_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

class FeedPage extends ConsumerStatefulWidget {
  const FeedPage({super.key});

  @override
  ConsumerState<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends ConsumerState<FeedPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      final notifier = ref.read(feedPaginationProvider.notifier);
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          notifier.hasMore) {
        notifier.loadNextPage();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // -------------------- Filter Bottom Sheet --------------------
  void _showFilterSheet() {
    final notifier = ref.read(feedPaginationProvider.notifier);

    // Local state for the sheet
    String? selectedBloodGroup = notifier.bloodGroup;
    double selectedRadius = notifier.radiusInKm;
    bool proximityOn = notifier.proximityEnabled;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
              ),
              child: SafeArea(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 20.h),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Drag handle
                      Center(
                        child: Container(
                          width: 40.w,
                          height: 4.h,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade400,
                            borderRadius: BorderRadius.circular(2.r),
                          ),
                        ),
                      ),
                      SizedBox(height: 1.h),

                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Filters',
                            style: TextStyle(
                              fontSize: 22.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              setSheetState(() {
                                selectedBloodGroup = null;
                                selectedRadius = 50.0;
                                proximityOn = true;
                              });
                            },
                            child: Text(
                              'Reset',
                              style: TextStyle(
                                color: Colors.red.shade400,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 2.h),

                      // ── Blood Group Section ──
                      Row(
                        children: [
                          Icon(PhosphorIcons.drop,
                              size: 18.w, color: Colors.red.shade400),
                          SizedBox(width: 8.w),
                          Text(
                            'Blood Group',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 1.h),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: AppData.bloodGroups.map((group) {
                          final isSelected = selectedBloodGroup == group;
                          return GestureDetector(
                            onTap: () {
                              setSheetState(() {
                                selectedBloodGroup =
                                    isSelected ? null : group;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: EdgeInsets.symmetric(
                                horizontal: 16.w,
                                vertical: 10.h,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.red.shade600
                                    : Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.grey.shade800
                                        : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(20.r),
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.red.shade600
                                      : Colors.grey.shade400,
                                  width: 1.w,
                                ),
                              ),
                              child: Text(
                                group,
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? Colors.white
                                      : Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Colors.white70
                                          : Colors.grey.shade700,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      SizedBox(height: 2.h),

                      // ── Proximity Section ──
                      Row(
                        children: [
                          Icon(PhosphorIcons.mapPin,
                              size: 18.w, color: Colors.blue.shade400),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              'Proximity',
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Switch.adaptive(
                            value: proximityOn,
                            activeColor: Colors.red.shade400,
                            onChanged: (v) =>
                                setSheetState(() => proximityOn = v),
                          ),
                        ],
                      ),
                      SizedBox(height: 4.h),

                      AnimatedOpacity(
                        opacity: proximityOn ? 1.0 : 0.35,
                        duration: const Duration(milliseconds: 200),
                        child: IgnorePointer(
                          ignoring: !proximityOn,
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '5 km',
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12.w,
                                      vertical: 4.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade50,
                                      borderRadius: BorderRadius.circular(12.r),
                                    ),
                                    child: Text(
                                      '${selectedRadius.round()} km',
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red.shade700,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '100 km',
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                              Slider(
                                value: selectedRadius,
                                min: 5,
                                max: 100,
                                divisions: 19,
                                activeColor: Colors.red.shade400,
                                inactiveColor: Colors.grey.shade300,
                                label: '${selectedRadius.round()} km',
                                onChanged: (v) {
                                  setSheetState(
                                      () => selectedRadius = v);
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 2.h),

                      // ── Apply Button ──
                      SizedBox(
                        width: double.infinity,
                        height: 48.h,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade600,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            elevation: 0,
                          ),
                          onPressed: () {
                            notifier.updateFilters(
                              bloodGroup: selectedBloodGroup,
                              radiusInKm: selectedRadius,
                              proximityEnabled: proximityOn,
                            );
                            Navigator.pop(sheetContext);
                          },
                          child: Text(
                            'Apply Filters',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // -------------------- Feed List --------------------
  Widget _buildFeedList() {
    final feedAsync = ref.watch(feedPaginationProvider);

    return feedAsync.when(
      data: (docs) {
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(PhosphorIcons.drop, size: 64.w, color: Colors.grey[400]),
                SizedBox(height: 1.h),
                Text(
                  'No blood requests found',
                  style: TextStyle(
                    fontSize: 18.sp,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Try adjusting your filters or increasing the distance',
                  style: TextStyle(fontSize: 14.sp, color: Colors.grey[500]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final notifier = ref.read(feedPaginationProvider.notifier);
        return ListView.separated(
          padding: EdgeInsets.all(16.w),
          separatorBuilder: (_, __) => SizedBox(height: 1.h),
          controller: _scrollController,
          itemCount: docs.length + (notifier.hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index < docs.length) {
              return BloodRequestCard(request: docs[index]);
            } else {
              return Center(
                child: Padding(
                  padding: EdgeInsets.all(16.w),
                  child: SizedBox(
                    width: 24.w,
                    height: 24.h,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              );
            }
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              PhosphorIcons.warningCircle,
              size: 64.w,
              color: Colors.red[300],
            ),
            SizedBox(height: 1.h),
            Text(
              'Something went wrong',
              style: TextStyle(fontSize: 18.sp, color: Colors.grey[600]),
            ),
            SizedBox(height: 8.h),
            Text(
              'Error: $e',
              style: TextStyle(fontSize: 14.sp, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.watch(feedPaginationProvider.notifier);
    final hasFilters = notifier.hasActiveFilters;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Feed'),
        centerTitle: false,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: Icon(PhosphorIcons.funnel),
                onPressed: _showFilterSheet,
              ),
              if (hasFilters)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 8.w,
                    height: 8.h,
                    decoration: BoxDecoration(
                      color: Colors.red.shade600,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: _buildFeedList(),
    );
  }
}
