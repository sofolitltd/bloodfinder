import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '/data/models/blood_request.dart';
import '../donation/donation_page.dart';

class BloodRequestCard extends StatelessWidget {
  const BloodRequestCard({super.key, required this.request});

  final BloodRequest request;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        // color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          //
          Stack(
            children: [
              //
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  //grp
                  Container(
                    width: 56,
                    height: 56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.red.shade700,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      request.bloodGroup,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  //
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          request.name,
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        SizedBox(height: 4),
                        Text(
                          '${request.subdistrict}, ${request.district}',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                            height: 1.2,
                          ),
                        ),
                        SizedBox(height: 2),

                        Text(
                          'Time: ${formatDateTime(request.date, request.time)}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              //
              if (int.parse(request.bag) > 1)
                Positioned(
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.shade700,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${request.bag} bag ',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white,
                        height: 1,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 6),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Address: ',
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                  height: 1.2,
                ),
              ),

              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  request.address,
                  style: const TextStyle(fontSize: 14, height: 1.3),
                ),
              ),
            ],
          ),

          //
          Divider(height: 20, thickness: .5, color: Colors.grey),

          // SizedBox(height: 8),
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
                        'Blood Group: ${request.bloodGroup}\nName: ${request.name}\nLocation: ${request.subdistrict}, ${request.district}\nAddress: ${request.address}\nDate & Time: ${formatDateTime(request.date, request.time)}\n\nBags Needed: ${request.bag}';

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
                  child: Text('Share', style: TextStyle(color: Colors.grey)),
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
                  child: Text('Donate', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ],
      ),
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
