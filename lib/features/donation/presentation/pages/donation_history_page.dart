import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../../data/providers/repository_providers.dart';
import '../../../../data/providers/user_providers.dart';
import '../../services/donation_service.dart';
import 'add_donation_page.dart';
import 'certificate_page.dart';

class DonationHistoryPage extends ConsumerStatefulWidget {
  const DonationHistoryPage({super.key});

  @override
  ConsumerState<DonationHistoryPage> createState() =>
      _DonationHistoryPageState();
}

class _DonationHistoryPageState extends ConsumerState<DonationHistoryPage> {
  Future<void> _deleteDonation(String docId, {String? imageUrl}) async {
    final userRepo = ref.read(userRepositoryProvider);
    final uid = ref.read(authRepositoryProvider).currentUser!.uid;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Delete Donation'),
            IconButton(
              onPressed: () => Navigator.pop(context, false),
              icon: Icon(PhosphorIcons.x),
            ),
          ],
        ),
        content: const Text('Are you sure you want to delete this donation?'),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        if (imageUrl != null && imageUrl.isNotEmpty) {
          await FirebaseStorage.instance.refFromURL(imageUrl).delete();
        }
        await userRepo.deleteDonation(uid, docId);

        final remaining = await userRepo
            .donationCollection()
            .where('uid', isEqualTo: uid)
            .get();
        final actualCount = remaining.docs.length;

        final updates = <String, dynamic>{
          'donationCount': actualCount,
          'badges': computeBadges(actualCount),
        };
        if (actualCount == 0) {
          updates['isVerifiedDonor'] = false;
        }
        await userRepo.updateUser(uid, updates);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Donation deleted successfully!')),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete donation.')),
        );
      }
    }
  }

  Future<void> _openCertificate() async {
    final uid = ref.read(authRepositoryProvider).currentUser?.uid;
    if (uid == null) return;

    final userAsync = ref.read(userProvider);
    final userModel = userAsync.value;
    if (userModel == null) return;

    final userRepo = ref.read(userRepositoryProvider);
    final doc = await userRepo.getUser(uid);
    final data = doc.data() as Map<String, dynamic>;
    final count = (data['donationCount'] as num?)?.toInt() ?? 0;
    final badges =
        (data['badges'] as List<dynamic>?)?.cast<String>() ?? [];
    final badge =
        badges.isNotEmpty ? badgeLabel(badges.last) : 'First Hero';

    // Get latest donation image
    String? latestImageUrl;
    try {
      final latestDocs = await userRepo.donationCollection()
          .where('uid', isEqualTo: uid)
          .orderBy('donationDate', descending: true)
          .limit(1)
          .get();
      if (latestDocs.docs.isNotEmpty) {
        latestImageUrl =
            latestDocs.docs.first.data()['imageUrl'] as String?;
      }
    } catch (_) {}

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CertificatePage(
          user: userModel,
          donationCount: count,
          badgeName: badge,
          donationImageUrl: latestImageUrl,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userRepo = ref.read(userRepositoryProvider);
    final uid = ref.read(authRepositoryProvider).currentUser?.uid;

    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to view donations.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Donation History'),
        centerTitle: true,
    
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: userRepo.donationsStream(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No donations yet.'));
          }

          final donations = snapshot.data!.docs;

          final userDocAsync = ref.watch(userDocProvider);
          final rawData = userDocAsync.value?.data();
          final donationCount =
              (rawData?['donationCount'] as num?)?.toInt() ?? 0;
          final badgesList =
              (rawData?['badges'] as List<dynamic>?)?.cast<String>() ?? [];

          final dates = donations
              .map((d) => ((d.data() as Map<String, dynamic>)['donationDate']
                      as Timestamp?)
                  ?.toDate())
              .whereType<DateTime>()
              .toList()
            ..sort();

          final lastWaitingDays = donations.isNotEmpty
              ? ((donations.first.data() as Map<String, dynamic>)['waitingDays']
                      as num?)
                  ?.toInt()
              : null;

          return Column(
            children: [
              _SummarySection(
                donationCount: donationCount,
                badges: badgesList,
                donationDates: dates,
                lastWaitingDays: lastWaitingDays,
              ),
              Expanded(
                child: ListView.separated(
                  padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.w),
                  itemCount: donations.length,
                  separatorBuilder: (_, __) => SizedBox(height: 8.h),
                  itemBuilder: (context, index) {
                    final data =
                        donations[index].data() as Map<String, dynamic>;
                    final docId = donations[index].id;
                    final donationDate = (data['donationDate'] as Timestamp?)
                        ?.toDate();
                    final recipientName =
                        data['recipientName'] ?? 'Not specified';
                    final recipientMobile =
                        data['recipientMobile'] ?? '-';
                    final hospitalName =
                        data['hospitalName'] as String?;
                    final donationTypeLabel =
                        data['donationTypeLabel'] as String?;
                    final imageUrl = data['imageUrl'] as String?;
                    final notes = data['notes'] as String?;

                    return _DonationCard(
                      donationDate: donationDate,
                      recipientName: recipientName,
                      recipientMobile: recipientMobile,
                      hospitalName: hospitalName,
                      donationTypeLabel: donationTypeLabel,
                      imageUrl: imageUrl,
                      notes: notes,
                      onShare: _openCertificate,
                      onDelete: () => _deleteDonation(docId, imageUrl: imageUrl),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.red.shade600,
        icon: Icon(PhosphorIcons.plus, color: Colors.white),
        label: Text('Add Donation', style: TextStyle(color: Colors.white)),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddDonationPage()),
          );

          if (result == true) {
            setState(() {});
          }
        },
      ),
    );
  }
}

