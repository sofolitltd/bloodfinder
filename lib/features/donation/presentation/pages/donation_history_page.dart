import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../../data/providers/repository_providers.dart';
import '../../../../data/providers/user_providers.dart';
import '../../services/donation_service.dart';
import 'add_donation_page.dart';
import 'certificate_page.dart';

class DonationHistoryPage extends ConsumerStatefulWidget {
  const DonationHistoryPage({super.key});

  @override
  ConsumerState<DonationHistoryPage> createState() =>
      _DonationHistoryPageState();
}

class _DonationHistoryPageState extends ConsumerState<DonationHistoryPage> {
  Future<void> _deleteDonation(String docId) async {
    final userRepo = ref.read(userRepositoryProvider);
    final uid = ref.read(authRepositoryProvider).currentUser!.uid;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Delete Donation'),
            IconButton(
              onPressed: () => Navigator.pop(context, false),
              icon: Icon(PhosphorIcons.x),
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
        await userRepo.deleteDonation(uid, docId);
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

  Future<void> _openCertificate() async {
    final uid = ref.read(authRepositoryProvider).currentUser?.uid;
    if (uid == null) return;

    final userAsync = ref.read(userProvider);
    final userModel = userAsync.value;
    if (userModel == null) return;

    final userRepo = ref.read(userRepositoryProvider);
    final doc = await userRepo.getUser(uid);
    final data = doc.data() as Map<String, dynamic>;
    final count = (data['donationCount'] as num?)?.toInt() ?? 0;
    final badges =
        (data['badges'] as List<dynamic>?)?.cast<String>() ?? [];
    final badge =
        badges.isNotEmpty ? badgeLabel(badges.last) : 'First Hero';

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CertificatePage(
          user: userModel,
          donationCount: count,
          badgeName: badge,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userRepo = ref.read(userRepositoryProvider);
    final uid = ref.read(authRepositoryProvider).currentUser?.uid;

    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to view donations.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Donation History'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.photo_library_outlined),
            tooltip: 'View Hero Card',
            onPressed: _openCertificate,
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: userRepo.donationsStream(uid),
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
              final recipientName =
                  data['recipientName'] ?? 'Not specified';
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
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.share_outlined,
                          color: Colors.red.shade400,
                          size: 20,
                        ),
                        tooltip: 'Share Hero Card',
                        onPressed: _openCertificate,
                      ),
                      IconButton(
                        icon: Icon(
                          PhosphorIcons.trash,
                          color: Colors.red,
                          size: 20,
                        ),
                        onPressed: () => _deleteDonation(docId),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: Icon(PhosphorIcons.plus),
        label: const Text('Add Donation'),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddDonationPage()),
          );

          if (result == true) {
            setState(() {});
          }
        },
      ),
    );
  }
}
