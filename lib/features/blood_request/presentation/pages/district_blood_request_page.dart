import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/providers/repository_providers.dart';
import '../../models/blood_request.dart';
import '../../../../shared/widgets/blood_request_card.dart';

class DistrictRequestsPage extends ConsumerStatefulWidget {
  const DistrictRequestsPage({super.key});

  @override
  ConsumerState<DistrictRequestsPage> createState() =>
      _DistrictRequestsPageState();
}

class _DistrictRequestsPageState extends ConsumerState<DistrictRequestsPage> {
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
    final uid = ref.read(authRepositoryProvider).currentUser!.uid;
    final userDoc =
        await ref.read(userRepositoryProvider).getUser(uid);

    if (!userDoc.exists) return;

    final userData = userDoc.data()!;
    _userDistrict = userData['district'] ?? '';
    _subdistricts = await _fetchSubdistricts(_userDistrict);

    setState(() {
      _loadingSubdistricts = false;
    });
  }

  Future<List<String>> _fetchSubdistricts(String district) async {
    final snap =
        await ref.read(bloodRequestRepositoryProvider).getSubdistricts(district);

    final subs = snap.docs
        .map((doc) => doc['subdistrict'] as String)
        .toSet()
        .toList();
    subs.sort();
    return subs;
  }

  Stream<List<BloodRequest>> _bloodRequestStream() {
    final uid = ref.read(authRepositoryProvider).currentUser!.uid;

    return ref
        .read(bloodRequestRepositoryProvider)
        .requestsByDistrict(_userDistrict, subdistrict: _selectedSubdistrict)
        .map((snap) => snap.docs
            .map(
              (doc) => BloodRequest.fromFirestore(doc),
            )
            .where((req) => req.uid != uid)
            .toList());
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
            padding: EdgeInsets.all(16.0),
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
                  padding: EdgeInsets.all(16.w),
                  itemCount: requests.length,
                  separatorBuilder: (_, __) => SizedBox(height: 8.h),
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
