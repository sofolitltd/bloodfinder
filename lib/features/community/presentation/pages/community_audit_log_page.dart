import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../../data/models/user_model.dart';
import '../../../../data/providers/repository_providers.dart';
import '../../../../data/repositories/user_repository.dart';
import '../../models/audit_log_entry.dart';
import '../../models/community.dart';

/// Shows who approved/removed/promoted whom in this community, and when.
/// Visible to admins/moderators only (gated by the caller).
class CommunityAuditLogPage extends ConsumerWidget {
  final Community community;

  const CommunityAuditLogPage({super.key, required this.community});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final communityRepo = ref.read(communityRepositoryProvider);
    final userRepo = ref.read(userRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity Log'),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: communityRepo.auditLogStream(community.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text('Something went wrong. Please try again.'),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No activity yet.'));
          }

          final entries = snapshot.data!.docs
              .map((doc) {
                try {
                  return AuditLogEntry.fromDoc(doc);
                } catch (_) {
                  return null;
                }
              })
              .whereType<AuditLogEntry>()
              .toList();

          return ListView.separated(
            padding: EdgeInsets.all(16.w),
            itemCount: entries.length,
            separatorBuilder: (_, _) => SizedBox(height: 8.h),
            itemBuilder: (context, index) {
              final entry = entries[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.shade50,
                    child: Icon(PhosphorIcons.clockCounterClockwise,
                        color: Colors.blue.shade600, size: 18.w),
                  ),
                  title: FutureBuilder<String>(
                    future: _resolveName(userRepo, entry.actorUid),
                    builder: (context, actorSnapshot) {
                      final actorName = actorSnapshot.data ?? '...';
                      return Text('$actorName ${entry.description}');
                    },
                  ),
                  subtitle: entry.targetUid == null
                      ? null
                      : FutureBuilder<String>(
                          future: _resolveName(userRepo, entry.targetUid!),
                          builder: (context, targetSnapshot) {
                            final targetName = targetSnapshot.data ?? '...';
                            return Text(targetName);
                          },
                        ),
                  trailing: Text(
                    DateFormat('MMM d, h:mm a')
                        .format(entry.createdAt.toDate()),
                    style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade500),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<String> _resolveName(UserRepository userRepo, String uid) async {
    try {
      final doc = await userRepo.getUser(uid);
      if (!doc.exists) return 'Unknown user';
      final user = UserModel.fromFirestore(doc);
      return '${user.firstName} ${user.lastName}';
    } catch (_) {
      return 'Unknown user';
    }
  }
}
