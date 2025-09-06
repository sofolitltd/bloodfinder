// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:intl/intl.dart';
//
// import '/features/account/edit_account_page.dart';
// import '/features/blood_request/my_blood_request.dart';
// import '/features/donation/donation_history.dart';
// import '../../data/providers/theme_provider.dart';
//
// class AccountPage extends StatefulWidget {
//   const AccountPage({super.key});
//
//   @override
//   State<AccountPage> createState() => _AccountPageState();
// }
//
// class _AccountPageState extends State<AccountPage> {
//   Map<String, dynamic>? _userData;
//   int _lifeSavedCount = 0; // New state variable for life saved
//   DateTime? _lastDonationDate; // New state variable for last donation date
//   bool _isLoading = false;
//   bool _isLogOutLoading = false;
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchUserProfileAndDonations(); // Combined fetch operation
//   }
//
//   Future<void> _fetchUserProfileAndDonations() async {
//     setState(() {
//       _isLoading = true;
//     });
//     try {
//       final user = FirebaseAuth.instance.currentUser;
//       if (user != null) {
//         // 1. Fetch main user profile data
//         DocumentSnapshot userDoc = await FirebaseFirestore.instance
//             .collection('users')
//             .doc(user.uid)
//             .get();
//
//         if (userDoc.exists) {
//           _userData = userDoc.data() as Map<String, dynamic>;
//         } else {
//           print('User document does not exist for UID: ${user.uid}');
//           _showMessage('User data not found.', isError: true);
//         }
//
//         // 2. Fetch donation subcollection data
//         QuerySnapshot donationSnapshot = await FirebaseFirestore.instance
//             .collection('users')
//             .doc(user.uid)
//             .collection('donation')
//             .orderBy(
//               'donationDate',
//               descending: true,
//             ) // Order by date to get the latest
//             .get();
//
//         _lifeSavedCount =
//             donationSnapshot.docs.length; // Count of donation documents
//
//         if (donationSnapshot.docs.isNotEmpty) {
//           // Get the latest donation document's date
//           _lastDonationDate =
//               (donationSnapshot.docs.first.data()
//                       as Map<String, dynamic>)['donationDate']
//                   ?.toDate();
//         } else {
//           _lastDonationDate = null; // No donations yet
//         }
//       } else {
//         print('No user logged in.');
//         _showMessage('Please log in to view profile.', isError: true);
//       }
//     } catch (e) {
//       print('Error fetching user profile or donations: $e');
//       _showMessage('Failed to load profile data.', isError: true);
//     } finally {
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }
//
//   Future<void> _updateIsDonorStatus(bool newValue) async {
//     setState(() {
//       if (_userData != null) {
//         _userData!['isDonor'] = newValue; // Optimistic update
//       }
//     });
//
//     try {
//       final user = FirebaseAuth.instance.currentUser;
//       if (user != null) {
//         await FirebaseFirestore.instance
//             .collection('users')
//             .doc(user.uid)
//             .update({'isDonor': newValue});
//         _showMessage('Donor status updated successfully.', isError: false);
//       }
//     } catch (e) {
//       print('Error updating donor status: $e');
//       _showMessage('Failed to update donor status.', isError: true);
//       // Revert local state if update fails
//       setState(() {
//         if (_userData != null) {
//           _userData!['isDonor'] = !newValue;
//         }
//       });
//     }
//   }
//
//   Future<void> _handleLogout() async {
//     try {
//       setState(() => _isLogOutLoading = true);
//
//       // log out, go router manage to go login page
//       await FirebaseAuth.instance.signOut();
//       // _showMessage('Logged out successfully.', isError: false);
//     } catch (e) {
//       print('Error logging out: $e');
//       _showMessage('Failed to log out.', isError: true);
//     } finally {
//       if (mounted) {
//         setState(() => _isLogOutLoading = false);
//       }
//     }
//   }
//
//   void _showMessage(String message, {bool isError = false}) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: isError ? Colors.red : Colors.green,
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     if (_isLoading) {
//       return const Scaffold(body: Center(child: CircularProgressIndicator()));
//     }
//
//     // Default values if _userData is null or incomplete
//     final String firstName = _userData?['firstName'] ?? 'User';
//     final String lastName = _userData?['lastName'] ?? '';
//     final String fullName = '$firstName $lastName'.trim();
//     final String mobileNumber = _userData?['mobileNumber'] ?? 'N/A';
//     final String email = _userData?['email'] ?? 'N/A';
//     final String address =
//         "${_userData?['address'][0]['subdistrict']}, ${_userData?['address'][0]['district']}" ??
//         'N/A';
//     final String bloodGroup = _userData?['bloodGroup'] ?? 'Unknown';
//     final bool isDonorStatus = _userData?['isDonor'] ?? false;
//
//     // Calculate next donation date (e.g., 3 months after last donation)
//     String nextDonationText = '0 Donation';
//     String nextDonationDay = '-';
//     String nextDonationMonth = '';
//
//     if (_lastDonationDate != null) {
//       final DateTime nextDonationCalculatedDate = DateTime(
//         _lastDonationDate!.year,
//         _lastDonationDate!.month + 3, // Add 3 months
//         _lastDonationDate!.day,
//       );
//       nextDonationText = 'Next donation';
//       nextDonationDay = DateFormat('dd').format(nextDonationCalculatedDate);
//       nextDonationMonth = DateFormat('MMMM').format(nextDonationCalculatedDate);
//     }
//
//     return Scaffold(
//       appBar: AppBar(
//         automaticallyImplyLeading: false,
//         backgroundColor: Colors.red.shade700,
//         elevation: 0,
//         surfaceTintColor: Colors.red.shade700,
//         title: Text('Profile', style: TextStyle(color: Colors.white)),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.edit, color: Colors.white),
//             onPressed: () {
//               // go to edit ac page
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (context) => const EditAccountPage(),
//                 ),
//               );
//             },
//           ),
//           const SizedBox(width: 10),
//         ],
//       ),
//       body: SingleChildScrollView(
//         child: Column(
//           children: [
//             // Top Red Section - Profile Header
//             Container(
//               width: double.infinity,
//               decoration: BoxDecoration(color: Colors.red.shade700),
//               child: Column(
//                 children: [
//                   CircleAvatar(
//                     radius: 50,
//                     backgroundColor: Colors.white,
//                     child: Text(
//                       fullName.substring(0, 1),
//                       style: TextStyle(
//                         fontSize: 40,
//                         color: Colors.grey.shade400,
//                         // fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//
//                   //
//                   const SizedBox(height: 10),
//                   Text(
//                     fullName,
//                     style: const TextStyle(
//                       color: Colors.white,
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   Text(
//                     mobileNumber,
//                     style: const TextStyle(color: Colors.white70, fontSize: 16),
//                   ),
//                   Text(
//                     email,
//                     style: const TextStyle(color: Colors.white70, fontSize: 14),
//                   ),
//                   const SizedBox(height: 4),
//
//                   Row(
//                     spacing: 4,
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Icon(
//                         Icons.location_on_outlined,
//                         size: 16,
//                         color: Colors.white70,
//                       ),
//                       Text(
//                         address,
//                         style: const TextStyle(
//                           color: Colors.white70,
//                           fontSize: 12,
//                         ),
//                       ),
//                     ],
//                   ),
//
//                   const SizedBox(height: 24),
//                 ],
//               ),
//             ),
//
//             //
//             Card(
//               child: Padding(
//                 padding: const EdgeInsets.symmetric(
//                   vertical: 16,
//                   horizontal: 16,
//                 ),
//
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     _buildInfoColumn(
//                       icon: Icons.bloodtype,
//                       iconColor: Colors.red.shade700,
//                       text: '$bloodGroup Group',
//                     ),
//                     _buildInfoColumn(
//                       icon: Icons.favorite,
//                       iconColor: Colors.red.shade700,
//                       text:
//                           '$_lifeSavedCount Life Saved', // Dynamic life saved count
//                     ),
//
//                     //
//                     Column(
//                       children: [
//                         RichText(
//                           text: TextSpan(
//                             children: [
//                               TextSpan(
//                                 text: nextDonationDay, // Dynamic day
//                                 style: TextStyle(
//                                   color: Colors.red.shade700,
//                                   fontSize: 25,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                               ),
//                               TextSpan(
//                                 text: ' $nextDonationMonth', // Dynamic month
//                                 style: TextStyle(
//                                   color: Colors.red.shade700,
//                                   fontSize: 14,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                         const SizedBox(height: 5),
//
//                         Text(
//                           nextDonationText,
//                           // "Next donation" or "Ready for first donation"
//                           style: TextStyle(
//                             color: Colors.grey[700],
//                             fontSize: 14,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//
//             const SizedBox(height: 4),
//
//             Card(
//               child: _buildProfileOption(
//                 icon: Icons.check_circle_outline,
//                 title: 'Available To Donate',
//                 trailing: Switch(
//                   value: isDonorStatus,
//                   onChanged: _updateIsDonorStatus,
//                   activeThumbColor: Colors.red.shade700,
//                 ),
//                 onTap: () {
//                   _updateIsDonorStatus(!isDonorStatus);
//                 },
//               ),
//             ),
//
//             const SizedBox(height: 16),
//
//             //
//             Consumer(
//               builder: (context, ref, child) {
//                 final currentThemeMode = ref.watch(themeModeProvider);
//                 // Access the notifier to call its methods (e.g., toggleTheme).
//                 final themeNotifier = ref.read(themeModeProvider.notifier);
//
//                 //
//                 return Card(
//                   child: Padding(
//                     padding: const EdgeInsets.symmetric(
//                       vertical: 8,
//                       horizontal: 16,
//                     ),
//                     child: Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       crossAxisAlignment: CrossAxisAlignment.center,
//                       children: [
//                         Icon(
//                           currentThemeMode == ThemeMode.light
//                               ? Icons.light_mode
//                               : Icons.dark_mode,
//                           color: currentThemeMode == ThemeMode.light
//                               ? Colors.orange
//                               : Colors.red,
//                         ),
//
//                         const SizedBox(width: 16),
//
//                         //
//                         Text(
//                           'Change Theme',
//                           style: Theme.of(context).textTheme.titleMedium,
//                         ),
//
//                         Spacer(),
//                         //
//                         Switch.adaptive(
//                           value:
//                               currentThemeMode ==
//                               ThemeMode.dark, // True if dark mode is active
//                           onChanged: (bool value) {
//                             themeNotifier
//                                 .toggleTheme(); // Call the toggle method
//                           },
//                         ),
//                       ],
//                     ),
//                   ),
//                 );
//               },
//             ),
//
//             Card(
//               child: Padding(
//                 padding: const EdgeInsets.only(bottom: 8),
//                 child: Column(
//                   children: [
//                     // _buildProfileOption(
//                     //   icon: Icons.location_on_outlined,
//                     //   title: 'Manage Address',
//                     //   onTap: () {
//                     //     _showMessage('Manage Address not implemented.');
//                     //   },
//                     // ),
//                     _buildProfileOption(
//                       icon: Icons.scatter_plot,
//                       title: 'My Blood Requests',
//                       onTap: () {
//                         // go to my blood requests page
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder: (context) => const MyBloodRequestsPage(),
//                           ),
//                         );
//                       },
//                     ),
//
//                     //
//                     _buildProfileOption(
//                       icon: Icons.history,
//                       title: 'My Donation History',
//                       onTap: () async {
//                         final result = await Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder: (_) => const DonationHistoryPage(),
//                           ),
//                         );
//
//                         if (result == true) {
//                           _fetchUserProfileAndDonations(); // Refresh life saved & next donation
//                         }
//                       },
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//
//             const SizedBox(height: 16),
//
//             Card(
//               child: Padding(
//                 padding: const EdgeInsets.symmetric(
//                   vertical: 24,
//                   horizontal: 16,
//                 ),
//                 child: SizedBox(
//                   child: ElevatedButton(
//                     onPressed: _isLogOutLoading ? null : _handleLogout,
//                     child: _isLogOutLoading
//                         ? SizedBox(
//                             height: 20,
//                             width: 20,
//                             child: CircularProgressIndicator(
//                               color: Colors.white,
//                               strokeWidth: 2,
//                             ),
//                           )
//                         : Row(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             spacing: 8,
//                             children: [
//                               const Icon(Icons.logout),
//                               Text('Log Out'),
//                             ],
//                           ),
//                   ),
//                 ),
//               ),
//             ),
//             const SizedBox(height: 16),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildInfoColumn({
//     required IconData icon,
//     required Color iconColor,
//     required String text,
//   }) {
//     return Column(
//       children: [
//         Icon(icon, color: iconColor, size: 32),
//         const SizedBox(height: 5),
//         Text(text, style: TextStyle(color: Colors.grey[700], fontSize: 14)),
//       ],
//     );
//   }
//
//   Widget _buildProfileOption({
//     required IconData icon,
//     required String title,
//     Widget? trailing,
//     VoidCallback? onTap,
//   }) {
//     return ListTile(
//       visualDensity: VisualDensity.compact,
//       leading: Icon(icon, size: 28),
//       title: Text(
//         title,
//         style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
//       ),
//       trailing:
//           trailing ??
//           const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
//       onTap: onTap,
//       contentPadding: const EdgeInsets.symmetric(
//         horizontal: 16.0,
//         vertical: 4.0,
//       ),
//     );
//   }
// }

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '/features/account/edit_account_page.dart';
import '/features/blood_request/my_blood_request.dart';
import '/features/donation/donation_history.dart';
import '../../data/providers/theme_provider.dart';
import '../../data/providers/user_providers.dart';

class AccountPage extends ConsumerWidget {
  const AccountPage({super.key});

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
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EditAccountPage()),
              );
            },
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (user) {
          if (user == null) {
            return const Center(child: Text('User data not found.'));
          }

          final fullName = '${user.firstName} ${user.lastName}'.trim();
          final address = user.address.isNotEmpty
              ? '${user.address[0].subdistrict}, ${user.address[0].district}'
              : 'N/A';
          final bloodGroup = user.bloodGroup;
          final isDonorStatus = user.isDonor;

          // Donations
          final donations = donationAsync.maybeWhen(
            data: (list) => list,
            orElse: () => [],
          );

          final lifeSavedCount = donations.length;
          DateTime? lastDonationDate;
          if (donations.isNotEmpty) {
            lastDonationDate =
                (donations.first.data() as Map<String, dynamic>)['donationDate']
                    ?.toDate();
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
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white,
                        child: Text(
                          fullName.substring(0, 1),
                          style: TextStyle(
                            fontSize: 40,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ),
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
                        style: const TextStyle(color: Colors.white70),
                      ),
                      Text(
                        user.email,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
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
                  margin: const EdgeInsets.all(8),
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
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  child: ListTile(
                    leading: const Icon(Icons.check_circle_outline, size: 28),
                    title: const Text(
                      'Available To Donate',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    trailing: Switch(
                      value: isDonorStatus,
                      onChanged: (value) async {
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(user.uid)
                            .update({'isDonor': value});
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

                // Theme toggle
                Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
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
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    children: [
                      _buildProfileOption(
                        Icons.scatter_plot,
                        'My Blood Requests',
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const MyBloodRequestsPage(),
                            ),
                          );
                        },
                      ),
                      _buildProfileOption(
                        Icons.history,
                        'My Donation History',
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const DonationHistoryPage(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // Log out
                Card(
                  margin: const EdgeInsets.all(8),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: ElevatedButton.icon(
                      onPressed: () async {
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
