import 'package:bloodfinder/shared/widgets/start_chat_btn.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../data/providers/repository_providers.dart';
import '../../../../features/blood_request/models/blood_request.dart';
import '../widgets/donation_info_card.dart';
import '../widgets/donation_poster_card.dart';

class DonationPage extends ConsumerWidget {
  final String requestId;

  DonationPage({super.key, required this.requestId});

  Future<void> _callDonor(String mobile) async {
    if (mobile.isEmpty) return;
    final Uri uri = Uri.parse("tel:$mobile");
    try {
      final bool launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) debugPrint("❌ Could not launch dialer for $mobile");
    } catch (e) {
      debugPrint("❌ Error launching dialer: $e");
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final requestStream = ref
        .read(bloodRequestRepositoryProvider)
        .requestStream(requestId);

    return Scaffold(
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: requestStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Request not found"));
          }

          final request = BloodRequest.fromFirestore(snapshot.data!);

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.red.shade800,
                        Colors.red.shade600,
                        Colors.red.shade400,
                      ],
                    ),
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.elliptical(300, 40),
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(4.w, 4.h, 16.w, 28.h),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(
                                  PhosphorIcons.arrowLeft,
                                  color: Colors.white,
                                ),
                                onPressed: () => Navigator.pop(context),
                              ),
                              const Spacer(),
                              IconButton(
                                icon: Icon(
                                  PhosphorIcons.share,
                                  color: Colors.white,
                                ),
                                onPressed: () async {
                                  final locationPart =
                                      (request.locationAddress != null &&
                                          request.locationAddress!.isNotEmpty)
                                      ? ', ${request.locationAddress}'
                                      : '';
                                  final shareText =
                                      '\nBlood Group: ${request.bloodGroup}\nName: ${request.name}\nContact No: ${request.mobile}\n\nAddress: ${request.address}$locationPart\n\nBags Needed: ${request.bag}\nTime: ${request.time}, ${request.date}';
                                  try {
                                    await SharePlus.instance.share(
                                      ShareParams(
                                        text: shareText,
                                        subject: 'Blood Donation Request',
                                        title:
                                            '${request.bloodGroup} Blood Request',
                                      ),
                                    );
                                  } catch (e) {
                                    debugPrint('Error sharing: $e');
                                  }
                                },
                              ),
                            ],
                          ),
                          SizedBox(height: 8.h),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.w),
                            child: Row(
                              children: [
                                Container(
                                  width: 72.w,
                                  height: 72.h,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.2,
                                        ),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Text(
                                      request.bloodGroup,
                                      style: TextStyle(
                                        fontSize: 28.sp,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 16.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Patient",
                                        style: TextStyle(
                                          fontSize: 10.sp,
                                          color: Colors.white60,
                                          height: 1.h,
                                        ),
                                      ),
                                      Text(
                                        request.name,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 22.sp,
                                          color: Colors.white,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      SizedBox(height: 4.h),
                                      Container(
                                        decoration: BoxDecoration(),
                                        child: Text(
                                          "${request.bag} bag - ${request.date} - ${request.time}",
                                          style: TextStyle(
                                            fontSize: 13.sp,
                                            color: Colors.white.withValues(
                                              alpha: 0.8,
                                            ),
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 0.h),
                  child: Row(
                    children: [
                      Container(
                        width: 28.w,
                        height: 28.h,
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Icon(
                          PhosphorIcons.userCircle,
                          size: 16,
                          color: Colors.red.shade600,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        'Posted by',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 0.h),
                  child: Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    color: theme.colorScheme.surface,
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: EdgeInsets.all(16.w),
                      child: DonationPosterCard(request: request),
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 12.h),
                  child: Row(
                    children: [
                      Container(
                        width: 28.w,
                        height: 28.h,
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Icon(
                          PhosphorIcons.info,
                          size: 16,
                          color: Colors.red.shade400,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        'Info',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    color: theme.colorScheme.surface,
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: EdgeInsets.all(16.w),
                      child: DonationInfoCard(request: request, isDark: isDark),
                    ),
                  ),
                ),
              ),
              if (request.note != null && request.note!.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 0.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              PhosphorIcons.note,
                              size: 20,
                              color: Colors.red.shade400,
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              'Additional Note',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10.h),
                        Card(
  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    color: theme.colorScheme.surface,
                          child: Container(
                            width: .infinity,
                            padding: EdgeInsets.all(12.w),
                            child: Text(
                              request.note!,
                              style: TextStyle(
                                height: 1.5,
                                fontSize: 14.sp,
                                color: isDark
                                    ? Colors.grey.shade300
                                    : Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 12.h),
                  child: Row(
                    children: [
                      Container(
                        width: 28.w,
                        height: 28.h,
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Icon(
                          PhosphorIcons.phone,
                          size: 16,
                          color: Colors.green.shade600,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        'Contact',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 0.h, 16.w, 24.h),
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    color: theme.colorScheme.surface,
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: EdgeInsets.all(16.w),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Contact Number',
                                      style: TextStyle(
                                        fontSize: 11.sp,
                                        color: isDark
                                            ? Colors.grey.shade500
                                            : Colors.grey.shade400,
                                      ),
                                    ),
                                    SizedBox(height: 8.h),
                                    Text(
                                      request.mobile,
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w600,
                                        color: isDark
                                            ? Colors.grey.shade200
                                            : Colors.grey.shade800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(
                                height: 40.h,
                                width: 40.w,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green.shade500,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10.r),
                                    ),
                                    padding: EdgeInsets.zero,
                                  ),
                                  onPressed: (request.mobile.isNotEmpty)
                                      ? () => _callDonor(request.mobile)
                                      : null,
                                  child: Icon(
                                    PhosphorIcons.phoneCall,
                                    size: 20,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12.h),
                          SizedBox(
                            width: double.infinity,
                            height: 48.h,
                            child: StartChatButton(otherUserId: request.uid),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