class _SummarySection extends StatelessWidget {
  final int donationCount;
  final List<String> badges;
  final List<DateTime> donationDates;
  final int? lastWaitingDays;

  const _SummarySection({
    required this.donationCount,
    required this.badges,
    required this.donationDates,
    this.lastWaitingDays,
  });

  static const _milestones = [
    (label: 'First', count: 1),
    (label: 'Bronze', count: 3),
    (label: 'Silver', count: 7),
    (label: 'Gold', count: 15),
    (label: 'Legend', count: 25),
  ];

  String get _currentBadge {
    if (badges.isEmpty) return 'First Hero';
    return badgeLabel(badges.last);
  }

  Color _milestoneColor(int threshold) {
    if (donationCount >= threshold) return Colors.red;
    return Colors.grey.shade300;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(16.w),
      padding: EdgeInsets.all(16.w),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(PhosphorIcons.drop, size: 22, color: Colors.red.shade600),
              SizedBox(width: 8.w),
              Text(
                '$donationCount',
                style: TextStyle(
                  fontSize: 26.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade700,
                ),
              ),
              SizedBox(width: 4.w),
              Text(
                'donation${donationCount == 1 ? '' : 's'}',
                style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade600),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  final current = _milestones.lastWhere(
                    (m) => donationCount >= m.count,
                    orElse: () => _milestones.first,
                  );
                  final earned = donationCount >= current.count;
                  _showBadgeInfo(
                    context,
                    _currentBadge,
                    current.count,
                    earned,
                  );
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.emoji_events, size: 20, color: Colors.amber.shade700),
                    SizedBox(width: 6.w),
                    Text(
                      _currentBadge,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.amber.shade800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          // Milestones
          SizedBox(
            height: 40.h,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  top: 6,
                  child: Row(
                    children: List.generate(_milestones.length - 1, (i) {
                      final next = _milestones[i + 1];
                      final reached = donationCount >= next.count;
                      return Expanded(
                        child: Container(
                          height: 2,
                          color: reached ? Colors.red.shade300 : Colors.grey.shade300,
                        ),
                      );
                    }),
                  ),
                ),
                Row(
                  children: _milestones.map((m) {
                    final reached = donationCount >= m.count;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => _showBadgeInfo(context, m.label, m.count, reached),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: reached ? 14 : 10,
                              height: reached ? 14 : 10,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: reached ? Colors.red : Colors.grey.shade300,
                                border: reached
                                    ? Border.all(color: Colors.red.shade700, width: 2)
                                    : null,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              m.label,
                              style: TextStyle(
                                fontSize: 9.sp,
                                fontWeight: reached ? FontWeight.bold : FontWeight.normal,
                                color: reached ? Colors.red.shade700 : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          SizedBox(height: 12.h),
          // Donation dots timeline
          Text(
            'Donation Timeline',
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 6.h),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: donationDates.map((date) {
                final isNewest = date == donationDates.last;
                return Container(
                  width: isNewest ? 12 : 8,
                  height: isNewest ? 12 : 8,
                  margin: EdgeInsets.only(right: 4.w),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isNewest ? Colors.red.shade600 : Colors.red.shade200,
                    border: isNewest
                        ? Border.all(color: Colors.red.shade800, width: 2)
                        : null,
                  ),
                );
              }).toList(),
            ),
          ),
          SizedBox(height: 12.h),
          Divider(height: 8.h),
          SizedBox(height: 12.h),
          // Next eligible donation
          Row(
            children: [
              Icon(PhosphorIcons.calendar, size: 16, color: Colors.red.shade500),
              SizedBox(width: 8.w),
              Text(
                'Next Eligible Donation',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          _buildNextDonationDate(),
        ],
      ),
    );
  }

  Widget _buildNextDonationDate() {
    if (donationDates.isEmpty) {
      return Text(
        'You can donate now',
        style: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.bold,
          color: Colors.green,
        ),
      );
    }

    final lastDate = donationDates.last;
    final interval = lastWaitingDays ?? 90;
    final nextDate = lastDate.add(Duration(days: interval));
    final remaining = nextDate.difference(DateTime.now()).inDays;

    if (remaining <= 0) {
      return Text(
        'You can donate now',
        style: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.bold,
          color: Colors.green,
        ),
      );
    }

