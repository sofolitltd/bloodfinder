import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../../data/providers/repository_providers.dart';
import '../../models/announcement.dart';
import '../../models/community.dart';
import 'create_announcement_sheet.dart';

/// Shows a community's announcements to any viewer (member or not) — a
/// lightweight bulletin board. Only admins/moderators can post/pin/delete.
class AnnouncementsSection extends ConsumerWidget {
  final Community community;
  final String uid;

  const AnnouncementsSection({
    super.key,
    required this.community,
    required this.uid,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final communityRepo = ref.read(communityRepositoryProvider);
    final canManage = community.canManageMembers(uid);

    return StreamBuilder<QuerySnapshot>(
      stream: communityRepo.announcementsStream(community.id),
      builder: (context, snapshot) {
        final announcements = (snapshot.data?.docs ?? [])
            .map((doc) {
              try {
                return Announcement.fromDoc(doc);
              } catch (_) {
                return null;
              }
            })
            .whereType<Announcement>()
            .toList()
          ..sort((a, b) {
            if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
            return b.createdAt.compareTo(a.createdAt);
          });

        if (announcements.isEmpty && !canManage) {
          return const SizedBox.shrink();
        }

        return Container(
          width: double.infinity,
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
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(PhosphorIcons.megaphone,
                        size: 15, color: Colors.amber.shade700),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Announcements',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const Spacer(),
                  if (canManage)
                    IconButton(
                      icon: Icon(PhosphorIcons.plus, size: 18),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                                top: Radius.circular(20)),
                          ),
                          builder: (context) =>
                              CreateAnnouncementSheet(community: community),
                        );
                      },
                    ),
                ],
              ),
              if (announcements.isEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'No announcements yet.',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                  ),
                )
              else
                ...announcements.map((a) => _AnnouncementTile(
                      announcement: a,
                      canManage: canManage,
                      onPin: () => communityRepo.setAnnouncementPinned(
                          a.id, !a.pinned),
                      onDelete: () =>
                          communityRepo.deleteAnnouncement(a.id),
                    )),
            ],
          ),
        );
      },
    );
  }
}

class _AnnouncementTile extends StatelessWidget {
  final Announcement announcement;
  final bool canManage;
  final VoidCallback onPin;
  final VoidCallback onDelete;

  const _AnnouncementTile({
    required this.announcement,
    required this.canManage,
    required this.onPin,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: announcement.pinned ? Colors.amber.shade50 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (announcement.pinned) ...[
                Icon(PhosphorIcons.pushPin,
                    size: 14, color: Colors.amber.shade700),
                SizedBox(width: 6),
              ],
              Expanded(
                child: Text(
                  DateFormat('MMM d, yyyy · h:mm a')
                      .format(announcement.createdAt.toDate()),
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ),
              if (canManage)
                PopupMenuButton<String>(
                  icon: Icon(PhosphorIcons.dotsThreeVertical, size: 16),
                  onSelected: (value) {
                    if (value == 'pin') onPin();
                    if (value == 'delete') onDelete();
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'pin',
                      child: Text(announcement.pinned ? 'Unpin' : 'Pin'),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete'),
                    ),
                  ],
                ),
            ],
          ),
          SizedBox(height: 4),
          Text(
            announcement.message,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade800),
          ),
        ],
      ),
    );
  }
}
