import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../../data/models/user_model.dart';

class ProfileHeader extends StatelessWidget {
  final UserModel user;
  final String fullName;
  final bool isVerified;
  final List<String> badges;
  final VoidCallback? onEditTap;

  const ProfileHeader({
    super.key,
    required this.user,
    required this.fullName,
    this.isVerified = false,
    this.badges = const [],
    this.onEditTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF991B1B),
            Color(0xFFDC2626),
            Color(0xFFF87171),
          ],
        ),
        borderRadius: BorderRadius.vertical(
          bottom: Radius.elliptical(300, 40),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 32.h, 16.w, 80.h),
              child: Column(
                children: [
                  SizedBox(height: 8.h),
                  CircleAvatar(
                    radius: 52,
                    backgroundColor: Colors.white,
                    child: CircleAvatar(
                      radius: 52,
                      backgroundColor: Colors.white,
                      child: user.image.isEmpty
                          ? Text(
                              fullName.isNotEmpty
                                  ? fullName[0].toUpperCase()
                                  : '',
                              style: TextStyle(
                                fontSize: 40.sp,
                                color: Colors.red.shade600,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(50.r),
                              child: CachedNetworkImage(
                                imageUrl: user.image,
                                width: 100.w,
                                height: 100.h,
                                fit: BoxFit.cover,
                                placeholder: (context, url) =>
                                    const CircularProgressIndicator(
                                        strokeWidth: 2),
                                errorWidget: (context, url, error) => Icon(
                                  PhosphorIcons.warningCircle,
                                  color: Colors.red.shade300,
                                ),
                              ),
                            ),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        fullName,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (isVerified) ...[
                        SizedBox(width: 6.w),
                        Tooltip(
                          message:
                              'This donor has successfully donated blood via BloodFinder.',
                          child: Icon(
                            Icons.verified,
                            size: 22,
                            color: Colors.blue.shade300,
                          ),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    user.mobileNumber,
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                      fontSize: 14.sp,
                    ),
                  ),
                  Text(
                    user.email,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.65),
                      fontSize: 13.sp,
                    ),
                  ),
                  if (badges.isNotEmpty) ...[
                    SizedBox(height: 8.h),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      alignment: WrapAlignment.center,
                      children: badges
                          .map((b) => BadgeChip(badge: b))
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
            Positioned(
              top: 8,
              left: 16.w,
              child: Text(
                'Profile',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (onEditTap != null)
              Positioned(
                top: 4,
                right: 4,
                child: IconButton(
                  icon: Container(
                    width: 36.w,
                    height: 36.h,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      PhosphorIcons.pencil,
                      color: Colors.red.shade600,
                      size: 18,
                    ),
                  ),
                  onPressed: onEditTap,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class BadgeChip extends StatelessWidget {
  final String badge;

  const BadgeChip({required this.badge});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;
    switch (badge) {
      case 'first_hero':
        icon = PhosphorIcons.heart;
        color = Colors.white;
        break;
      case 'bronze':
        icon = PhosphorIcons.shield;
        color = Colors.brown;
        break;
      case 'silver':
        icon = PhosphorIcons.shield;
        color = Colors.grey.shade400;
        break;
      case 'gold':
        icon = PhosphorIcons.star;
        color = Colors.amber;
        break;
      case 'legend':
        icon = PhosphorIcons.crown;
        color = Colors.amber.shade700;
        break;
      default:
        icon = PhosphorIcons.heart;
        color = Colors.white70;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          SizedBox(width: 4.w),
          Text(
            badge
                .replaceAll('_', ' ')
                .split(' ')
                .map((w) =>
                    w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
                .join(' '),
            style: TextStyle(color: Colors.white, fontSize: 11.sp),
          ),
        ],
      ),
    );
  }
}
