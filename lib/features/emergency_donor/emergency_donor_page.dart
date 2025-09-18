import 'package:bloodfinder/shared/admin_widget.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/models/user_model.dart';
import '../widgets/start_chat_btn.dart';
import 'add_emergency_donor.dart';

class EmergencyDonorPage extends StatelessWidget {
  const EmergencyDonorPage({super.key});

  // ✅ Stream of emergency donors
  Stream<List<UserModel>> _streamEmergencyDonors() {
    return FirebaseFirestore.instance
        .collection('users')
        .where('isEmergencyDonor', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            // inject uid into model
            return UserModel.fromJson({'uid': doc.id, ...data});
          }).toList();
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Emergency Donors'), centerTitle: true),
      body: Column(
        children: [
          // 🔴 Donors List
          Expanded(
            child: StreamBuilder<List<UserModel>>(
              stream: _streamEmergencyDonors(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final donors = snapshot.data!;

                if (donors.isEmpty) {
                  return const Center(
                    child: Text('No emergency donors found.'),
                  );
                }

                return ListView.separated(
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  padding: const EdgeInsets.all(12),
                  itemCount: donors.length,
                  itemBuilder: (context, index) {
                    final donor = donors[index];
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: Colors.redAccent.shade200,
                              child: donor.image.isEmpty
                                  ? Text(
                                      donor.firstName.isNotEmpty
                                          ? donor.firstName[0].toUpperCase()
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
                                        imageUrl: donor.image,
                                        width: 36,
                                        height: 36,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) =>
                                            CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                        errorWidget: (context, url, error) =>
                                            Icon(
                                              Icons.error,
                                              color: Colors.red,
                                            ),
                                      ),
                                    ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  //
                                  Text(
                                    "${donor.firstName ?? ''} ${donor.lastName ?? ''}",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Blood Group: ${donor.bloodGroup ?? 'Unknown'}',
                                  ),
                                  Text(
                                    'Mobile: ${donor.mobileNumber ?? 'N/A'}',
                                  ),
                                  Text(
                                    'Address: ${donor.currentAddress}, ${donor.subdistrict}, ${donor.district}',
                                  ),

                                  const SizedBox(height: 8),

                                  //
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                Colors.green.shade500,
                                            visualDensity: VisualDensity(
                                              vertical: -3,
                                            ),
                                          ),
                                          onPressed:
                                              (donor.mobileNumber.isNotEmpty)
                                              ? () => _callDonor(
                                                  donor.mobileNumber,
                                                )
                                              : null,
                                          icon: const Icon(Icons.call),
                                          label: const Text("Call Donor"),
                                        ),
                                      ),
                                      const SizedBox(width: 12),

                                      //
                                      Expanded(
                                        child: StartChatButton(
                                          otherUserId: donor.uid,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // ➕ Add Emergency Donor Button (admin-only ideally)
          AdminWidget(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddEmergencyDonorPage(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Emergency Donor'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  //
  Future<void> _callDonor(String mobile) async {
    if (mobile.isEmpty) return;
    final Uri uri = Uri.parse("tel:$mobile");
    try {
      final bool launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) debugPrint("❌ Could not launch dialer for $mobile");
    } catch (e) {
      debugPrint("❌ Error launching dialer: $e");
    }
  }
}
