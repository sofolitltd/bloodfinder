import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '/data/models/blood_request.dart';
import '../../blood_request/district_blood_request.dart';
import '../../widgets/blood_request_card.dart';

class HomeBloodRequestsSection extends StatelessWidget {
  const HomeBloodRequestsSection({super.key});

  Stream<List<BloodRequest>> _fetchBloodRequests() async* {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    // 1️⃣ Get user info
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    if (!userDoc.exists) {
      yield [];
      return;
    }

    final userData = userDoc.data()!;
    final userDistrict = userData['district'] ?? '';
    final userSubdistrict = userData['subdistrict'] ?? '';

    if (userDistrict.isEmpty && userSubdistrict.isEmpty) {
      yield [];
      return;
    }

    // 2️⃣ Stream for subdistrict + district posts
    final bothStream = FirebaseFirestore.instance
        .collection('blood_requests')
        .where('district', isEqualTo: userDistrict)
        .where('subdistrict', isEqualTo: userSubdistrict)
        .orderBy('createdAt', descending: true)
        .limit(8)
        .snapshots();

    await for (final snap in bothStream) {
      final subdistrictPosts = snap.docs
          .map((doc) => BloodRequest.fromJson(doc.data()))
          .where((req) => req.uid != uid)
          .toList();

      if (subdistrictPosts.isNotEmpty) {
        // ✅ Emit subdistrict posts
        yield subdistrictPosts;
      } else {
        // 3️⃣ Fallback to district-only posts stream
        final distStream = FirebaseFirestore.instance
            .collection('blood_requests')
            .where('district', isEqualTo: userDistrict)
            .orderBy('createdAt', descending: true)
            .limit(8)
            .snapshots();

        await for (final distSnap in distStream) {
          final distPosts = distSnap.docs
              .map((doc) => BloodRequest.fromJson(doc.data()))
              .where((req) => req.uid != uid)
              .toList();

          yield distPosts;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Blood Request',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'From your Subdistrict or District',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DistrictRequestsPage(),
                      ),
                    );
                  },
                  child: Text(
                    'see more',
                    style: TextStyle(color: Colors.red.shade700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Blood request stream
            Container(
              constraints: const BoxConstraints(maxHeight: 150),

              child: StreamBuilder<List<BloodRequest>>(
                stream: _fetchBloodRequests(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(child: Text('Something went wrong'));
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final requests = snapshot.data!;
                  if (requests.isEmpty) {
                    return const Center(child: Text('No blood requests found'));
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: requests.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      return BloodRequestCard(request: requests[index]);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
