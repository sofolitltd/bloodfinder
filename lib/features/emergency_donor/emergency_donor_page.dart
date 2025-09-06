import 'package:bloodfinder/shared/admin_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'add_emergency_donor.dart';

class EmergencyDonorPage extends StatefulWidget {
  const EmergencyDonorPage({super.key});

  @override
  State<EmergencyDonorPage> createState() => _EmergencyDonorPageState();
}

class _EmergencyDonorPageState extends State<EmergencyDonorPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final int _batchSize = 10;
  List<DocumentSnapshot> _emergencyDocs = [];
  bool _isLoadingMore = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    final snapshot = await _firestore
        .collection('emergency_donor')
        .limit(_batchSize)
        .get();

    setState(() {
      _emergencyDocs = snapshot.docs;
      _hasMore = snapshot.docs.length == _batchSize;
    });
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() => _isLoadingMore = true);

    final lastDoc = _emergencyDocs.last;

    final snapshot = await _firestore
        .collection('emergency_donor')
        .startAfterDocument(lastDoc)
        .limit(_batchSize)
        .get();

    setState(() {
      _emergencyDocs.addAll(snapshot.docs);
      _hasMore = snapshot.docs.length == _batchSize;
      _isLoadingMore = false;
    });
  }

  /// Stream of user data based on UID list
  Stream<List<Map<String, dynamic>>> _streamDonorsData() {
    return _firestore.collection('emergency_donor').snapshots().asyncMap((
      snapshot,
    ) async {
      final uids = snapshot.docs.map((doc) => doc.id).toList();

      if (uids.isEmpty) return [];

      final userSnapshots = await Future.wait(
        uids.map((uid) => _firestore.collection('users').doc(uid).get()),
      );

      return userSnapshots.where((doc) => doc.exists).map((doc) {
        final data = doc.data()!;
        return {
          'uid': doc.id,
          'name': '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}',
          'bloodGroup': data['bloodGroup'] ?? 'Unknown',
          'mobile': data['mobileNumber'] ?? 'N/A',
          'address': data['address'],
        };
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
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _streamDonorsData(),
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

                return Card(
                  margin: const EdgeInsets.only(top: 8, bottom: 8),
                  child: ListView.separated(
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    padding: const EdgeInsets.all(12),
                    itemCount: donors.length,
                    itemBuilder: (context, index) {
                      final donor = donors[index];
                      return Card(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey, width: 1),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              children: [
                                Row(
                                  spacing: 12,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    //
                                    CircleAvatar(
                                      child: const Icon(
                                        Icons.person,
                                        color: Colors.red,
                                      ),
                                    ),

                                    //
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            donor['name'],
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            'Blood Group: ${donor['bloodGroup']}',
                                          ),
                                          Text('Mobile: ${donor['mobile']}'),
                                          Text(
                                            'Address: ${donor['address'][0]['subdistrict']}, ${donor['address'][0]['district']}',
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),

          // todo: ➕ Add Emergency Donor Button (admin-only ideally)
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
}