    return Row(
      children: [
        Text(
          DateFormat('dd MMM, yyyy').format(nextDate),
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(width: 8.w),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(4.r),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: Text(
            '$remaining days',
            style: TextStyle(
              fontSize: 10.sp,
              fontWeight: FontWeight.w600,
              color: Colors.orange.shade700,
            ),
          ),
        ),
      ],
    );
  }

  void _showBadgeInfo(BuildContext context, String name, int required, bool earned) {
    final nextMilestone = _milestones.firstWhere(
      (m) => m.count > required,
      orElse: () => (label: 'Legend', count: 25),
    );
    final nextRequired = nextMilestone.count;
    final remaining = earned ? 0 : nextRequired - donationCount;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Row(
          children: [
            Icon(
              Icons.emoji_events,
              size: 24,
              color: earned ? Colors.amber.shade700 : Colors.grey,
            ),
            SizedBox(width: 8.w),
            Text(name, style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              earned
                  ? 'You\'ve earned this badge!'
                  : 'Donate $required times to earn this badge.',
              style: TextStyle(fontSize: 14.sp),
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                Text('Progress: ', style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade600)),
                Text(
                  '${donationCount.clamp(0, nextRequired)} / $nextRequired',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: earned ? Colors.green : Colors.red.shade700,
                  ),
                ),
              ],
            ),
            if (!earned && remaining > 0) ...[
              SizedBox(height: 4.h),
              Text(
                '$remaining more donation${remaining == 1 ? '' : 's'} needed',
                style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade500),
              ),
            ],
            SizedBox(height: 8.h),
            ClipRRect(
              borderRadius: BorderRadius.circular(4.r),
              child: LinearProgressIndicator(
                value: (donationCount.clamp(0, nextRequired) / nextRequired).clamp(0.0, 1.0),
                backgroundColor: Colors.grey.shade200,
                color: earned ? Colors.green : Colors.red.shade400,
                minHeight: 6,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _DonationCard extends StatelessWidget {
  final DateTime? donationDate;
  final String recipientName;
  final String recipientMobile;
  final String? hospitalName;
  final String? donationTypeLabel;
  final String? imageUrl;
  final String? notes;
  final VoidCallback onShare;
  final VoidCallback onDelete;

  const _DonationCard({
    required this.donationDate,
    required this.recipientName,
    required this.recipientMobile,
    this.hospitalName,
    this.donationTypeLabel,
    this.imageUrl,
    this.notes,
    required this.onShare,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (imageUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8.r),
                    child: Image.network(
                      imageUrl!,
                      height: 56,
                      width: 56,
                      fit: BoxFit.cover,
                    ),
                  )
                else
                  Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Icon(
                      PhosphorIcons.drop,
                      size: 18,
                      color: Colors.red.shade600,
                    ),
                  ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Donated',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          if (donationTypeLabel != null) ...[
                            SizedBox(width: 8.w),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 6.w,
                                vertical: 8.h,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(4.r),
                              ),
                              child: Text(
                                donationTypeLabel!,
                                style: TextStyle(
                                  fontSize: 9.sp,
                                  color: Colors.red.shade700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        donationDate != null
                            ? DateFormat('dd MMM, yyyy').format(donationDate!)
                            : '-',
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.share_outlined,
                        color: Colors.red.shade400,
                        size: 20.w,
                      ),
                      onPressed: onShare,
                    ),
                    IconButton(
                      icon: Icon(
                        PhosphorIcons.trash,
                        color: Colors.red,
                        size: 20.w,
                      ),
                      onPressed: onDelete,
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Row(
              children: [
                Icon(PhosphorIcons.user, size: 16, color: Colors.grey.shade500),
                SizedBox(width: 6.w),
                Expanded(
                  child: Text(
                    'Recipient: $recipientName',
                    style: TextStyle(fontSize: 13.sp),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: 4.h),
            Row(
              children: [
                Icon(
                  PhosphorIcons.deviceMobile,
                  size: 16,
                  color: Colors.grey.shade500,
                ),
                SizedBox(width: 6.w),
                Text(
                  'Mobile: $recipientMobile',
                  style: TextStyle(fontSize: 13.sp),
                ),
              ],
            ),
            if (hospitalName != null) ...[
              SizedBox(height: 4.h),
              Row(
                children: [
                  Icon(
                    PhosphorIcons.hospital,
                    size: 16,
                    color: Colors.grey.shade500,
                  ),
                  SizedBox(width: 6.w),
                  Expanded(
                    child: Text(
                      hospitalName!,
                      style: TextStyle(fontSize: 13.sp),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            if (notes != null) ...[
              SizedBox(height: 4.h),
              Row(
                children: [
                  Icon(
                    PhosphorIcons.note,
                    size: 16,
                    color: Colors.grey.shade500,
                  ),
                  SizedBox(width: 6.w),
                  Expanded(
                    child: Text(
                      notes!,
                      style: TextStyle(fontSize: 13.sp, color: Colors.grey.shade700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
