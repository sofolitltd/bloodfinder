import 'package:cached_network_image/cached_network_image.dart';

import 'package:flutter/material.dart';

import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import 'package:share_plus/share_plus.dart';

import 'package:url_launcher/url_launcher.dart';

import '../../models/blood_bank.dart';

class BloodBankDetailPage extends StatelessWidget {
  final BloodBank bloodBank;

  const BloodBankDetailPage({super.key, required this.bloodBank});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
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
                  padding: const EdgeInsets.fromLTRB(4, 4, 16, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              PhosphorIcons.arrowLeft,
                              color: Colors.white,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const Spacer(),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: bloodBank.imageUrl != null &&
                                      bloodBank.imageUrl!.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: bloodBank.imageUrl!,
                                      width: 56,
                                      height: 56,
                                      fit: BoxFit.cover,
                                      placeholder: (_, __) =>
                                          const Center(
                                              child:
                                                  CircularProgressIndicator(
                                                      strokeWidth: 2)),
                                      errorWidget: (_, __, ___) => Icon(
                                        PhosphorIcons.hospital,
                                        color: Colors.red.shade200,
                                        size: 28,
                                      ),
                                    )
                                  : Icon(
                                      PhosphorIcons.hospital,
                                      color: Colors.red.shade200,
                                      size: 28,
                                    ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    bloodBank.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (bloodBank.address.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      bloodBank.address,
                                      style: TextStyle(
                                        color: Colors.white
                                            .withValues(alpha: 0.8),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                  if (bloodBank.locationAddress != null &&
                                      bloodBank.locationAddress!.isNotEmpty)
                                    Padding(
                                      padding:
                                          const EdgeInsets.only(top: 2),
                                      child: Text(
                                        bloodBank.locationAddress!,
                                        style: TextStyle(
                                          color: Colors.white
                                              .withValues(alpha: 0.65),
                                          fontSize: 12,
                                        ),
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

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Contact card
                _ContactCard(bloodBank: bloodBank),

                const SizedBox(height: 12),

                // Share card
                _ShareCard(bloodBank: bloodBank),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final BloodBank bloodBank;

  const _ContactCard({required this.bloodBank});

  @override
  Widget build(BuildContext context) {
    final hasPhone = bloodBank.mobile1.isNotEmpty ||
        (bloodBank.mobile2 != null && bloodBank.mobile2!.isNotEmpty);
    final hasSocials = bloodBank.socialMediaLinks != null &&
        bloodBank.socialMediaLinks!.isNotEmpty;

    if (!hasPhone && !hasSocials) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(PhosphorIcons.phoneCall,
                    size: 15, color: Colors.red.shade600),
              ),
              const SizedBox(width: 8),
              Text(
                'Contact',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (bloodBank.mobile1.isNotEmpty)
            _InfoTile(
              icon: PhosphorIcons.phoneCall,
              label: 'Phone',
              value: bloodBank.mobile1,
              onTap: () => _launchUrl('tel:${bloodBank.mobile1}'),
            ),
          if (bloodBank.mobile1.isNotEmpty &&
              bloodBank.mobile2 != null &&
              bloodBank.mobile2!.isNotEmpty)
            const SizedBox(height: 8),
          if (bloodBank.mobile2 != null && bloodBank.mobile2!.isNotEmpty)
            _InfoTile(
              icon: PhosphorIcons.phoneCall,
              label: 'Phone',
              value: bloodBank.mobile2!,
              onTap: () => _launchUrl('tel:${bloodBank.mobile2}'),
            ),
          if (hasSocials) ...[
            if (hasPhone) const SizedBox(height: 8),
            ...bloodBank.socialMediaLinks!.map(
              (link) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _InfoTile(
                  icon: _iconForPlatform(link.platform),
                  label: link.platform,
                  value: link.url,
                  onTap: () => _launchUrl(link.url),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _ShareCard extends StatelessWidget {
  final BloodBank bloodBank;

  const _ShareCard({required this.bloodBank});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              PhosphorIcons.shareNetwork,
              size: 18,
              color: Colors.blue.shade600,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Share this blood bank with others',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          InkWell(
            onTap: () {
              final socials = bloodBank.socialMediaLinks
                      ?.where((l) => l.url.isNotEmpty)
                      .map((l) => '${l.platform}: ${l.url}')
                      .join('\n') ??
                  '';
              SharePlus.instance.share(
                ShareParams(
                  text:
                      '${bloodBank.name} at ${bloodBank.address}.\nContact: ${bloodBank.mobile1}\n${bloodBank.mobile2}\n$socials',
                ),
              );
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Share',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: Colors.red.shade600),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade800,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

IconData _iconForPlatform(String platform) {
  switch (platform) {
    case 'Facebook':
      return PhosphorIcons.facebookLogo;
    case 'WhatsApp':
      return PhosphorIcons.whatsappLogo;
    case 'YouTube':
      return PhosphorIcons.youtubeLogo;
    case 'Instagram':
      return PhosphorIcons.instagramLogo;
    case 'Twitter / X':
      return PhosphorIcons.twitterLogo;
    case 'Telegram':
      return PhosphorIcons.telegramLogo;
    case 'LinkedIn':
      return PhosphorIcons.linkedinLogo;
    case 'TikTok':
      return PhosphorIcons.tiktokLogo;
    case 'Discord':
      return PhosphorIcons.discordLogo;
    case 'Snapchat':
      return PhosphorIcons.snapchatLogo;
    case 'Messenger':
      return PhosphorIcons.messengerLogo;
    default:
      return PhosphorIcons.globe;
  }
}
