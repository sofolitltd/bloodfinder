import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'add_donation_page.dart';

class DonationHistoryPage extends StatefulWidget {
  const DonationHistoryPage({super.key});

  @override
  State<DonationHistoryPage> createState() => _DonationHistoryPageState();
}

class _DonationHistoryPageState extends State<DonationHistoryPage> {
  final user = FirebaseAuth.instance.currentUser;

  Future<void> _deleteDonation(String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Delete Donation'),
            IconButton(
              onPressed: () => Navigator.pop(context, false),
              icon: Icon(Icons.close),
            ),
          ],
        ),
        content: const Text('Are you sure you want to delete this donation?'),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .collection('donation')
            .doc(docId)
            .delete();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Donation deleted successfully!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete donation.')),
        );
        print('Error deleting donation: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to view donations.')),
      );
    }

    final donationRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('donation')
        .orderBy('donationDate', descending: true);

    return Scaffold(
      appBar: AppBar(title: const Text('Donation History'), centerTitle: true),
      body: StreamBuilder<QuerySnapshot>(
        stream: donationRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No donations yet.'));
          }

          final donations = snapshot.data!.docs;

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: donations.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final data = donations[index].data() as Map<String, dynamic>;
              final docId = donations[index].id;
              final donationDate = (data['donationDate'] as Timestamp?)
                  ?.toDate();
              final recipientName = data['recipientName'] ?? 'Not specified';
              final recipientMobile = data['recipientMobile'] ?? '-';

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  title: Text(
                    'Donated on: ${donationDate != null ? DateFormat('dd MMM, yyyy').format(donationDate) : '-'}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text('Recipient: $recipientName'),
                      Text('Mobile: $recipientMobile'),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteDonation(docId),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Add Donation'),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddDonationPage()),
          );

          if (result == true) {
            setState(() {}); // Refresh after adding donation
          }
        },
      ),
    );
  }
}
