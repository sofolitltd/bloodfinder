import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../../data/models/user_model.dart';

class ProfileHeader extends StatelessWidget {
  final UserModel user;
  final String fullName;
  final String address;
  final bool isVerified;
  final List<String> badges;
  final VoidCallback? onEditTap;

  const ProfileHeader({
    super.key,
    required this.user,
    required this.fullName,
    required this.address,
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
              padding: const EdgeInsets.fromLTRB(4, 16, 16, 32),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  CircleAvatar(
                    radius: 52,
                    backgroundColor: Colors.white,
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.white,
                      child: user.image.isEmpty
                          ? Text(
                              fullName.isNotEmpty
                                  ? fullName[0].toUpperCase()
                                  : '',
                              style: TextStyle(
                                fontSize: 40,
                                color: Colors.red.shade600,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(50),
                              child: CachedNetworkImage(
                                imageUrl: user.image,
                                width: 100,
                                height: 100,
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
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        fullName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (isVerified) ...[
                        const SizedBox(width: 6),
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
                  const SizedBox(height: 4),
                  Text(
                    user.mobileNumber,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    user.email,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.65),
                      fontSize: 13,
                    ),
                  ),
                  if (address.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          PhosphorIcons.mapPin,
                          size: 14,
                          color: Colors.white.withValues(alpha: 0.65),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            address,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.65),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (badges.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      alignment: WrapAlignment.center,
                      children: badges
                          .map((b) => _BadgeChip(badge: b))
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
            if (onEditTap != null)
              Positioned(
                top: 4,
                right: 4,
                child: IconButton(
                  icon: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
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

class _BadgeChip extends StatelessWidget {
  final String badge;

  const _BadgeChip({required this.badge});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;
    switch (badge) {
      case 'first_hero':
        icon = PhosphorIcons.heart;
        color = Colors.red.shade300;
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            badge
                .replaceAll('_', ' ')
                .split(' ')
                .map((w) =>
                    w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
                .join(' '),
            style: const TextStyle(color: Colors.white, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
