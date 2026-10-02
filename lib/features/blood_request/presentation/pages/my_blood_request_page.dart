import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../../data/providers/repository_providers.dart';
import '../../../../shared/widgets/blood_request_card.dart';
import '../../models/blood_request.dart';
import 'post_blood_request_page.dart';

class MyBloodRequestsPage extends ConsumerStatefulWidget {
  const MyBloodRequestsPage({super.key});

  @override
  ConsumerState<MyBloodRequestsPage> createState() =>
      _MyBloodRequestsPageState();
}

class _MyBloodRequestsPageState extends ConsumerState<MyBloodRequestsPage> {
  void _openPostRequestPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const BloodRequestPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = ref.read(authRepositoryProvider).currentUser!.uid;
    final bloodRequestRepo = ref.read(bloodRequestRepositoryProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('My Blood Requests'), centerTitle: true),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openPostRequestPage,
        backgroundColor: Colors.red.shade600,
        icon: Icon(PhosphorIcons.plusBold, color: Colors.white),
        label: const Text(
          'Post Blood Request',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: bloodRequestRepo.userRequestsStream(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      PhosphorIcons.drop,
                      size: 64,
                      color: Colors.grey.shade300,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'No blood requests yet',
                      style: TextStyle(
                        fontSize: 16,
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final requests = snapshot.data!.docs
              .map((doc) => BloodRequest.fromFirestore(doc))
              .toList();

          final expiredToHeal = requests
              .where((r) => r.isActive && r.isExpired)
              .toList();
          if (expiredToHeal.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              for (final r in expiredToHeal) {
                bloodRequestRepo.updateRequestStatus(r.id, 'expired');
              }
            });
          }

          return ListView.separated(
            padding: EdgeInsets.all(16),
            itemCount: requests.length,
            separatorBuilder: (_, _) => SizedBox(height: 8),
            itemBuilder: (context, index) {
              final req = requests[index];

              return BloodRequestCard(
                request: req,
                embedded: true,
                onEdit: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BloodRequestPage(existingRequest: req),
                    ),
                  );
                },
                onDelete: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    useRootNavigator: true,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Delete Request'),
                      content: const Text(
                        'Are you sure? This cannot be undone.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed != true) return;
                  if (!context.mounted) return;
                  try {
                    await ref
                        .read(bloodRequestRepositoryProvider)
                        .deleteRequest(req.id);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Request deleted successfully'),
                      ),
                    );
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}
