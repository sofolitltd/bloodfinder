import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/announcement_model.dart';

class AnnouncementDetailPage extends StatelessWidget {
  final AnnouncementModel broadcast;

  const AnnouncementDetailPage({super.key, required this.broadcast});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Announcement'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Badge row
            Row(
              children: [
                _badge(
                  Icons.campaign,
                  'Announcement',
                  Colors.amber.shade50,
                  Colors.amber.shade700,
                ),
                if (broadcast.country != null) ...[
                  SizedBox(width: 8),
                  _badge(
                    Icons.location_on_outlined,
                    broadcast.country!,
                    Colors.blue.shade50,
                    Colors.blue.shade700,
                  ),
                ],
              ],
            ),
            SizedBox(height: 12),

            // Target info
            Text(
              _targetLabel(),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),

            // Timestamp
            Text(
              DateFormat('MMM d, yyyy – h:mm a').format(broadcast.createdAt),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
            SizedBox(height: 16),

            // Title
            Text(
              broadcast.title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),

            // Body
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                broadcast.body,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: Colors.grey.shade800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(IconData icon, String label, Color bg, Color fg) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }

  String _targetLabel() {
    switch (broadcast.target) {
      case 'all':
        return 'Sent to All Users';
      case 'country':
        return 'Sent to users in ${broadcast.country ?? "selected country"}';
      case 'selected':
        return 'Sent to Selected Users';
      default:
        return 'Sent to ${broadcast.target}';
    }
  }
}
