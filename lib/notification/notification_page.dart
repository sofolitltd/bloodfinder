import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../data/models/notification.dart';
import '../features/chat/chat_detail_page.dart';
import '../features/community/community_details.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications'), centerTitle: true),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(_uid)
            .collection('notifications')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(
              child: Text(
                'No notifications yet.',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          final notifications = docs
              .map(
                (doc) => NotificationModel.fromJson(
                  doc.data() as Map<String, dynamic>,
                ),
              )
              .toList();

          return ListView.separated(
            itemCount: notifications.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final notif = notifications[index];
              return ListTile(
                title: Text(notif.title),
                subtitle: Text(notif.body),
                trailing: notif.read
                    ? null
                    : const Icon(Icons.circle, color: Colors.red, size: 10),
                onTap: () async {
                  // Mark as read
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(_uid)
                      .collection('notifications')
                      .doc(notif.id)
                      .update({'read': true});

                  // Navigate based on type
                  switch (notif.type) {
                    case 'chats':
                      if (notif.data?['chatId'] != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ChatDetailPage(chatId: notif.data!['chatId']),
                          ),
                        );
                      }
                      break;
                    case 'community':
                      if (notif.data?['communityId'] != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CommunityDetailsPage(
                              communityId: notif.data!['communityId'],
                            ),
                          ),
                        );
                      }
                      break;
                    default:
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Unknown notification type'),
                        ),
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
