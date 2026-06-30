import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../../data/providers/repository_providers.dart';

class AddEmergencyDonorPage extends ConsumerStatefulWidget {
  const AddEmergencyDonorPage({super.key});

  @override
  ConsumerState<AddEmergencyDonorPage> createState() =>
      _AddEmergencyDonorPageState();
}

class _AddEmergencyDonorPageState extends ConsumerState<AddEmergencyDonorPage> {
  Set<String> _emergencyDonorUids = {};

  final TextEditingController _searchController = TextEditingController();
  String? _searchQuery;

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
    final snapshot =
        await ref.read(emergencyDonorRepositoryProvider).getAllDonors();
    setState(() {
      _emergencyDonorUids = snapshot.docs.map((doc) => doc.id).toSet();
    });
  }

  Future<void> _toggleEmergencyDonor(String uid) async {
    final donorRepo = ref.read(emergencyDonorRepositoryProvider);
    if (_emergencyDonorUids.contains(uid)) {
      await donorRepo.removeDonor(uid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Removed from emergency donors'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
        );
      }
      setState(() {
        _emergencyDonorUids.remove(uid);
      });
    } else {
      await donorRepo.addDonor(uid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Added to emergency donors'),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
        );
      }
      setState(() {
        _emergencyDonorUids.add(uid);
      });
    }
  }

  Future<void> _fetchUsers({bool initialLoad = false}) async {
    if (_isLoadingMore || (!_hasMore && !initialLoad)) return;

    setState(() => _isLoadingMore = true);

    Query<Map<String, dynamic>> query = ref
        .read(firebaseDataSourceProvider)
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
        title: Row(
          children: [
            Container(
              width: 32.w,
              height: 32.h,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(
                PhosphorIcons.shieldChevron,
                color: Colors.red.shade600,
                size: 18,
              ),
            ),
            SizedBox(width: 10.w),
            const Text(
              'Manage Emergency Donors',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            margin: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0.h),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(14.r),
            ),
            padding: EdgeInsets.all(12.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          hintText: 'Search by mobile number',
                          prefixIcon: Icon(
                            PhosphorIcons.magnifyingGlass,
                            size: 20,
                          ),
                          filled: false,
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 12.h,
                          ),
                        ),
                        onSubmitted: (_) => _onSearchPressed(),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    SizedBox(
                      height: 44.h,
                      child: ElevatedButton(
                        onPressed: _onSearchPressed,
                        style: ElevatedButton.styleFrom(elevation: 0),
                        child: Text(
                          'Search',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Search by full mobile number',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    InkWell(
                      onTap: _onResetSearch,
                      borderRadius: BorderRadius.circular(8.r),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          vertical: 4.h,
                          horizontal: 10.w,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Text(
                          'Reset',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(height: 12.h),

          // User list
          Expanded(
            child: _users.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 64.w,
                          height: 64.h,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                          child: Icon(
                            PhosphorIcons.users,
                            size: 30,
                            color: Colors.grey.shade400,
                          ),
                        ),
                        SizedBox(height: 12.h),
                        Text(
                          'No users found',
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    itemCount: _users.length + 1,
                    itemBuilder: (context, index) {
                      if (index == _users.length) {
                        if (_hasMore) {
                          _fetchUsers();
                          return Padding(
                            padding: EdgeInsets.symmetric(vertical: 16.h),
                            child: Center(
                              child: SizedBox(
                                width: 24.w,
                                height: 24.h,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                          );
                        }
                        return const SizedBox();
                      }

                      final userDoc = _users[index];
                      final uid = userDoc.id;
                      final data = userDoc.data()! as Map<String, dynamic>;

                      final firstName = data['firstName'] ?? '';
                      final lastName = data['lastName'] ?? '';
                      final mobileNumber = data['mobileNumber'] ?? 'N/A';
                      final bloodGroup = data['bloodGroup'] ?? 'Unknown';
                      final image = data['image'] ?? '';

                      final isEmergencyDonor =
                          _emergencyDonorUids.contains(uid);

                      return Padding(
                        padding: EdgeInsets.only(
                          top: index == 0 ? 0 : 8,
                          bottom: index == _users.length - 1 ? 16 : 0,
                        ),
                        child: _UserCard(
                          firstName: firstName,
                          lastName: lastName,
                          mobileNumber: mobileNumber,
                          bloodGroup: bloodGroup,
                          image: image,
                          isEmergencyDonor: isEmergencyDonor,
                          onToggle: () => _toggleEmergencyDonor(uid),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final String firstName;
  final String lastName;
  final String mobileNumber;
  final String bloodGroup;
  final String image;
  final bool isEmergencyDonor;
  final VoidCallback onToggle;

  const _UserCard({
    required this.firstName,
    required this.lastName,
    required this.mobileNumber,
    required this.bloodGroup,
    required this.image,
    required this.isEmergencyDonor,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(14.w),
        child: Row(
          children: [
            // Blood group avatar
            Container(
              width: 48.w,
              height: 48.h,
              decoration: BoxDecoration(
                color: isEmergencyDonor
                    ? Colors.red.shade50
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(14.r),
              ),
              child: Center(
                child: Text(
                  bloodGroup,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.bold,
                    color: isEmergencyDonor
                        ? Colors.red.shade600
                        : Colors.grey.shade600,
                  ),
                ),
              ),
            ),
            SizedBox(width: 14.w),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$firstName $lastName',
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      Icon(
                        PhosphorIcons.phone,
                        size: 12,
                        color: Colors.grey.shade500,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        mobileNumber,
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Toggle button
            SizedBox(
              height: 34.h,
              child: ElevatedButton(
                onPressed: onToggle,
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  padding: EdgeInsets.symmetric(horizontal: 14.w),
                  backgroundColor: isEmergencyDonor
                      ? Colors.red.shade50
                      : Colors.green.shade50,
                  foregroundColor: isEmergencyDonor
                      ? Colors.red.shade700
                      : Colors.green.shade700,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isEmergencyDonor
                          ? PhosphorIcons.minusBold
                          : PhosphorIcons.plusBold,
                      size: 14,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      isEmergencyDonor ? 'Remove' : 'Add',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
