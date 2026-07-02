import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
  @override
  Widget build(BuildContext context) {
    final uid = ref.read(authRepositoryProvider).currentUser!.uid;
    final bloodRequestRepo = ref.read(bloodRequestRepositoryProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Blood Requests'),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const BloodRequestPage()),
          );
        },
        backgroundColor: Colors.red.shade600,
        icon: Icon(PhosphorIcons.plusBold, color: Colors.white),
        label: const Text('Post Blood Request', style: TextStyle(color: Colors.white)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: bloodRequestRepo.userRequestsStream(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Padding(
              padding: EdgeInsets.all(16.w),
              child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(PhosphorIcons.drop, size: 64.w, color: Colors.grey.shade300),
                  SizedBox(height: 8.h),
                  Text(
                    'No blood requests yet',
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const BloodRequestPage()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      minimumSize: Size(200, 40),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: Icon(PhosphorIcons.plus, color: Colors.white),
                    label: const Text('Post Your First Request', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
              ),
            );
          }

          final requests = snapshot.data!.docs
              .map(
                (doc) => BloodRequest.fromFirestore(doc),
              )
              .toList();

          return ListView.separated(
            padding: EdgeInsets.all(16.w),
            itemCount: requests.length,
            separatorBuilder: (_, __) => SizedBox(height: 8.h),
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
                              foregroundColor: Colors.red),
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
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
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
