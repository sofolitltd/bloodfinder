import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
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
class CommunityAuditLogPage extends StatelessWidget {
  final Community community;

  const CommunityAuditLogPage({super.key, required this.community});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Activity Log'), centerTitle: true),
      body: CommunityAuditLogBody(community: community),
    );
  }
}

/// Body-only activity log list, reusable outside a dedicated [Scaffold]
/// (e.g. as a tab in [CommunityManagePage]).
class CommunityAuditLogBody extends ConsumerWidget {
  final Community community;

  const CommunityAuditLogBody({super.key, required this.community});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final communityRepo = ref.read(communityRepositoryProvider);
    final userRepo = ref.read(userRepositoryProvider);

    return StreamBuilder<QuerySnapshot>(
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
          padding: EdgeInsets.all(16),
          itemCount: entries.length,
          separatorBuilder: (_, _) => SizedBox(height: 10),
          itemBuilder: (context, index) {
            final entry = entries[index];
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      PhosphorIcons.clockCounterClockwise,
                      color: Colors.blue.shade600,
                      size: 18,
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FutureBuilder<String>(
                          future: _resolveName(userRepo, entry.actorUid),
                          builder: (context, actorSnapshot) {
                            final actorName = actorSnapshot.data ?? '...';
                            return Text.rich(
                              TextSpan(
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade800,
                                  height: 1.3,
                                ),
                                children: [
                                  TextSpan(
                                    text: actorName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  TextSpan(text: ' ${entry.description}'),
                                ],
                              ),
                            );
                          },
                        ),
                        if (entry.targetUid != null) ...[
                          SizedBox(height: 4),
                          FutureBuilder<String>(
                            future: _resolveName(userRepo, entry.targetUid!),
                            builder: (context, targetSnapshot) {
                              final targetName = targetSnapshot.data ?? '...';
                              return Text(
                                targetName,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade600,
                                ),
                              );
                            },
                          ),
                        ],
                        SizedBox(height: 6),
                        Text(
                          DateFormat(
                            'MMM d, h:mm a',
                          ).format(entry.createdAt.toDate()),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
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
