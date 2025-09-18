import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '/data/models/blood_request.dart';
import '../widgets/blood_request_card.dart';

class DistrictRequestsPage extends StatefulWidget {
  const DistrictRequestsPage({super.key});

  @override
  State<DistrictRequestsPage> createState() => _DistrictRequestsPageState();
}

class _DistrictRequestsPageState extends State<DistrictRequestsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final int _limit = 10;
  String? _selectedSubdistrict;

  List<String> _subdistricts = [];
  late String _userDistrict;
  bool _loadingSubdistricts = true;

  @override
  void initState() {
    super.initState();
    _fetchUserDistrictAndSubdistricts();
  }

  Future<void> _fetchUserDistrictAndSubdistricts() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final userDoc = await _firestore.collection('users').doc(uid).get();

    if (!userDoc.exists) return;

    final userData = userDoc.data()!;
    _userDistrict = userData['district'] ?? '';
    _subdistricts = await _fetchSubdistricts(_userDistrict);

    setState(() {
      _loadingSubdistricts = false;
    });
  }

  Future<List<String>> _fetchSubdistricts(String district) async {
    final snap = await _firestore
        .collection('blood_requests')
        .where('district', isEqualTo: district)
        .get();

    final subs = snap.docs
        .map((doc) => doc['subdistrict'] as String)
        .toSet()
        .toList();
    subs.sort();
    return subs;
  }

  Stream<List<BloodRequest>> _bloodRequestStream() {
    Query query = _firestore
        .collection('blood_requests')
        .where('district', isEqualTo: _userDistrict)
        .orderBy('createdAt', descending: true);

    if (_selectedSubdistrict != null && _selectedSubdistrict!.isNotEmpty) {
      query = query.where('subdistrict', isEqualTo: _selectedSubdistrict);
    }

    return query.snapshots().map((snap) {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      return snap.docs
          .map(
            (doc) => BloodRequest.fromJson(doc.data() as Map<String, dynamic>),
          )
          .where((req) => req.uid != uid) // exclude user's own posts
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingSubdistricts) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("District Blood Requests"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Subdistrict filter dropdown
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ButtonTheme(
              alignedDropdown: true,
              child: DropdownButtonFormField<String>(
                initialValue: _selectedSubdistrict,
                decoration: const InputDecoration(
                  labelText: "Filter by Subdistrict",
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text("All Subdistricts"),
                  ),
                  ..._subdistricts.map(
                    (sub) => DropdownMenuItem(value: sub, child: Text(sub)),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedSubdistrict = value;
                  });
                },
              ),
            ),
          ),

          // Blood requests list
          Expanded(
            child: StreamBuilder<List<BloodRequest>>(
              stream: _bloodRequestStream(),
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

                // Simple pagination using ListView.separated
                // return BloodRequestsPage();
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
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
    );
  }
}
