import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../../data/providers/repository_providers.dart';

class ArchivedMessagesPage extends ConsumerStatefulWidget {
  const ArchivedMessagesPage({super.key});

  @override
  ConsumerState<ArchivedMessagesPage> createState() => _ArchivedMessagesPageState();
}

class _ArchivedMessagesPageState extends ConsumerState<ArchivedMessagesPage> {
  late final String uid = ref.read(authRepositoryProvider).currentUser!.uid;
  String? selectedChatId;

  @override
  Widget build(BuildContext context) {
    final communityRepo = ref.read(communityRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Archived Chats"),
        centerTitle: true,
        actions: [
          if (selectedChatId != null)
            IconButton(
              icon: Icon(PhosphorIcons.archive),
              tooltip: 'Unarchive',
              onPressed: () => _unarchiveChat(selectedChatId!),
            ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: communityRepo.userChatsStream(uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Error loading chats"));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final chatDocs = snapshot.data!.docs.where((doc) {
            final archivedBy = List<String>.from(doc['archivedBy'] ?? []);
            return archivedBy.contains(uid);
          }).toList();

          if (chatDocs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    PhosphorIcons.archive,
                    size: 100.w,
                    color: Colors.grey.shade300,
                  ),
                  SizedBox(height: 10.h),
                  const Text("No archived chats"),
                ],
              ),
            );
          }

          // Sort by lastMessage timestamp descending
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
            padding: EdgeInsets.symmetric(vertical: 8.h),
            separatorBuilder: (_, __) => SizedBox(height: 12.h),
            itemBuilder: (context, index) {
              final chatDoc = chatDocs[index];
              final chatData = chatDoc.data();
              final chatId = chatDoc.id;
              final participants = List<String>.from(chatData['participants']);
              final otherUserId = participants.firstWhere(
                (id) => id != uid,
                orElse: () => '',
              );

              if (otherUserId.isEmpty) return const SizedBox();

              final lastMessage = chatData['lastMessage'] ?? {};
              final lastText = lastMessage['text'] ?? '';
              final lastSenderId = lastMessage['senderId'] ?? '';
              final seenBy = List<String>.from(lastMessage['seenBy'] ?? []);
              final timestamp = lastMessage['timestamp'] != null
                  ? (lastMessage['timestamp'] as Timestamp).toDate()
                  : null;

              return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                future: ref.read(userRepositoryProvider).getUser(otherUserId),
                builder: (context, userSnapshot) {
                  String name = '';
                  String avatarLetter = '';
                  String image = '';

                  if (userSnapshot.hasData &&
                      userSnapshot.data!.data() != null) {
                    final data = userSnapshot.data!.data()!;
                    name =
                        '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}';
                    avatarLetter = (data['firstName'] ?? '').isNotEmpty
                        ? data['firstName'][0].toUpperCase()
                        : '';
                    image = data['image'] ?? '';
                  }

                  return GestureDetector(
                    onLongPress: () {
                      setState(() {
                        selectedChatId = chatId;
                      });
                    },
                      child: Card(
                        child: ListTile(
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                          ),
                          horizontalTitleGap: 8.w,
                          leading: CircleAvatar(
                            radius: 20.r,
                            backgroundColor: Colors.redAccent.shade200,
                            child: image.isEmpty
                                ? Text(
                                    avatarLetter,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20.sp,
                                    ),
                                  )
                                : ClipRRect(
                                    borderRadius: BorderRadius.circular(50.r),
                                    child: Image.network(
                                      image,
                                      width: 40.w,
                                      height: 40.h,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                          ),
                          title: Row(
                            children: [
                              Expanded(child: Text(name)),
                              if (timestamp != null)
                                Text(
                                  timeAgo(timestamp),
                                  style: TextStyle(fontSize: 12.sp),
                                ),
                          ],
                        ),
                        subtitle: Row(
                          children: [
                            if (lastSenderId == uid &&
                                !seenBy.contains(otherUserId))
                              Icon(
                                Icons.check,
                                size: 16.w,
                                color: Colors.grey,
                              ),
                            if (lastSenderId == uid &&
                                seenBy.contains(otherUserId))
                              Icon(
                                Icons.done_all,
                                size: 16.w,
                                color: Colors.blue,
                              ),
                            SizedBox(width: 4.w),
                            Expanded(
                              child: Text(
                                lastText,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        onTap: () =>
                            GoRouter.of(context).push('/chats/$chatId'),
                      ),
                    ),
                  );
                },
              );
            },
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

  Future<void> _unarchiveChat(String chatId) async {
    await ref.read(communityRepositoryProvider).updateChat(chatId, {
      'archivedBy': FieldValue.arrayRemove([uid]),
    });
    setState(() {
      selectedChatId = null;
    });
  }
}
