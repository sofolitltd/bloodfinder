import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:gal/gal.dart';
import 'package:intl/intl.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../data/models/user_model.dart';
import '../../services/donation_service.dart';

class CertificatePage extends StatefulWidget {
  final UserModel user;
  final int donationCount;
  final String badgeName;

  const CertificatePage({
    super.key,
    required this.user,
    required this.donationCount,
    required this.badgeName,
  });

  String get livesSaved => '${donationCount * 3}';

  @override
  State<CertificatePage> createState() => _CertificatePageState();
}

class _CertificatePageState extends State<CertificatePage> {
  final _repaintKey = GlobalKey();
  bool _saving = false;
  bool _sharing = false;

  Future<Uint8List?> _captureImage() async {
    final boundary =
        _repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;

    final image = await boundary.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  Future<void> _saveToGallery() async {
    setState(() => _saving = true);
    try {
      final png = await _captureImage();
      if (png == null) return;

      await Gal.putImageBytes(
        png,
        name: 'bloodfinder_hero_card_${DateTime.now().millisecondsSinceEpoch}',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved to gallery!')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _share() async {
    setState(() => _sharing = true);
    try {
      final png = await _captureImage();
      if (png == null) return;

      await Share.shareXFiles(
        [XFile.fromData(png, name: 'bloodfinder_hero_card.png')],
        text:
            'I just helped save ${widget.livesSaved} lives with BloodFinder! 🩸',
      );
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final savedText = widget.donationCount > 1
        ? '${widget.livesSaved} lives'
        : '3 lives';
    final totalDonations = widget.donationCount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hero Card'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: RepaintBoundary(
                key: _repaintKey,
                child: Container(
                  width: 340,
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
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.shade200.withValues(alpha: 0.5),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Avatar
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: Colors.white,
                        child: CircleAvatar(
                          radius: 33,
                          backgroundColor: Colors.white,
                          backgroundImage: widget.user.image.isNotEmpty
                              ? CachedNetworkImageProvider(widget.user.image)
                              : null,
                          child: widget.user.image.isEmpty
                              ? Text(
                                  widget.user.firstName.isNotEmpty
                                      ? widget.user.firstName[0].toUpperCase()
                                      : '?',
                                  style: TextStyle(
                                    fontSize: 32,
                                    color: Colors.red.shade700,
                                  ),
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Main headline
                      Text(
                        'I just helped save\n$savedText!',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Name
                      Text(
                        '${widget.user.firstName} ${widget.user.lastName}',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Blood group badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              PhosphorIcons.drop,
                              size: 22,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              widget.user.bloodGroup,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              PhosphorIcons.drop,
                              size: 22,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Badge
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _badgeIcon(widget.badgeName),
                          const SizedBox(width: 8),
                          Text(
                            widget.badgeName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.yellow.shade300,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Donation count
                      Text(
                        '$totalDonations Donation${totalDonations == 1 ? '' : 's'}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Branding
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              PhosphorIcons.heartbeat,
                              size: 16,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'BloodFinder',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white.withValues(alpha: 0.9),
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

          // Bottom buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _saving ? null : _saveToGallery,
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child:
                                CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.download, size: 20),
                    label: const Text('Save Image', style: TextStyle(fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _sharing ? null : _share,
                    icon: _sharing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.share, size: 20),
                    label: const Text('Share', style: TextStyle(fontSize: 13)),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _badgeIcon(String badge) {
    IconData icon;
    Color color;
    switch (badge) {
      case 'First Hero':
        icon = PhosphorIcons.heart;
        color = Colors.red.shade300;
        break;
      case 'Bronze Donor':
        icon = PhosphorIcons.shield;
        color = Colors.brown.shade300;
        break;
      case 'Silver Donor':
        icon = PhosphorIcons.shield;
        color = Colors.grey.shade300;
        break;
      case 'Gold Donor':
        icon = PhosphorIcons.star;
        color = Colors.amber;
        break;
      case 'Legend':
        icon = PhosphorIcons.crown;
        color = Colors.amber.shade700;
        break;
      default:
        icon = PhosphorIcons.heart;
        color = Colors.red.shade300;
    }
    return Icon(icon, size: 26, color: color);
  }
}
