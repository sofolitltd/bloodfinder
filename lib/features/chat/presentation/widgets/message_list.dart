import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/providers/repository_providers.dart';
import '../../models/chat_model.dart';
import 'message_bubble.dart';

class MessageList extends ConsumerWidget {
  final String chatId;
  final String uid;
  final String? otherUserId;
  final ScrollController scrollController;
  final String Function(DateTime) formatTime;
  final void Function(MessageModel) onMessageLongPress;

  const MessageList({
    super.key,
    required this.chatId,
    required this.uid,
    required this.otherUserId,
    required this.scrollController,
    required this.formatTime,
    required this.onMessageLongPress,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final communityRepo = ref.read(communityRepositoryProvider);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: communityRepo.messagesStream(chatId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final messages = snapshot.data!.docs
            .map((doc) => MessageModel.fromMap(doc.id, doc.data()))
            .toList();

        for (var msg in messages) {
          if (msg.senderId != uid && !msg.seenBy.contains(uid)) {
            communityRepo.updateMessage(chatId, msg.id, {
              'seenBy': FieldValue.arrayUnion([uid]),
            });

            communityRepo.updateChat(chatId, {
              'lastMessage.seenBy': FieldValue.arrayUnion([uid]),
            });
          }
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (scrollController.hasClients) {
            scrollController.jumpTo(
              scrollController.position.maxScrollExtent,
            );
          }
        });

        return ListView.builder(
          controller: scrollController,
          padding: const EdgeInsets.all(16),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final msg = messages[index];
            final isMe = msg.senderId == uid;

            return MessageBubble(
              message: msg,
              isMe: isMe,
              otherUserId: otherUserId,
              formatTime: formatTime,
              onLongPress: () => onMessageLongPress(msg),
            );
          },
        );
      },
    );
  }
}
