import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../data/db/app_data.dart';
import '../../data/models/blood_request.dart';
import '../community/search_page.dart';
import '../widgets/blood_request_card.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final int _limit = 10;
  DocumentSnapshot? _lastDoc;
  bool _hasMore = true;
  bool _isLoading = false;
  bool _isVisible = true;

  final StreamController<List<BloodRequest>> _streamController =
      StreamController<List<BloodRequest>>.broadcast();

  List<BloodRequest> _requests = [];

  String? _selectedDistrict;
  String? _selectedSubdistrict;
  String? _selectedBloodGroup;

  final String _uid = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _loadRequests(reset: true);
  }

  @override
  void dispose() {
    _streamController.close();
    super.dispose();
  }

  Future<void> _loadRequests({bool reset = false}) async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    if (reset) {
      _lastDoc = null;
      _requests = [];
      _hasMore = true;
      _streamController.add([]); // clear stream immediately
    }

    Query query = _firestore
        .collection('blood_requests')
        .orderBy('createdAt', descending: true)
        .limit(_limit);

    if (_selectedDistrict != null) {
      query = query.where('district', isEqualTo: _selectedDistrict);
    }
    if (_selectedSubdistrict != null) {
      query = query.where('subdistrict', isEqualTo: _selectedSubdistrict);
    }
    if (_selectedBloodGroup != null) {
      query = query.where('bloodGroup', isEqualTo: _selectedBloodGroup);
    }

    if (_lastDoc != null) query = query.startAfterDocument(_lastDoc!);

    final snap = await query.get();

    final newRequests = snap.docs
        .map((doc) => BloodRequest.fromJson(doc.data() as Map<String, dynamic>))
        .where((req) => req.uid != _uid)
        .toList();

    if (newRequests.isNotEmpty) {
      _lastDoc = snap.docs.last;
      _requests.addAll(newRequests);
    } else if (reset) {
      _requests = [];
    }

    if (snap.docs.length < _limit) _hasMore = false;

    _streamController.add(_requests);

    setState(() => _isLoading = false);
  }

  Widget _buildDistrictDropdown() {
    return Expanded(
      child: TextFormField(
        readOnly: true,
        decoration: InputDecoration(
          hintText: _selectedDistrict ?? 'District',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          suffixIcon: _selectedDistrict != null
              ? IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () async {
                    setState(() {
                      _selectedDistrict = null;
                      _selectedSubdistrict = null;
                    });
                    await _loadRequests(reset: true);
                  },
                )
              : const Icon(Icons.arrow_drop_down),
        ),
        onTap: () async {
          final selectedValue = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SearchPage(
                title: 'District',
                items: (AppData.districts.map((d) => d.name).toList()..sort()),
              ),
            ),
          );
          if (selectedValue != null) {
            setState(() {
              _selectedDistrict = selectedValue;
              _selectedSubdistrict = null;
            });
            await _loadRequests(reset: true);
          }
        },
      ),
    );
  }

  Widget _buildSubDistrictDropdown() {
    final subDistricts = _selectedDistrict != null
        ? AppData.districts
              .firstWhere((d) => d.name == _selectedDistrict)
              .subDistricts
        : <String>[];

    return Expanded(
      child: TextFormField(
        readOnly: true,
        enabled: _selectedDistrict != null,
        decoration: InputDecoration(
          hintText: _selectedSubdistrict ?? 'Subdistrict',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          suffixIcon: _selectedSubdistrict != null
              ? IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () async {
                    setState(() {
                      _selectedSubdistrict = null;
                    });
                    await _loadRequests(reset: true);
                  },
                )
              : const Icon(Icons.arrow_drop_down),
        ),
        onTap: () async {
          if (_selectedDistrict == null) return;
          final selectedValue = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  SearchPage(title: 'Subdistrict', items: subDistricts),
            ),
          );
          if (selectedValue != null) {
            setState(() {
              _selectedSubdistrict = selectedValue;
            });
            await _loadRequests(reset: true);
          }
        },
      ),
    );
  }

  Widget _buildBloodGroupDropdown() {
    return Expanded(
      flex: 1,
      child: ButtonTheme(
        alignedDropdown: true,
        child: DropdownButtonFormField<String>(
          initialValue: _selectedBloodGroup,

          decoration: const InputDecoration(
            labelText: 'Blood Group',
            visualDensity: VisualDensity(vertical: -4),
          ),
          items: AppData.bloodGroups
              .map(
                (group) => DropdownMenuItem(value: group, child: Text(group)),
              )
              .toList(),
          onChanged: (value) async {
            setState(() => _selectedBloodGroup = value);
            await _loadRequests(reset: true);
          },
          isExpanded: true,
        ),
      ),
    );
  }

  Widget _buildClearButton() {
    final hasFilterSelected =
        _selectedDistrict != null ||
        _selectedSubdistrict != null ||
        _selectedBloodGroup != null;

    return Expanded(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: hasFilterSelected
              ? null
              : Colors.grey, // disabled color
        ),
        onPressed: hasFilterSelected
            ? () async {
                setState(() {
                  _selectedDistrict = null;
                  _selectedSubdistrict = null;
                  _selectedBloodGroup = null;
                });
                await _loadRequests(reset: true);
              }
            : null, // disables button
        child: const Text('Clear'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feed'),
        actions: [
          IconButton(
            onPressed: () {
              //show or hide filter options
              setState(() {
                _isVisible = !_isVisible;
              });
            },
            icon: Icon(
              Icons.filter_list,
              color: !_isVisible ? Colors.grey : Colors.red.shade300,
            ),
          ),
          SizedBox(width: 8),
        ],
      ),
      body: Column(
        spacing: 8,
        children: [
          //
          Visibility(
            visible: _isVisible,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Row 1: District + Subdistrict
                    Row(
                      children: [
                        _buildDistrictDropdown(),
                        const SizedBox(width: 12),
                        _buildSubDistrictDropdown(),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Row 2: Blood group + Clear button
                    Row(
                      children: [
                        _buildBloodGroupDropdown(),
                        const SizedBox(width: 12),
                        _buildClearButton(),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          //
          Expanded(
            child: StreamBuilder<List<BloodRequest>>(
              stream: _streamController.stream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    _requests.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(child: Text('Something went wrong'));
                }

                final requests = snapshot.data ?? [];

                if (requests.isEmpty) {
                  return const Center(child: Text('No blood requests found'));
                }

                //
                return Card(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: requests.length + (_hasMore ? 1 : 0),
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      if (index < requests.length) {
                        return BloodRequestCard(request: requests[index]);
                      }

                      if (_hasMore) {
                        _loadRequests();
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      return const SizedBox.shrink();
                    },
                  ),
                );
              },
            ),
          ),

          SizedBox(),
        ],
      ),
    );
  }
}
