import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '/data/models/user_model.dart';
import '/data/providers/theme_provider.dart';
import '/data/providers/user_providers.dart';
import '/features/account/edit_profile_page.dart';
import '../../routes/app_route.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider);
    final donationAsync = ref.watch(donationProvider);
    final themeMode = ref.watch(themeModeProvider);
    final themeNotifier = ref.read(themeModeProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.red.shade700,
        surfaceTintColor: Colors.red.shade700,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EditProfilePage()),
              );
            },
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (UserModel? user) {
          if (user == null) {
            return const Center(child: Text('User data not found.'));
          }

          final fullName = '${user.firstName} ${user.lastName}'.trim();
          final address =
              '${user.currentAddress}, ${user.subdistrict}, ${user.district}';
          final bloodGroup = user.bloodGroup;
          final isDonorStatus = user.isDonor;
          final isEmergencyDonorStatus = user.isEmergencyDonor;

          // Donations
          final donations = donationAsync.maybeWhen(
            data: (list) => list,
            orElse: () => [],
          );

          final lifeSavedCount = donations.length;
          DateTime? lastDonationDate;

          if (donations.isNotEmpty) {
            // Explicitly cast to Timestamp before calling .toDate()
            final donationData = donations.first.data() as Map<String, dynamic>;
            final donationDateTimestamp =
                donationData['donationDate'] as Timestamp?;

            if (donationDateTimestamp != null) {
              lastDonationDate = donationDateTimestamp.toDate();
            }
          }

          String nextDonationText = '0 Donation';
          String nextDonationDay = '-';
          String nextDonationMonth = '';
          if (lastDonationDate != null) {
            final nextDonation = DateTime(
              lastDonationDate.year,
              lastDonationDate.month + 3,
              lastDonationDate.day,
            );
            nextDonationText = 'Next donation';
            nextDonationDay = DateFormat('dd').format(nextDonation);
            nextDonationMonth = DateFormat('MMMM').format(nextDonation);
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                // Profile header
                Container(
                  width: double.infinity,
                  color: Colors.red.shade700,
                  padding: const EdgeInsets.only(top: 8, bottom: 8),
                  child: Column(
                    children: [
                      //
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white,
                        child: user.image.isEmpty
                            ? Text(
                                fullName.isNotEmpty
                                    ? fullName[0].toUpperCase()
                                    : '',
                                style: TextStyle(
                                  fontSize: 40,
                                  color: Colors.grey.shade400,
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
                                      CircularProgressIndicator(strokeWidth: 2),
                                  errorWidget: (context, url, error) =>
                                      Icon(Icons.error, color: Colors.red),
                                ),
                              ),
                      ),

                      //
                      const SizedBox(height: 10),
                      Text(
                        fullName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        user.mobileNumber,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        user.email,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (address.isNotEmpty)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 16,
                              color: Colors.white70,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              address,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),

                // Info row
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 16,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildInfoColumn(
                          Icons.bloodtype,
                          Colors.red.shade700,
                          '$bloodGroup Group',
                        ),
                        _buildInfoColumn(
                          Icons.favorite,
                          Colors.red.shade700,
                          '$lifeSavedCount Life Saved',
                        ),
                        Column(
                          children: [
                            RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: nextDonationDay,
                                    style: TextStyle(
                                      color: Colors.red.shade700,
                                      fontSize: 25,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  TextSpan(
                                    text: ' $nextDonationMonth',
                                    style: TextStyle(
                                      color: Colors.red.shade700,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              nextDonationText,
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Donor switch
                Card(
                  margin: const EdgeInsets.only(top: 8),
                  child: ListTile(
                    contentPadding: const EdgeInsets.only(left: 16, right: 12),
                    leading: const Icon(Icons.check_circle_outline, size: 24),
                    title: Text(
                      'Available To Donate',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    trailing: Switch(
                      value: isDonorStatus,
                      onChanged: (value) async {
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(user.uid)
                            .update({'isDonor': value});

                        //
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isEmergencyDonorStatus
                                  ? 'You are no longer a donor.'
                                  : 'You are now a donor.',
                            ),
                          ),
                        );
                      },
                      activeThumbColor: Colors.red.shade700,
                    ),
                    onTap: () async {
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(user.uid)
                          .update({'isDonor': !isDonorStatus});
                    },
                  ),
                ),

                // Emergency donor
                Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    contentPadding: const EdgeInsets.only(left: 16, right: 12),
                    leading: const Icon(Icons.check_circle_outline, size: 24),
                    title: Text(
                      'Emergency Donor',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    trailing: Switch(
                      value: isEmergencyDonorStatus,
                      onChanged: (value) async {
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(user.uid)
                            .update({'isEmergencyDonor': value});
                        // show snackbar, change color. suitable message
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isEmergencyDonorStatus
                                  ? 'You are no longer an emergency donor.'
                                  : 'You are now an emergency donor.',
                            ),
                          ),
                        );
                      },
                      activeThumbColor: Colors.red.shade700,
                    ),
                    onTap: () async {
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(user.uid)
                          .update({
                            'isEmergencyDonor': !isEmergencyDonorStatus,
                          });
                    },
                  ),
                ),

                // Theme toggle
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Icon(
                          themeMode == ThemeMode.light
                              ? Icons.light_mode
                              : Icons.dark_mode,
                          color: themeMode == ThemeMode.light
                              ? Colors.orange
                              : Colors.red,
                        ),
                        const SizedBox(width: 16),
                        Text(
                          'Change Theme',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const Spacer(),
                        Switch.adaptive(
                          value: themeMode == ThemeMode.dark,
                          onChanged: (_) => themeNotifier.toggleTheme(),
                        ),
                      ],
                    ),
                  ),
                ),

                // Navigation options
                Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Column(
                      spacing: 8,
                      children: [
                        _buildProfileOption(
                          Icons.scatter_plot,
                          'My Blood Requests',
                          () {
                            context.pushNamed(AppRoute.bloodRequest.name);
                          },
                        ),
                        _buildProfileOption(
                          Icons.history,
                          'My Donation History',
                          () {
                            context.pushNamed(AppRoute.bloodRequest.name);
                          },
                        ),

                        _buildProfileOption(
                          Icons.history,
                          'Community Page',
                          () {
                            context.pushNamed(AppRoute.community.name);
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                // Log out
                Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await FirebaseMessaging.instance.deleteToken();
                        await FirebaseAuth.instance.signOut();
                      },
                      icon: const Icon(Icons.logout),
                      label: const Text('Log Out'),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoColumn(IconData icon, Color iconColor, String text) {
    return Column(
      children: [
        Icon(icon, color: iconColor, size: 32),
        const SizedBox(height: 5),
        Text(text, style: TextStyle(color: Colors.grey[700], fontSize: 14)),
      ],
    );
  }

  Widget _buildProfileOption(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      visualDensity: VisualDensity.compact,
      leading: Icon(icon, size: 28),
      title: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 18,
        color: Colors.grey,
      ),
      onTap: onTap,
    );
  }
}
