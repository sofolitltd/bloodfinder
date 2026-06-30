import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/rendering.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../data/models/user_model.dart';

class CertificatePage extends StatefulWidget {
  final UserModel user;
  final int donationCount;
  final String badgeName;
  final String? donationImageUrl;

  const CertificatePage({
    super.key,
    required this.user,
    required this.donationCount,
    required this.badgeName,
    this.donationImageUrl,
  });

  @override
  State<CertificatePage> createState() => _CertificatePageState();
}

class _CertificatePageState extends State<CertificatePage> {
  final _repaintKey = GlobalKey();
  bool _saving = false;
  bool _sharing = false;
  int _selectedDesign = 0;

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
    } on GalException catch (e) {
      if (e.type == GalExceptionType.accessDenied && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gallery permission denied. Enable it in Settings.'),
          ),
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

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/bloodfinder_hero_card.png');
      await file.writeAsBytes(png);

      final lifeText = widget.donationCount == 1 ? 'life' : 'lives';
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text:
              'I just helped save ${widget.donationCount} $lifeText with BloodFinder! 🩸',
        ),
      );

      file.delete();
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final savedText = widget.donationCount > 0
        ? '${widget.donationCount} ${widget.donationCount == 1 ? 'life' : 'lives'}'
        : 'Start saving lives';
    final hasPhoto = widget.donationImageUrl != null &&
        widget.donationImageUrl!.isNotEmpty;

    // Fall back to design 0 only if photo exists
    if (!hasPhoto && _selectedDesign == 0) _selectedDesign = 1;

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
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _buildCard(context, savedText, hasPhoto),
                ),
              ),
            ),
          ),

          SizedBox(height: 8.h),

          // Design selector
          SizedBox(
            height: 56.h,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Row(
                children: [
                ..._buildDesignThumbnails(hasPhoto),
              ],
            ),
            ),
          ),
          SizedBox(height: 8.h),

          // Bottom buttons
          Padding(
            padding: EdgeInsets.fromLTRB(24.w, 0.h, 24.w, 24.h),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _saving ? null : _saveToGallery,
                    icon: _saving
                        ? SizedBox(
                            width: 18.w,
                            height: 18.h,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(Icons.download, size: 20.w),
                    label: Text('Save Image', style: TextStyle(fontSize: 13.sp)),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _sharing ? null : _share,
                    icon: _sharing
                        ? SizedBox(
                            width: 18.w,
                            height: 18.h,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(Icons.share, size: 20.w),
                    label: Text('Share', style: TextStyle(fontSize: 13.sp)),
                    style: FilledButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 14.h),
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

  // ── Card Builder ──
  Widget _buildCard(BuildContext context, String savedText, bool hasPhoto) {
    switch (_selectedDesign) {
      case 0:
        return _buildDesignPhoto(context, savedText);
      case 1:
        return _buildDesignClassic(context, savedText);
      case 2:
        return _buildDesignMinimal(context, savedText);
      case 3:
        return _buildDesignDark(context, savedText);
      default:
        return _buildDesignClassic(context, savedText);
    }
  }

  // ── Design 0: Photo Hero ──
  Widget _buildDesignPhoto(BuildContext context, String savedText) {
    return Container(
      key: const ValueKey(0),
      width: 340.w,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildPhotoHeroSection(context, savedText),
          _buildContentSection(context, savedText, Colors.grey.shade600, Colors.red.shade700, Colors.grey.shade800, Colors.grey.shade500),
        ],
      ),
    );
  }

  Widget _buildPhotoHeroSection(BuildContext context, String savedText) {
    return Stack(
      children: [
        Image.network(
          widget.donationImageUrl!,
          height: 200.h,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildGradientHeader(context),
        ),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.7),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: 20.w,
          bottom: 16.h,
          child: Row(
            children: [
              _buildMiniAvatar(22, 20),
              SizedBox(width: 10.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${widget.user.firstName} ${widget.user.lastName}',
                    style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Text(savedText, style: TextStyle(fontSize: 12.sp, color: Colors.white.withValues(alpha: 0.8))),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Design 1: Classic Red ──
  Widget _buildDesignClassic(BuildContext context, String savedText) {
    return Container(
      key: const ValueKey(1),
      width: 340.w,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildGradientHeader(context),
          _buildContentSection(context, savedText, Colors.grey.shade600, Colors.red.shade700, Colors.grey.shade800, Colors.grey.shade500),
        ],
      ),
    );
  }

  Widget _buildGradientHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 28.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.red.shade800, Colors.red.shade600, Colors.red.shade400],
        ),
      ),
      child: Column(
        children: [
          _buildMiniAvatar(32, 29),
          SizedBox(height: 8.h),
          Text(
            '${widget.user.firstName} ${widget.user.lastName}',
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600, color: Colors.white),
          ),
        ],
      ),
    );
  }

  // ── Design 2: Minimal White ──
  Widget _buildDesignMinimal(BuildContext context, String savedText) {
    return Container(
      key: const ValueKey(2),
      width: 340.w,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 28.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildMiniAvatar(36, 33),
            SizedBox(height: 12.h),
            _buildContentSection(context, savedText, Colors.grey.shade600, Colors.red.shade700, Colors.grey.shade800, Colors.grey.shade500),
          ],
        ),
      ),
    );
  }

  // ── Design 3: Dark Premium ──
  Widget _buildDesignDark(BuildContext context, String savedText) {
    return Container(
      key: const ValueKey(3),
      width: 340.w,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.r),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [const Color(0xFF1A1A2E), const Color(0xFF2D2D44)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 28.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildMiniAvatarDark(36, 33),
            SizedBox(height: 12.h),
            _buildContentSection(context, savedText, Colors.white.withValues(alpha: 0.6), Colors.amber.shade400, Colors.white, Colors.white.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }

  // ── Shared Content Section ──
  Widget _buildContentSection(
    BuildContext context,
    String savedText,
    Color subtitleColor,
    Color headlineColor,
    Color nameColor,
    Color countColor,
  ) {
    return Padding(
      padding: EdgeInsets.all(24.w),
      child: Column(
        children: [
          Text.rich(
            TextSpan(
              children: [
                TextSpan(text: 'I just helped save\n', style: TextStyle(fontSize: 15.sp, color: subtitleColor)),
                TextSpan(
                  text: savedText,
                  style: TextStyle(fontSize: 28.sp, fontWeight: FontWeight.bold, color: headlineColor, height: 1.2),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 12.h),
          Text(
            '${widget.user.firstName} ${widget.user.lastName}',
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600, color: nameColor),
          ),
          SizedBox(height: 12.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildPill(PhosphorIcons.drop, widget.user.bloodGroup, Colors.red.shade50, Colors.red.shade700),
              SizedBox(width: 8.w),
              _buildPill(_badgeIconData(widget.badgeName), widget.badgeName, Colors.amber.shade50, _badgeColor(widget.badgeName)),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            '${widget.donationCount} Donation${widget.donationCount == 1 ? '' : 's'}',
            style: TextStyle(fontSize: 13.sp, color: countColor),
          ),
          SizedBox(height: 16.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(PhosphorIcons.heartbeat, size: 16, color: headlineColor),
              SizedBox(width: 6.w),
              Text(
                'BloodFinder',
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: headlineColor),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Avatar Helpers ──
  Widget _buildMiniAvatar(double outerRadius, double innerRadius) {
    return CircleAvatar(
      radius: outerRadius,
      backgroundColor: Colors.white,
      child: CircleAvatar(
        radius: innerRadius,
        backgroundColor: Colors.white,
        backgroundImage: widget.user.image.isNotEmpty
            ? CachedNetworkImageProvider(widget.user.image)
            : null,
        child: widget.user.image.isEmpty
            ? Text(
                widget.user.firstName.isNotEmpty ? widget.user.firstName[0].toUpperCase() : '?',
                style: TextStyle(fontSize: 24.sp, color: Colors.red.shade700),
              )
            : null,
      ),
    );
  }

  Widget _buildMiniAvatarDark(double outerRadius, double innerRadius) {
    return CircleAvatar(
      radius: outerRadius,
      backgroundColor: Colors.white.withValues(alpha: 0.15),
      child: CircleAvatar(
        radius: innerRadius,
        backgroundColor: Colors.white.withValues(alpha: 0.15),
        backgroundImage: widget.user.image.isNotEmpty
            ? CachedNetworkImageProvider(widget.user.image)
            : null,
        child: widget.user.image.isEmpty
            ? Text(
                widget.user.firstName.isNotEmpty ? widget.user.firstName[0].toUpperCase() : '?',
                style: TextStyle(fontSize: 24.sp, color: Colors.white),
              )
            : null,
      ),
    );
  }

  // ── Design Thumbnails ──
  List<Widget> _buildDesignThumbnails(bool hasPhoto) {
    final items = <_DesignOption>[
      if (hasPhoto) _DesignOption(0, 'Photo', Colors.white, Colors.red.shade100, null, Icons.photo, Colors.white70),
      _DesignOption(1, 'Classic', Colors.red.shade700, Colors.red.shade400, null, Icons.palette, Colors.white70),
      _DesignOption(2, 'Minimal', Colors.white, Colors.grey.shade100, Colors.red.shade600, Icons.palette, Colors.red.shade400),
      _DesignOption(3, 'Dark', const Color(0xFF1A1A2E), const Color(0xFF2D2D44), Colors.amber.shade600, Icons.star, Colors.amber.shade400),
    ];
    return List.generate(items.length * 2 - 1, (i) {
      if (i.isOdd) return SizedBox(width: 10.w);
      final item = items[i ~/ 2];
      return _DesignThumbnailWidget(
        index: item.index,
        label: item.label,
        topColor: item.topColor,
        bottomColor: item.bottomColor,
        icon: item.icon,
        iconColor: item.iconColor,
        selected: _selectedDesign == item.index,
        onTap: () => setState(() => _selectedDesign = item.index),
      );
    });
  }

  // ── Design Thumbnail Widget ──
  Widget _DesignThumbnailWidget({
    required int index,
    required String label,
    required Color topColor,
    required Color bottomColor,
    required IconData icon,
    required Color iconColor,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 56.w,
        height: 52.h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(
            color: selected ? Colors.red : Colors.grey.shade300,
            width: selected ? 2.5 : 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(9.r),
          child: Column(
            children: [
              Expanded(
                flex: 3,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: index == 3
                        ? LinearGradient(colors: [const Color(0xFF1A1A2E), const Color(0xFF2D2D44)])
                        : LinearGradient(
                            colors: index == 2 ? [Colors.white, Colors.white] : [topColor, bottomColor],
                          ),
                  ),
                  child: Center(child: Icon(icon, size: 14, color: iconColor)),
                ),
              ),
              Expanded(
                flex: 2,
                child: Container(
                  color: index == 3 ? const Color(0xFF1A1A2E) : Colors.white,
                  child: Center(
                    child: Text(label, style: TextStyle(fontSize: 7.sp, color: index == 3 ? Colors.white70 : Colors.grey.shade700)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Pill Helper ──
  Widget _buildPill(IconData icon, String label, Color bg, Color fg) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: fg.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: fg),
          SizedBox(width: 6.w),
          Text(label, style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600, color: fg)),
        ],
      ),
    );
  }

  IconData _badgeIconData(String badge) {
    switch (badge) {
      case 'First Hero': return PhosphorIcons.heart;
      case 'Bronze Donor': return PhosphorIcons.shield;
      case 'Silver Donor': return PhosphorIcons.shieldStar;
      case 'Gold Donor': return PhosphorIcons.star;
      case 'Legend': return PhosphorIcons.crown;
      default: return PhosphorIcons.heart;
    }
  }

  Color _badgeColor(String badge) {
    switch (badge) {
      case 'First Hero': return Colors.red;
      case 'Bronze Donor': return Colors.brown;
      case 'Silver Donor': return Colors.grey.shade600;
      case 'Gold Donor': return Colors.amber.shade700;
      case 'Legend': return Colors.amber.shade900;
      default: return Colors.red;
    }
  }
}

class _DesignOption {
  final int index;
  final String label;
  final Color topColor;
  final Color bottomColor;
  final Color? accentColor;
  final IconData icon;
  final Color iconColor;

  const _DesignOption(this.index, this.label, this.topColor, this.bottomColor, this.accentColor, this.icon, this.iconColor);
}
