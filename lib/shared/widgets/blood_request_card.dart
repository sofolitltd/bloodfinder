import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../data/providers/repository_providers.dart';
import '../../features/blood_request/models/blood_request.dart';
import '../../data/models/user_model.dart';
import '../../features/donation/presentation/pages/donation_page.dart';

class BloodRequestCard extends ConsumerWidget {
  const BloodRequestCard({super.key, required this.request, this.embedded = false, this.distanceInKm, this.onDelete, this.onEdit});

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
            borderRadius: BorderRadius.circular(16),
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
      borderRadius: BorderRadius.circular(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 64,
                  height: 68,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.red.shade600,
                        Colors.red.shade400,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(PhosphorIcons.dropFill, size: 18, color: Colors.white),
                      const SizedBox(height: 2),
                      Text(
                        request.bloodGroup,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
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
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.grey.shade200 : Colors.grey.shade800,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _statusColor(request.status).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _statusLabel(request.status),
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: _statusColor(request.status),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 7,
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
                                      fontSize: 8,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade600,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Posted by ${user.firstName} ${user.lastName}',
                            style: TextStyle(
                              fontSize: 10,
                              color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(PhosphorIcons.hospital, size: 14, color: Colors.grey.shade500),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              request.address,
                              style: TextStyle(
                                fontSize: 12,
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
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Icon(PhosphorIcons.mapPin, size: 13, color: Colors.grey.shade500),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                request.locationAddress!,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(PhosphorIcons.clock, size: 14, color: Colors.grey.shade500),
                          const SizedBox(width: 5),
                          Text(
                            '${formatDate(request.date)} at ${formatTime(request.time)}',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                      if (distanceInKm != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(PhosphorIcons.mapPin, size: 14, color: Colors.red.shade400),
                            const SizedBox(width: 5),
                            Text(
                              '${distanceInKm!.toStringAsFixed(1)} km away',
                              style: TextStyle(
                                fontSize: 11,
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
                const SizedBox(width: 4),
                InkWell(
                  onTap: shareRequest,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey.shade700.withValues(alpha: 0.3) : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      PhosphorIcons.share,
                      size: 16,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.red.shade600, Colors.red.shade500],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(PhosphorIcons.heart, size: 16, color: Colors.white.withValues(alpha: 0.9)),
                const SizedBox(width: 8),
                Text(
                  'Donate Now',
                  style: TextStyle(
                    fontSize: 14,
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: Colors.redAccent.shade200,
                child: user.image.isEmpty
                    ? Text(
                        user.firstName.isNotEmpty
                            ? user.firstName[0].toUpperCase()
                            : '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                        ),
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(50),
                        child: CachedNetworkImage(
                          imageUrl: user.image,
                          width: 44,
                          height: 44,
                          fit: BoxFit.cover,
                          placeholder: (context, url) =>
                              const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2)),
                          errorWidget: (context, url, error) => Icon(
                            PhosphorIcons.warningCircle,
                            color: Colors.red,
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${user.firstName} ${user.lastName}',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? Colors.grey.shade200
                            : Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('dd MMM yyy - hh:mm a')
                          .format(request.createdAt),
                      style: TextStyle(
                        fontSize: 12,
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
          const SizedBox(height: 8),
          Divider(
            height: 1,
            thickness: 1,
            color: isDark
                ? Colors.grey.shade600.withValues(alpha: 0.5)
                : Colors.grey.shade300,
          ),
          const SizedBox(height: 12),
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
                    const SizedBox(height: 10),
                    _InfoTile(
                      icon: PhosphorIcons.drop,
                      iconColor: Colors.red.shade400,
                      label: 'Blood Group',
                      value: request.bloodGroup,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 10),
                    _InfoTile(
                      icon: PhosphorIcons.calendar,
                      iconColor: Colors.orange.shade400,
                      label: 'Date',
                      value: formatDate(request.date),
                      isDark: isDark,
                    ),
                    if (distanceInKm != null) ...[
                      const SizedBox(height: 10),
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
              const SizedBox(width: 12),
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
                    const SizedBox(height: 10),
                    _InfoTile(
                      icon: PhosphorIcons.heartbeat,
                      iconColor: Colors.red.shade400,
                      label: 'Bags Needed',
                      value: request.bag,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 10),
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
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.grey.shade700.withValues(alpha: 0.15)
                  : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
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
                  const SizedBox(height: 8),
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
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
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
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: iconColor),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
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
          const PopupMenuItem(
            value: 'edit',
            child: Row(
              children: [
                Icon(Icons.edit, size: 20),
                SizedBox(width: 8),
                Text('Edit'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'share',
            child: Row(
              children: [
                Icon(Icons.share, size: 20),
                SizedBox(width: 8),
                Text('Share'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete, size: 20, color: Colors.red),
                SizedBox(width: 8),
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
