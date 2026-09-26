import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../data/providers/repository_providers.dart';
import '../../../../shared/widgets/start_chat_btn.dart';
import '../../models/notification.dart';

class NotificationDetailPage extends StatelessWidget {
  final NotificationModel notification;

  const NotificationDetailPage({super.key, required this.notification});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Type badge
            _buildTypeBadge(),
            SizedBox(height: 16.h),

            // Title
            Text(
              notification.title,
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8.h),

            // Timestamp
            Text(
              DateFormat('MMM d, yyyy – h:mm a').format(notification.createdAt),
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.grey.shade500,
              ),
            ),
            SizedBox(height: 20.h),

            // Body
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Text(
                notification.body,
                style: TextStyle(
                  fontSize: 15.sp,
                  height: 1.5,
                  color: Colors.grey.shade800,
                ),
              ),
            ),

            // Action button (only for notifications with a destination)
            if (_actionAvailable()) ...[
              SizedBox(height: 32.h),
              if (notification.type == 'community_invite')
                _CommunityInviteActions(notification: notification)
              else if (notification.type == 'community_blood_help_request')
                _ContactRequesterAction(notification: notification)
              else
                _buildActionButton(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTypeBadge() {
    String label;
    Color bg;
    Color fg;
    IconData icon;

    switch (notification.type) {
      case 'chats':
        label = 'Chat Message';
        bg = Colors.blue.shade50;
        fg = Colors.blue.shade700;
        icon = Icons.chat_bubble_outline;
        break;
      case 'community':
        label = 'Community Update';
        bg = Colors.green.shade50;
        fg = Colors.green.shade700;
        icon = Icons.groups_outlined;
        break;
      case 'community_invite':
        label = 'Community Invite';
        bg = Colors.teal.shade50;
        fg = Colors.teal.shade700;
        icon = Icons.mail_outline;
        break;
      case 'community_blood_help_request':
        label = 'Blood Help Request';
        bg = Colors.red.shade50;
        fg = Colors.red.shade700;
        icon = Icons.bloodtype_outlined;
        break;
      case 'event':
        label = 'Event';
        bg = Colors.purple.shade50;
        fg = Colors.purple.shade700;
        icon = Icons.event_outlined;
        break;
      default:
        // admin notifications
        label = 'From Admin';
        bg = Colors.amber.shade50;
        fg = Colors.amber.shade700;
        icon = Icons.campaign_outlined;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16.w, color: fg),
          SizedBox(width: 6.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }

  bool _actionAvailable() {
    // Only show action button for notifications with a real destination
    switch (notification.type) {
      case 'chats':
        return notification.data['chatId'] != null;
      case 'community':
        return notification.data['communityId'] != null;
      case 'community_invite':
        return notification.data['communityId'] != null;
      case 'community_blood_help_request':
        return notification.data['requesterUid'] != null;
      case 'event':
        return true;
      default:
        return false; // admin — no action
    }
  }

  Widget _buildActionButton(BuildContext context) {
    String? routePath;
    String buttonLabel;
    IconData buttonIcon;

    switch (notification.type) {
      case 'chats':
        final chatId = notification.data['chatId'];
        routePath = chatId != null ? '/chats/$chatId' : null;
        buttonLabel = 'Open Chat';
        buttonIcon = Icons.chat_bubble_outline;
        break;
      case 'community':
        final communityId = notification.data['communityId'];
        routePath = communityId != null ? '/community/$communityId' : null;
        buttonLabel = 'View Community';
        buttonIcon = Icons.groups_outlined;
        break;
      case 'event':
        routePath = '/events';
        buttonLabel = 'View Events';
        buttonIcon = Icons.event_outlined;
        break;
      default:
        return const SizedBox.shrink();
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          if (routePath != null) {
            GoRouter.of(context).go(routePath);
          } else {
            Navigator.pop(context);
          }
        },
        icon: Icon(buttonIcon),
        label: Text(buttonLabel),
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 14.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
      ),
    );
  }
}

/// Accept/Decline actions for a `community_invite` notification.
class _CommunityInviteActions extends ConsumerStatefulWidget {
  final NotificationModel notification;

  const _CommunityInviteActions({required this.notification});

  @override
  ConsumerState<_CommunityInviteActions> createState() =>
      _CommunityInviteActionsState();
}

class _CommunityInviteActionsState
    extends ConsumerState<_CommunityInviteActions> {
  bool _isProcessing = false;

  Future<void> _respond(bool accept) async {
    setState(() => _isProcessing = true);
    try {
      final communityRepo = ref.read(communityRepositoryProvider);
      final currentUserId = ref.read(authRepositoryProvider).currentUser!.uid;
      final communityId = widget.notification.data['communityId'] as String;

      if (accept) {
        final bloodGroup =
            widget.notification.data['bloodGroup'] as String? ?? '';
        await communityRepo.approveMemberAndUpdateCounts(
            communityId, currentUserId, bloodGroup);
      } else {
        await communityRepo.removeMember(communityId, currentUserId);
      }

      try {
        await communityRepo.markNotificationRead(
            currentUserId, widget.notification.id);
      } catch (_) {
        // Non-critical.
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(accept
                ? 'You\'ve joined the community.'
                : 'Invite declined.'),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Something went wrong. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isProcessing ? null : () => _respond(false),
            child: const Text('Decline'),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: ElevatedButton(
            onPressed: _isProcessing ? null : () => _respond(true),
            child: _isProcessing
                ? SizedBox(
                    width: 18.w,
                    height: 18.h,
                    child: const CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                : const Text('Accept'),
          ),
        ),
      ],
    );
  }
}

/// "Contact Requester" action for a `community_blood_help_request`
/// notification — reuses [StartChatButton]'s find-or-create chat logic so
/// the admin/moderator can message the requester even though they were
/// never a community member.
class _ContactRequesterAction extends StatelessWidget {
  final NotificationModel notification;

  const _ContactRequesterAction({required this.notification});

  @override
  Widget build(BuildContext context) {
    final requesterUid = notification.data['requesterUid'] as String;
    return SizedBox(
      width: double.infinity,
      height: 48.h,
      child: StartChatButton(
        otherUserId: requesterUid,
        buttonText: 'Contact Requester',
      ),
    );
  }
}
