import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'chat_detail_page.dart';

class ChatPage extends StatelessWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: const Text("Chats")),
      body: Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('chats')
              .where('participants', arrayContains: uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError)
              return const Center(child: Text("Error loading chats"));
            if (!snapshot.hasData)
              return const Center(child: CircularProgressIndicator());

            final chatDocs = snapshot.data!.docs;

            if (chatDocs.isEmpty)
              return const Center(child: Text("No chat yet"));

            // Sort by lastMessage timestamp descending (newest first)
            chatDocs.sort((a, b) {
              final t1 =
                  (a['lastMessage']?['timestamp'] as Timestamp?)?.toDate() ??
                  DateTime.fromMillisecondsSinceEpoch(0);
              final t2 =
                  (b['lastMessage']?['timestamp'] as Timestamp?)?.toDate() ??
                  DateTime.fromMillisecondsSinceEpoch(0);
              return t2.compareTo(t1);
            });

            return ListView.separated(
              itemCount: chatDocs.length,
              padding: const EdgeInsets.all(16),
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final chatData = chatDocs[index].data();
                final chatId = chatDocs[index].id;

                final participants = List<String>.from(
                  chatData['participants'],
                );
                final otherUserId = participants.firstWhere((id) => id != uid);

                final lastMessage = chatData['lastMessage'] ?? {};
                final lastText = lastMessage['text'] ?? '';
                final lastSenderId = lastMessage['senderId'] ?? '';
                final seenBy = List<String>.from(lastMessage['seenBy'] ?? []);
                final timestamp = lastMessage['timestamp'] != null
                    ? (lastMessage['timestamp'] as Timestamp).toDate()
                    : null;

                return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  future: FirebaseFirestore.instance
                      .collection('users')
                      .doc(otherUserId)
                      .get(),
                  builder: (context, userSnapshot) {
                    String name = '';
                    String avatarLetter = '';
                    if (userSnapshot.hasData &&
                        userSnapshot.data!.data() != null) {
                      final data = userSnapshot.data!.data()!;
                      name =
                          '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}';
                      avatarLetter = name.isNotEmpty
                          ? name[0].toUpperCase()
                          : '';
                    }

                    return ListTile(
                      horizontalTitleGap: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      leading: CircleAvatar(child: Text(avatarLetter)),
                      title: Row(
                        children: [
                          Expanded(child: Text(name)),
                          if (timestamp != null)
                            Text(
                              timeAgo(timestamp),
                              style: const TextStyle(fontSize: 12),
                            ),
                        ],
                      ),
                      subtitle: Row(
                        children: [
                          if (lastSenderId == uid &&
                              !seenBy.contains(otherUserId))
                            const Icon(
                              Icons.check,
                              size: 16,
                              color: Colors.grey,
                            ),
                          if (lastSenderId == uid &&
                              seenBy.contains(otherUserId))
                            const Icon(
                              Icons.done_all,
                              size: 16,
                              color: Colors.blue,
                            ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              lastText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatDetailPage(chatId: chatId),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  String timeAgo(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
