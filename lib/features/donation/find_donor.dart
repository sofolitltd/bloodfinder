import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FindDonorPage extends StatefulWidget {
  final String? bloodGroup;
  final String? district;
  final String? subdistrict;

  const FindDonorPage({
    super.key,
    this.bloodGroup,
    this.district,
    this.subdistrict,
  });

  @override
  State<FindDonorPage> createState() => _FindDonorPageState();
}

class _FindDonorPageState extends State<FindDonorPage> {
  List<Map<String, dynamic>> _donors = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchDonors();
  }

  void _showMessage(String message, {bool isError = false}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : Colors.green,
        ),
      );
    }
  }

  Future<void> _fetchDonors() async {
    setState(() {
      _isLoading = true;
      _donors = [];
    });

    try {
      Query<Map<String, dynamic>> query = FirebaseFirestore.instance
          .collection('users')
          .where('isDonor', isEqualTo: true);

      if (widget.bloodGroup != null && widget.bloodGroup!.isNotEmpty) {
        query = query.where('bloodGroup', isEqualTo: widget.bloodGroup);
      }

      if (widget.district != null && widget.district!.isNotEmpty) {
        query = query.where('address.0.district', isEqualTo: widget.district);
      }

      if (widget.subdistrict != null && widget.subdistrict!.isNotEmpty) {
        query = query.where(
          'address.0.subdistrict',
          isEqualTo: widget.subdistrict,
        );
      }

      final snapshot = await query.get();

      setState(() {
        _donors = snapshot.docs.map((doc) => doc.data()).toList();
      });
    } catch (e) {
      log("Error fetching donors: $e");
      _showMessage('Failed to load donors: ${e.toString()}', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Find Donors'), centerTitle: true),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _donors.isEmpty
          ? const Center(
              child: Text('No donors found for the selected filters.'),
            )
          : Card(
              margin: EdgeInsets.symmetric(vertical: 8),
              child: ListView.separated(
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                padding: const EdgeInsets.all(16.0),
                itemCount: _donors.length,
                itemBuilder: (context, index) {
                  final donor = _donors[index];

                  final name =
                      '${donor['firstName'] ?? ''} ${donor['lastName'] ?? ''}'
                          .trim();
                  final bloodGroup = donor['bloodGroup'] ?? 'N/A';
                  final imageUrl = donor['imageUrl'] ?? '';

                  final addressData =
                      donor['address'] is List && donor['address'].isNotEmpty
                      ? donor['address'][0]
                      : null;

                  final address = addressData != null
                      ? '${addressData['subdistrict'] ?? ''}, ${addressData['district'] ?? ''}'
                      : 'N/A';

                  return _buildDonorListItem(
                    name: name,
                    address: address,
                    bloodGroup: bloodGroup,
                    imageUrl: imageUrl,
                  );
                },
              ),
            ),
    );
  }

  Widget _buildDonorListItem({
    required String name,
    required String address,
    required String bloodGroup,
    required String imageUrl,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey, width: 1),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            //todo: fix later
            // backgroundImage: NetworkImage(imageUrl),
            backgroundColor: Colors.grey[200],
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  address,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              bloodGroup,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
