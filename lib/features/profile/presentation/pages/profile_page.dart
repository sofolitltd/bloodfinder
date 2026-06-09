import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../../data/models/user_model.dart';
import '../../../../data/providers/repository_providers.dart';
import '../../../../data/providers/theme_provider.dart';
import '../../../../data/providers/user_providers.dart';
import '../../../donation/presentation/pages/donation_history_page.dart';
import '../widgets/profile_settings.dart';
import '../widgets/profile_stats.dart';
import 'edit_profile_page.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    ));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final userAsync = ref.watch(userProvider);
    final userDocAsync = ref.watch(userDocProvider);
    final donationAsync = ref.watch(donationProvider);
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (UserModel? user) {
          if (user == null) {
            return const Center(child: Text('User data not found.'));
          }

          final rawData = userDocAsync.value?.data();
          final availability =
              rawData?['availability'] as String? ?? 'available';
          final snoozedUntil = rawData?['snoozedUntil'] as Timestamp?;

          if (snoozedUntil != null &&
              snoozedUntil.toDate().isBefore(DateTime.now())) {
            ref.read(userRepositoryProvider).updateUser(user.uid, {
              'availability': 'available',
              'snoozedUntil': FieldValue.delete(),
            });
          }

          final fullName = '${user.firstName} ${user.lastName}'.trim();
          final address = user.locationAddress ?? '';
          final bloodGroup = user.bloodGroup;
          final isDonorStatus = user.isDonor;
          final isEmergencyDonorStatus = user.isEmergencyDonor;
          final isVerified = rawData?['isVerifiedDonor'] as bool? ?? false;
          final badges = (rawData?['badges'] as List<dynamic>?)
                  ?.cast<String>() ??
              [];

          final donations = donationAsync.maybeWhen(
            data: (list) => list,
            orElse: () => [],
          );

          final lifeSavedCount = donations.length;
          DateTime? lastDonationDate;

          if (donations.isNotEmpty) {
            final donationData =
                donations.first.data() as Map<String, dynamic>;
            final donationDateTimestamp =
                donationData['donationDate'] as Timestamp?;
            if (donationDateTimestamp != null) {
              lastDonationDate = donationDateTimestamp.toDate();
            }
          }

          String nextDonationText = 'Your Next';
          String nextDonationDay = '-';
          String nextDonationMonth = '';
          bool isEligible = false;
          if (lastDonationDate != null) {
            final nextDonation = DateTime(
              lastDonationDate.year,
              lastDonationDate.month + 3,
              lastDonationDate.day,
            );
            if (nextDonation.isBefore(DateTime.now())) {
              isEligible = true;
              nextDonationText = 'Tap to donate';
              nextDonationDay = 'Eligible';
              nextDonationMonth = '';
            } else {
              nextDonationText = 'Next Donation';
              nextDonationDay = DateFormat('dd').format(nextDonation);
              nextDonationMonth = DateFormat('MMM').format(nextDonation);
            }
          }

          void navigateToDonationHistory() {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DonationHistoryPage()),
            );
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                // Gradient hero
                Container(
                  width: size.width,
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
                              const Align(
                                alignment: Alignment.centerLeft,
                                child: Padding(
                                  padding: EdgeInsets.only(left: 8),
                                  child: Text(
                                    'Profile',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
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
                                          borderRadius:
                                              BorderRadius.circular(50),
                                          child: CachedNetworkImage(
                                            imageUrl: user.image,
                                            width: 100,
                                            height: 100,
                                            fit: BoxFit.cover,
                                            placeholder: (_, __) =>
                                                const CircularProgressIndicator(
                                                    strokeWidth: 2),
                                            errorWidget: (_, __, ___) => Icon(
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
                                Text(
                                  address,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.65),
                                    fontSize: 12,
                                  ),
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
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const EditProfilePage()),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Stats card (overlapping)
                ProfileStats(
                  bloodGroup: bloodGroup,
                  lifeSavedCount: lifeSavedCount,
                  nextDonationDay: nextDonationDay,
                  nextDonationMonth: nextDonationMonth,
                  nextDonationText: nextDonationText,
                  isEligible: isEligible,
                  onDonateTap: navigateToDonationHistory,
                ),
                const SizedBox(height: 4),

                // Animated settings
                FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: ProfileSettings(
                        uid: user.uid,
                        isDonorStatus: isDonorStatus,
                        isEmergencyDonorStatus: isEmergencyDonorStatus,
                        availability: availability,
                        snoozedUntil: snoozedUntil?.toDate(),
                        dateOfBirth: user.dateOfBirth,
                        themeMode: themeMode,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
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
