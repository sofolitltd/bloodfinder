import 'package:bloodfinder/data/models/blood_request.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'post_blood_request.dart';

class MyBloodRequestsPage extends StatefulWidget {
  const MyBloodRequestsPage({super.key});

  @override
  State<MyBloodRequestsPage> createState() => _MyBloodRequestsPageState();
}

class _MyBloodRequestsPageState extends State<MyBloodRequestsPage> {
  final uid = FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Blood Requests'), centerTitle: true),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PostBloodRequestPage()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Post Blood Request'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('blood_requests')
            .where('uid', isEqualTo: uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('You have not posted any blood requests yet.'),
            );
          }

          final requests = snapshot.data!.docs
              .map(
                (doc) =>
                    BloodRequest.fromJson(doc.data()! as Map<String, dynamic>),
              )
              .toList();

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: requests.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final req = requests[index];

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        spacing: 8,
                        children: [
                          //
                          Chip(
                            visualDensity: VisualDensity.compact,
                            color: WidgetStateProperty.all(Colors.red),
                            label: Text(
                              req.bloodGroup,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),

                          //
                          Chip(
                            visualDensity: VisualDensity.compact,

                            label: Text(
                              '${req.bag} bag',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                          Spacer(),
                          //
                          Row(
                            children: [
                              //todo: fix later
                              // IconButton(
                              //   onPressed: () {
                              //     Navigator.push(
                              //       context,
                              //       MaterialPageRoute(
                              //         builder: (_) =>
                              //             const PostBloodRequestPage(),
                              //       ),
                              //     );
                              //   },
                              //   icon: const Icon(Icons.edit, color: Colors.blue),
                              // ),

                              //
                              IconButton(
                                onPressed: () async {
                                  try {
                                    await FirebaseFirestore.instance
                                        .collection('blood_requests')
                                        .doc(req.id)
                                        .delete();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Request deleted successfully',
                                        ),
                                      ),
                                    );
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Error: $e')),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.delete),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Time: ${req.time}, ${req.date}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text('Name: ${req.name}'),
                      Text('Contact: ${req.mobile}'),
                      Text(
                        'Address: ${req.address}, ${req.subdistrict}, ${req.district}',
                      ),
                      if (req.note != null && req.note!.isNotEmpty)
                        Text('Note: ${req.note}'),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
