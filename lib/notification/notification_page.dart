// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
//
// import '../data/models/notification.dart';
// import '../features/chat/chat_detail_page.dart';
// import '../features/community/community_details.dart';
//
// class NotificationPage extends StatelessWidget {
//   const NotificationPage({super.key});
//
//   String get _uid => FirebaseAuth.instance.currentUser!.uid;
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Notifications'), centerTitle: true),
//       body: StreamBuilder<QuerySnapshot>(
//         stream: FirebaseFirestore.instance
//             .collection('users')
//             .doc(_uid)
//             .collection('notifications')
//             .orderBy('createdAt', descending: true)
//             .snapshots(),
//         builder: (context, snapshot) {
//           if (!snapshot.hasData) {
//             return const Center(child: CircularProgressIndicator());
//           }
//
//           final docs = snapshot.data!.docs;
//           if (docs.isEmpty) {
//             return const Center(
//               child: Text(
//                 'No notifications yet.',
//                 style: TextStyle(color: Colors.grey),
//               ),
//             );
//           }
//
//           final notifications = docs
//               .map(
//                 (doc) => NotificationModel.fromJson(
//                   doc.data() as Map<String, dynamic>,
//                 ),
//               )
//               .toList();
//
//           return ListView.separated(
//             itemCount: notifications.length,
//             separatorBuilder: (_, __) => const Divider(height: 1),
//             itemBuilder: (context, index) {
//               final notif = notifications[index];
//               return Card(
//                 color: notif.read ? null : Colors.red.shade50,
//                 child: ListTile(
//                   title: Text(notif.title),
//                   subtitle: Text(notif.body),
//                   onTap: () async {
//                     // Mark as read
//                     await FirebaseFirestore.instance
//                         .collection('users')
//                         .doc(_uid)
//                         .collection('notifications')
//                         .doc(notif.id)
//                         .update({'read': true});
//
//                     // Navigate based on type
//                     switch (notif.type) {
//                       case 'chats':
//                         if (notif.data?['chatId'] != null) {
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                               builder: (_) =>
//                                   ChatDetailPage(chatId: notif.data!['chatId']),
//                             ),
//                           );
//                         }
//                         break;
//                       case 'community':
//                         if (notif.data?['communityId'] != null) {
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                               builder: (_) => CommunityDetailsPage(
//                                 communityId: notif.data!['communityId'],
//                               ),
//                             ),
//                           );
//                         }
//                         break;
//                       default:
//                         ScaffoldMessenger.of(context).showSnackBar(
//                           const SnackBar(
//                             content: Text('Unknown notification type'),
//                           ),
//                         );
//                     }
//                   },
//                 ),
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
// }

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/notification.dart';
import '../data/providers/notification_provider.dart';
import '../routes/router_config.dart';

class NotificationPage extends ConsumerStatefulWidget {
  final String userId;

  const NotificationPage({super.key, required this.userId});

  @override
  ConsumerState<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends ConsumerState<NotificationPage> {
  final ScrollController _controller = ScrollController();
  DocumentSnapshot? lastDoc;
  bool isLoadingMore = false;
  List<NotificationModel> notifications = [];

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);
  }

  void _onScroll() {
    if (_controller.position.pixels >=
        _controller.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (isLoadingMore) return;
    isLoadingMore = true;

    final repo = ref.read(notificationRepositoryProvider);
    final stream = repo.getNotifications(
      userId: widget.userId,
      startAfter: lastDoc,
      limit: 20,
    );
    final snapshot = await stream.first;
    if (snapshot.isNotEmpty) {
      lastDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('notifications')
          .doc(snapshot.last.id)
          .get();
      notifications.addAll(snapshot);
      setState(() {});
    }

    isLoadingMore = false;
  }

  @override
  Widget build(BuildContext context) {
    final asyncNotifications = ref.watch(
      notificationsStreamProvider(widget.userId),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications'), centerTitle: true),
      body: asyncNotifications.when(
        data: (list) {
          notifications = list;
          return ListView.separated(
            separatorBuilder: (_, __) => const Divider(height: 1),
            controller: _controller,
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final n = notifications[index];

              // if no notifications then show msg
              if (notifications.isEmpty) {
                return const Center(
                  child: Text(
                    'No notifications yet.',
                    style: TextStyle(color: Colors.grey),
                  ),
                );
              }

              //
              return Card(
                color: n.read ? null : Colors.red.shade50,
                child: ListTile(
                  title: Row(
                    children: [
                      Expanded(child: Text(n.title)),
                      Text(
                        timeAgo(n.createdAt),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  subtitle: Text(n.body),

                  onTap: () async {
                    // mark as read
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(widget.userId)
                        .collection('notifications')
                        .doc(n.id)
                        .update({'read': true});
                    // handle navigation based on type
                    switch (n.type) {
                      case 'chats':
                        final chatId = n.data['chatId'];
                        if (chatId != null) {
                          // routerConfig.push('/chats');
                          routerConfig.push('/chats/$chatId');
                        }
                        break;
                      case 'community':
                        final communityId = n.data['communityId'];
                        if (communityId != null) {
                          // routerConfig.push('/community');
                          routerConfig.push('/community/$communityId');
                        }
                        break;
                      default:
                        routerConfig.go('/notification');
                    }
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

String timeAgo(DateTime dt) {
  final now = DateTime.now();
  final diff = now.difference(dt);
  if (diff.inMinutes < 1) return 'now';
  if (diff.inHours < 1) return '${diff.inMinutes}m ago';
  if (diff.inDays < 1) return '${diff.inHours}h ago';
  return '${diff.inDays}d ago';
}
