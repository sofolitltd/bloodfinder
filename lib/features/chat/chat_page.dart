import 'package:bloodfinder/data/models/user_model.dart';
import 'package:bloodfinder/routes/app_route.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final uid = FirebaseAuth.instance.currentUser!.uid;
  String? selectedChatId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: selectedChatId == null
            ? Text("Chats")
            : IconButton(
                icon: Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    selectedChatId = null;
                  });
                },
              ),
        actions: selectedChatId != null
            ? [
                IconButton(
                  onPressed: () => _archiveChat(selectedChatId!),
                  icon: const Icon(Icons.archive),
                  tooltip: 'Archive',
                ),
                IconButton(
                  onPressed: () => _deleteChatWithConfirm(selectedChatId!),
                  icon: const Icon(Icons.delete),
                  tooltip: 'Delete',
                ),
              ]
            : null,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .where('participants', arrayContains: uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text("Error"));
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final chatDocs = snapshot.data!.docs;

          // Determine if any chat is archived
          final hasArchived = chatDocs.any((doc) {
            final archivedBy = List<String>.from(doc['archivedBy'] ?? []);
            return archivedBy.contains(uid);
          });

          // Filter active chats
          final filteredChats = chatDocs.where((doc) {
            final data = doc.data();
            final archivedBy = List<String>.from(data['archivedBy'] ?? []);
            final deletedBy = List<String>.from(data['deletedBy'] ?? []);
            return !archivedBy.contains(uid) && !deletedBy.contains(uid);
          }).toList();

          // Sort by lastMessage timestamp descending
          filteredChats.sort((a, b) {
            final t1 =
                (a['lastMessage']?['timestamp'] as Timestamp?)?.toDate() ??
                DateTime.fromMillisecondsSinceEpoch(0);
            final t2 =
                (b['lastMessage']?['timestamp'] as Timestamp?)?.toDate() ??
                DateTime.fromMillisecondsSinceEpoch(0);
            return t2.compareTo(t1);
          });

          return Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Archive button appears only if any chat is archived
              if (hasArchived)
                Card(
                  child: ListTile(
                    onTap: () {
                      GoRouter.of(context).push(AppRoute.archive.path);
                    },
                    leading: Icon(Icons.archive_outlined),
                    title: const Text("View Archived Chats"),
                  ),
                ),

              //
              if (!hasArchived) SizedBox(height: 8),

              Expanded(
                child: filteredChats.isEmpty
                    ? const Center(child: Text("No active chats"))
                    : ListView.separated(
                        itemCount: filteredChats.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final chatDoc = filteredChats[index];
                          final chatData = chatDoc.data();
                          final chatId = chatDoc.id;

                          final participants = List<String>.from(
                            chatData['participants'],
                          );
                          final otherUserId = participants.firstWhere(
                            (id) => id != uid,
                            orElse: () => '',
                          );
                          if (otherUserId.isEmpty) return const SizedBox();

                          final lastMessage = chatData['lastMessage'] ?? {};
                          final lastText = lastMessage['text'] ?? '';
                          final lastSenderId = lastMessage['senderId'] ?? '';
                          final seenBy = List<String>.from(
                            lastMessage['seenBy'] ?? [],
                          );
                          final timestamp = lastMessage['timestamp'] != null
                              ? (lastMessage['timestamp'] as Timestamp).toDate()
                              : null;

                          return FutureBuilder<
                            DocumentSnapshot<Map<String, dynamic>>
                          >(
                            future: FirebaseFirestore.instance
                                .collection('users')
                                .doc(otherUserId)
                                .get(),
                            builder: (context, userSnapshot) {
                              String name = '';
                              String avatarLetter = '';
                              String image = '';

                              if (userSnapshot.hasData &&
                                  userSnapshot.data!.data() != null) {
                                final data = userSnapshot.data!.data()!;
                                UserModel user = UserModel.fromJson(data);
                                name = '${user.firstName} ${user.lastName}';
                                avatarLetter = user.firstName.isNotEmpty
                                    ? user.firstName[0].toUpperCase()
                                    : '';
                                image = user.image;
                              }

                              return GestureDetector(
                                onLongPress: () =>
                                    setState(() => selectedChatId = chatId),
                                child: Card(
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    horizontalTitleGap: 8,
                                    leading: CircleAvatar(
                                      radius: 20,
                                      backgroundColor:
                                          Colors.redAccent.shade200,
                                      child: image.isEmpty
                                          ? Text(
                                              avatarLetter,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 20,
                                              ),
                                            )
                                          : ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(50),
                                              child: CachedNetworkImage(
                                                imageUrl: image,
                                                width: 40,
                                                height: 40,
                                                fit: BoxFit.cover,
                                                placeholder: (context, url) =>
                                                    const CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                    ),
                                                errorWidget:
                                                    (
                                                      context,
                                                      url,
                                                      error,
                                                    ) => Center(
                                                      child: Text(
                                                        avatarLetter,
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 20,
                                                        ),
                                                      ),
                                                    ),
                                              ),
                                            ),
                                    ),
                                    title: Row(
                                      children: [
                                        Expanded(child: Text(name)),
                                        if (timestamp != null)
                                          Text(
                                            timeAgo(timestamp),
                                            style: const TextStyle(
                                              fontSize: 12,
                                            ),
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
                                    onTap: () => GoRouter.of(
                                      context,
                                    ).push('/chats/$chatId'),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
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

  Future<void> _archiveChat(String chatId) async {
    await FirebaseFirestore.instance.collection('chats').doc(chatId).update({
      'archivedBy': FieldValue.arrayUnion([uid]),
    });
    setState(() => selectedChatId = null);
  }

  Future<void> _deleteChatWithConfirm(String chatId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Chat'),
        content: const Text('Are you sure you want to delete this chat?'),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Cancel'),
          ),

          //
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              visualDensity: VisualDensity.compact,
            ),
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('chats')
                  .doc(chatId)
                  .update({
                    'deletedBy': FieldValue.arrayUnion([uid]),
                  });
              context.pop();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
