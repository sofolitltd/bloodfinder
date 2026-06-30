import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../data/providers/repository_providers.dart';
import '../../features/blood_request/models/blood_request.dart';
import '../../data/models/user_model.dart';
import '../../features/donation/presentation/pages/donation_page.dart';

class BloodRequestCard extends ConsumerWidget {
  BloodRequestCard({super.key, required this.request, this.embedded = false, this.distanceInKm, this.onDelete, this.onEdit});

  final BloodRequest request;
  final bool embedded;
  final double? distanceInKm;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isFeed = onDelete == null;

    return FutureBuilder(
      future: ref.read(userRepositoryProvider).getUser(request.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox();
        }

        final UserModel user;
        if (!snapshot.hasData || !snapshot.data!.exists || snapshot.hasError) {
          if (snapshot.hasError) {
            debugPrint('Error fetching user ${request.uid}: ${snapshot.error}');
          } else if (!snapshot.hasData || !snapshot.data!.exists) {
            debugPrint('User ${request.uid} not found in users_test collection.');
          }
          user = UserModel(
            uid: request.uid,
            firstName: 'Unknown',
            lastName: 'User',
            email: '',
            mobileNumber: '',
            bloodGroup: request.bloodGroup,
            gender: '',
            dateOfBirth: DateTime(2000),
            communities: const [],
            isDonor: false,
            isEmergencyDonor: false,
            token: '',
            createdAt: '',
            isOnline: false,
            image: '',
          );
        } else {
          final userData = snapshot.data!.data() as Map<String, dynamic>;
          user = UserModel.fromJson(userData);
        }

        void shareRequest() async {
          final locationPart = (request.locationAddress != null && request.locationAddress!.isNotEmpty)
              ? ', ${request.locationAddress}'
              : '';
          final shareText =
              '\nBlood Group: ${request.bloodGroup}\nName: ${request.name}\nContact No: ${request.mobile}\n\nAddress: ${request.address}$locationPart\nDate: ${formatDate(request.date)}\nTime: ${formatTime(request.time)}\nBags Needed: ${request.bag}';

          try {
            await SharePlus.instance.share(
              ShareParams(
                text: shareText.isEmpty ? null : shareText,
                subject: 'Blood Donation Request',
                title: '${request.bloodGroup} Blood Request',
                excludedCupertinoActivities: [
                  CupertinoActivityType.airDrop,
                ],
              ),
            );
          } catch (e) {
            debugPrint('Error sharing: $e');
          }
        }

        final Widget container;

        if (isFeed) {
          container = _buildFeedCard(context, isDark, user, shareRequest);
        } else {
          container = _buildManageCard(context, isDark, user, shareRequest);
        }

        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16.r),
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
          child: container,
        );
      },
    );
  }

  Widget _buildFeedCard(BuildContext context, bool isDark, UserModel user, VoidCallback shareRequest) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DonationPage(requestId: request.id),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 0.h),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40.w,
                  height: 48.h,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.red.shade600,
                        Colors.red.shade400,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: 2.h),

                      Icon(PhosphorIcons.dropFill, size: 16.w, color: Colors.white),
                      SizedBox(height: 2.h),
                      Text(
                        request.bloodGroup,
                        style: TextStyle(
                          fontSize: 16.sp,
                          height: 1.h,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              request.name,
                              style: TextStyle(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.grey.shade200 : Colors.grey.shade800,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(width: 6.w),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                            decoration: BoxDecoration(
                              color: _statusColor(request.status).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                            child: Text(
                              _statusLabel(request.status),
                              style: TextStyle(
                                fontSize: 9.sp,
                                fontWeight: FontWeight.w600,
                                color: _statusColor(request.status),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4.h),
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 7.r,
                            backgroundColor: Colors.grey.shade300,
                            backgroundImage: user.image.isNotEmpty
                                ? CachedNetworkImageProvider(user.image)
                                : null,
                            child: user.image.isEmpty
                                ? Text(
                                    user.firstName.isNotEmpty
                                        ? user.firstName[0].toUpperCase()
                                        : '',
                                    style: TextStyle(
                                      fontSize: 8.sp,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade600,
                                    ),
                                  )
                                : null,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            'Posted by ${user.firstName} ${user.lastName}',
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 6.h),
                      Row(
                        children: [
                          Icon(PhosphorIcons.hospital, size: 14.w, color: Colors.grey.shade500),
                          SizedBox(width: 5.w),
                          Expanded(
                            child: Text(
                              request.address,
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (request.locationAddress != null &&
                          request.locationAddress!.isNotEmpty) ...[
                        SizedBox(height: 3.h),
                        Row(
                          children: [
                            Icon(PhosphorIcons.mapPin, size: 13.w, color: Colors.grey.shade500),
                            SizedBox(width: 6.w),
                            Expanded(
                              child: Text(
                                request.locationAddress!,
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                      SizedBox(height: 4.h),
                      Row(
                        children: [
                          Icon(PhosphorIcons.clock, size: 14.w, color: Colors.grey.shade500),
                          SizedBox(width: 5.w),
                          Text(
                            '${formatDate(request.date)} at ${formatTime(request.time)}',
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                      if (distanceInKm != null) ...[
                        SizedBox(height: 4.h),
                        Row(
                          children: [
                            Icon(PhosphorIcons.mapPin, size: 14.w, color: Colors.red.shade400),
                            SizedBox(width: 5.w),
                            Text(
                              '${distanceInKm!.toStringAsFixed(1)} km away',
                              style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w500,
                                color: Colors.red.shade400,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(width: 4.w),
                InkWell(
                  onTap: shareRequest,
                  borderRadius: BorderRadius.circular(8.r),
                  child: Container(
                    width: 32.w,
                    height: 32.h,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey.shade700.withValues(alpha: 0.3) : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Icon(
                      PhosphorIcons.share,
                      size: 16.w,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 10.h),
          Container(
            height: 40.h,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.red.shade600, Colors.red.shade500],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(16.r),
                bottomRight: Radius.circular(16.r),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(PhosphorIcons.heart, size: 16.w, color: Colors.white.withValues(alpha: 0.9)),
                SizedBox(width: 8.w),
                Text(
                  'Donate Now',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.95),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManageCard(BuildContext context, bool isDark, UserModel user, VoidCallback shareRequest) {
    return Padding(
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 22.r,
                backgroundColor: Colors.redAccent.shade200,
                child: user.image.isEmpty
                    ? Text(
                        user.firstName.isNotEmpty
                            ? user.firstName[0].toUpperCase()
                            : '',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 22.sp,
                        ),
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(50.r),
                        child: CachedNetworkImage(
                          imageUrl: user.image,
                          width: 44.w,
                          height: 44.h,
                          fit: BoxFit.cover,
                          placeholder: (context, url) =>
                              SizedBox(
                                  width: 20.w,
                                  height: 20.h,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2)),
                          errorWidget: (context, url, error) => Icon(
                            PhosphorIcons.warningCircle,
                            color: Colors.red,
                          ),
                        ),
                      ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${user.firstName} ${user.lastName}',
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? Colors.grey.shade200
                            : Colors.grey.shade800,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      DateFormat('dd MMM yyy - hh:mm a')
                          .format(request.createdAt),
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (onDelete != null)
                    _ManagementMenu(
                      onEdit: onEdit,
                      onDelete: onDelete,
                      onShare: shareRequest,
                      isDark: isDark,
                    ),
                ],
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Divider(
            height: 1.h,
            thickness: 1,
            color: isDark
                ? Colors.grey.shade600.withValues(alpha: 0.5)
                : Colors.grey.shade300,
          ),
          SizedBox(height: 12.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  children: [
                    _InfoTile(
                      icon: PhosphorIcons.user,
                      iconColor: Colors.blue.shade400,
                      label: 'Patient',
                      value: request.name,
                      isDark: isDark,
                    ),
                    SizedBox(height: 10.h),
                    _InfoTile(
                      icon: PhosphorIcons.drop,
                      iconColor: Colors.red.shade400,
                      label: 'Blood Group',
                      value: request.bloodGroup,
                      isDark: isDark,
                    ),
                    SizedBox(height: 10.h),
                    _InfoTile(
                      icon: PhosphorIcons.calendar,
                      iconColor: Colors.orange.shade400,
                      label: 'Date',
                      value: formatDate(request.date),
                      isDark: isDark,
                    ),
                    if (distanceInKm != null) ...[
                      SizedBox(height: 10.h),
                      _InfoTile(
                        icon: PhosphorIcons.mapPin,
                        iconColor: Colors.grey.shade500,
                        label: 'Distance',
                        value: '${distanceInKm!.toStringAsFixed(1)} km',
                        isDark: isDark,
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  children: [
                    _InfoTile(
                      icon: PhosphorIcons.flag,
                      iconColor: _statusColor(request.status),
                      label: 'Status',
                      value: _statusLabel(request.status),
                      isDark: isDark,
                      valueColor: _statusColor(request.status),
                    ),
                    SizedBox(height: 10.h),
                    _InfoTile(
                      icon: PhosphorIcons.heartbeat,
                      iconColor: Colors.red.shade400,
                      label: 'Bags Needed',
                      value: request.bag,
                      isDark: isDark,
                    ),
                    SizedBox(height: 10.h),
                    _InfoTile(
                      icon: PhosphorIcons.clock,
                      iconColor: Colors.orange.shade400,
                      label: 'Time',
                      value: formatTime(request.time),
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.grey.shade700.withValues(alpha: 0.15)
                  : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _AddressTile(
                  icon: PhosphorIcons.hospital,
                  iconColor: Colors.grey.shade500,
                  label: 'Clinic / Address',
                  value: request.address,
                  isDark: isDark,
                ),
                if (request.locationAddress != null &&
                    request.locationAddress!.isNotEmpty) ...[
                  SizedBox(height: 8.h),
                  _AddressTile(
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
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final bool isDark;
  final Color? valueColor;

  const _InfoTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.isDark,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 36.w,
          height: 36.h,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Icon(icon, size: 18.w, color: iconColor),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.sp,
                  color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                ),
              ),
              SizedBox(height: 1.h),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: valueColor ??
                      (isDark ? Colors.grey.shade200 : Colors.grey.shade800),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AddressTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final bool isDark;

  const _AddressTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32.w,
          height: 32.h,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(icon, size: 16.w, color: iconColor),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.sp,
                  color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

String formatDate(String dateStr) {
  try {
    final date = DateFormat('d/M/yyy').parseStrict(dateStr);
    return DateFormat('d MMM, yyyy').format(date);
  } catch (e) {
    try {
      final date = DateFormat('yyyy-MM-dd').parseStrict(dateStr);
      return DateFormat('d MMM, yyyy').format(date);
    } catch (_) {
      return dateStr;
    }
  }
}

String formatTime(String timeStr) {
  return timeStr;
}

class _ManagementMenu extends StatelessWidget {
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onShare;
  final bool isDark;

  const _ManagementMenu({
    required this.onEdit,
    required this.onDelete,
    required this.onShare,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: PopupMenuButton<String>(
        onSelected: (value) {
          if (value == 'edit') onEdit?.call();
          if (value == 'delete') onDelete?.call();
          if (value == 'share') onShare?.call();
        },
        itemBuilder: (_) => [
          PopupMenuItem(
            value: 'edit',
            child: Row(
              children: [
                Icon(Icons.edit, size: 20.w),
                SizedBox(width: 8.w),
                Text('Edit'),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'share',
            child: Row(
              children: [
                Icon(Icons.share, size: 20.w),
                SizedBox(width: 8.w),
                Text('Share'),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete, size: 20, color: Colors.red),
                SizedBox(width: 8.w),
                Text('Delete', style: TextStyle(color: Colors.red)),
              ],
            ),
          ),
        ],
        icon: Icon(PhosphorIcons.dotsThreeVertical,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
      ),
    );
  }
}

Color _statusColor(String status) {
  switch (status) {
    case 'active':
      return Colors.green;
    case 'fulfilled':
      return Colors.blue;
    case 'cancelled':
      return Colors.red;
    default:
      return Colors.grey;
  }
}

String _statusLabel(String status) {
  switch (status) {
    case 'active':
      return 'Active';
    case 'fulfilled':
      return 'Fulfilled';
    case 'cancelled':
      return 'Cancelled';
    default:
      return status;
  }
}
