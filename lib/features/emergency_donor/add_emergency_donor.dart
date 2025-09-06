import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AddEmergencyDonorPage extends StatefulWidget {
  const AddEmergencyDonorPage({super.key});

  @override
  State<AddEmergencyDonorPage> createState() => _AddEmergencyDonorPageState();
}

class _AddEmergencyDonorPageState extends State<AddEmergencyDonorPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Emergency Donors
  Set<String> _emergencyDonorUids = {};

  // Search
  final TextEditingController _searchController = TextEditingController();
  String? _searchQuery;

  // Pagination
  final int _limit = 10;
  DocumentSnapshot? _lastDocument;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  List<DocumentSnapshot> _users = [];

  @override
  void initState() {
    super.initState();
    _loadEmergencyDonors();
    _fetchUsers(initialLoad: true);
  }

  Future<void> _loadEmergencyDonors() async {
    final snapshot = await _firestore.collection('emergency_donor').get();
    setState(() {
      _emergencyDonorUids = snapshot.docs.map((doc) => doc.id).toSet();
    });
  }

  Future<void> _toggleEmergencyDonor(String uid) async {
    final docRef = _firestore.collection('emergency_donor').doc(uid);
    if (_emergencyDonorUids.contains(uid)) {
      await docRef.delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Removed from emergency donors'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _emergencyDonorUids.remove(uid);
      });
    } else {
      await docRef.set({});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Added to emergency donors'),
          backgroundColor: Colors.green,
        ),
      );
      setState(() {
        _emergencyDonorUids.add(uid);
      });
    }
  }

  Future<void> _fetchUsers({bool initialLoad = false}) async {
    if (_isLoadingMore || (!_hasMore && !initialLoad)) return;

    setState(() => _isLoadingMore = true);

    Query query = _firestore
        .collection('users')
        .orderBy('mobileNumber')
        .limit(_limit);

    if (_searchQuery != null && _searchQuery!.isNotEmpty) {
      query = query.where('mobileNumber', isEqualTo: _searchQuery);
    }

    if (_lastDocument != null) {
      query = query.startAfterDocument(_lastDocument!);
    }

    final snapshot = await query.get();

    if (snapshot.docs.isNotEmpty) {
      setState(() {
        if (initialLoad) {
          _users = snapshot.docs;
        } else {
          _users.addAll(snapshot.docs);
        }
        _lastDocument = snapshot.docs.last;
        _hasMore = snapshot.docs.length == _limit;
      });
    } else {
      if (initialLoad) {
        setState(() {
          _users = [];
        });
      }
      _hasMore = false;
    }

    setState(() => _isLoadingMore = false);
  }

  void _onSearchPressed() {
    setState(() {
      _searchQuery = _searchController.text.trim();
      _lastDocument = null;
      _hasMore = true;
    });
    _fetchUsers(initialLoad: true);
  }

  void _onResetSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = null;
      _lastDocument = null;
      _hasMore = true;
    });
    _fetchUsers(initialLoad: true);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Emergency Donors'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 🔍 Search bar
          Card(
            margin: const EdgeInsets.only(top: 8),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      //
                      Expanded(
                        flex: 5,
                        child: TextField(
                          controller: _searchController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            hintText: 'Search by mobile number',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.zero,
                          ),
                          onPressed: _onSearchPressed,
                          child: const Text('Search'),
                        ),
                      ),
                    ],
                  ),

                  //
                  const SizedBox(height: 8),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      //
                      Text(
                        'Press reset to clear search01',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),

                      //
                      InkWell(
                        onTap: _onResetSearch,
                        child: Container(
                          color: Colors.grey.shade200,
                          padding: const EdgeInsets.symmetric(
                            vertical: 4,
                            horizontal: 8,
                          ),
                          child: Text('X  Reset'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // 📋 User List
          Expanded(
            child: _users.isEmpty
                ? const Center(child: Text('No users found.'))
                : Card(
                    margin: const EdgeInsets.only(top: 8, bottom: 8),
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemCount: _users.length + 1,
                      itemBuilder: (context, index) {
                        if (index == _users.length) {
                          if (_hasMore) {
                            _fetchUsers();
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          } else {
                            return const SizedBox(); // No more data
                          }
                        }

                        final userDoc = _users[index];
                        final uid = userDoc.id;
                        final data = userDoc.data()! as Map<String, dynamic>;

                        final firstName = data['firstName'] ?? '';
                        final lastName = data['lastName'] ?? '';
                        final mobileNumber = data['mobileNumber'] ?? 'N/A';
                        final bloodGroup = data['bloodGroup'] ?? 'Unknown';
                        final name = '$firstName $lastName';

                        final isEmergencyDonor = _emergencyDonorUids.contains(
                          uid,
                        );

                        return Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
                            child: Row(
                              children: [
                                CircleAvatar(child: Text('$bloodGroup')),
                                SizedBox(width: 10),
                                Expanded(
                                  flex: 6,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text('Mobile: $mobileNumber'),
                                    ],
                                  ),
                                ),

                                //
                                Expanded(
                                  flex: 2,
                                  child: SizedBox(
                                    height: 36,
                                    width: 36,
                                    child: ElevatedButton(
                                      onPressed: () =>
                                          _toggleEmergencyDonor(uid),
                                      style: ElevatedButton.styleFrom(
                                        padding: EdgeInsets.zero,
                                        backgroundColor: isEmergencyDonor
                                            ? Colors.red
                                            : Colors.green,
                                      ),
                                      child: Text(
                                        isEmergencyDonor ? 'Remove' : 'Add',
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
