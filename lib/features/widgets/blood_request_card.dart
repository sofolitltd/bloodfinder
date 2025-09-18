import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '/data/models/blood_request.dart';
import '../../data/models/user_model.dart';
import '../donation/donation_page.dart';

class BloodRequestCard extends StatelessWidget {
  const BloodRequestCard({super.key, required this.request});

  final BloodRequest request;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(request.uid)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox();
        }
        if (snapshot.hasError) {
          return const Text('Error loading user data');
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Text('User not found');
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>;
        final user = UserModel.fromJson(userData);

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            // color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Theme.of(context).dividerColor, width: 1),
          ),

          child: Column(
            children: [
              //
              Stack(
                children: [
                  //
                  Row(
                    children: [
                      //
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.redAccent.shade200,
                        child: user.image.isEmpty
                            ? Text(
                                user.firstName.isNotEmpty
                                    ? user.firstName[0].toUpperCase()
                                    : '',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(50),
                                child: CachedNetworkImage(
                                  imageUrl: user.image,
                                  width: 36,
                                  height: 36,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) =>
                                      CircularProgressIndicator(strokeWidth: 2),
                                  errorWidget: (context, url, error) =>
                                      Icon(Icons.error, color: Colors.red),
                                ),
                              ),
                      ),

                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${user.firstName} ${user.lastName}' ?? 'Anonymous',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          //
                          Text(
                            // Format the Timestamp to a readable date string
                            // 'dd MMM, yyyy hh:mm a'
                            DateFormat(
                              'dd MMM yyy - hh:mm a',
                            ).format(request.createdAt),
                            style: const TextStyle(
                              fontSize: 12, // Adjusted for better UI
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.shade700,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        ' ${request.bloodGroup} ',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.white,
                          // height: 1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              //
              Divider(height: 20, thickness: .5, color: Colors.grey),

              // const SizedBox(height: 8),

              //
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  //blood
                  Row(
                    spacing: 12,
                    children: [
                      //
                      Row(
                        spacing: 8,
                        children: [
                          Text(
                            'Blood Group:',
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            request.bloodGroup,
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),

                      Text('|', style: TextStyle(fontSize: 10)),

                      //
                      Row(
                        spacing: 8,
                        children: [
                          Text(
                            'Bag Need:',
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            request.bag,
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  SizedBox(height: 10),

                  //
                  Row(
                    spacing: 8,
                    children: [
                      Text(
                        'Patient:',
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        request.name,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 8),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Expected Time: ',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        formatDateTime(request.date, request.time),
                        style: const TextStyle(
                          fontSize: 14,
                          // color: Colors.grey,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 4),
                  Text(
                    'Address: ${request.address}, ${request.subdistrict}, ${request.district}',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              Divider(height: 20, thickness: .5, color: Colors.grey),

              Row(
                spacing: 16,
                children: [
                  // Inside your OutlinedButton
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      onPressed: () async {
                        final RenderBox? box =
                            context.findRenderObject() as RenderBox?;

                        final shareText =
                            '\nBlood Group: ${request.bloodGroup}\nName: ${request.name}\nContact No: ${request.mobile}\n\nAddress: ${request.address}, ${request.subdistrict}, ${request.district}\n\nDate & Time: ${formatDateTime(request.date, request.time)}\nBags Needed: ${request.bag}';

                        //\n
                        try {
                          final shareResult = await SharePlus.instance.share(
                            ShareParams(
                              text: shareText.isEmpty ? null : shareText,
                              subject: 'Blood Donation Request',
                              title: '${request.bloodGroup} Blood Request',
                              sharePositionOrigin:
                                  box!.localToGlobal(Offset.zero) & box.size,
                              excludedCupertinoActivities: [
                                CupertinoActivityType.airDrop,
                              ],
                            ),
                          );

                          // Optional: handle result
                          debugPrint('Share Result: $shareResult');
                        } catch (e) {
                          debugPrint('Error sharing: $e');
                        }
                      },
                      child: Text(
                        'Share',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),

                  //
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        minimumSize: Size(double.infinity, 40),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      onPressed: () {
                        // go to DonationPage[material]
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                DonationPage(requestId: request.id),
                          ),
                        );
                      },
                      child: Text(
                        'Donate',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

//
String formatDateTime(String dateStr, String timeStr) {
  try {
    // Parse the date string (yyyy-MM-dd)
    final date = DateFormat('yyyy-MM-dd').parse(dateStr);

    // Format date as: 26 Jun, 25
    final formattedDate = DateFormat('d MMMM, yyyy').format(date);

    // Return combined string with time
    return '$timeStr $formattedDate';
  } catch (e) {
    // fallback if parsing fails
    return '$dateStr at $timeStr';
  }
}
