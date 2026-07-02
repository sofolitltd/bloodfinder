import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

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
