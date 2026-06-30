import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../data/providers/repository_providers.dart';
import '../../features/chat/models/chat_model.dart';

class StartChatButton extends ConsumerStatefulWidget {
  final String otherUserId;
  final String buttonText;

  const StartChatButton({
    super.key,
    required this.otherUserId,
    this.buttonText = "Message",
  });

  @override
  ConsumerState<StartChatButton> createState() => _StartChatButtonState();
}

class _StartChatButtonState extends ConsumerState<StartChatButton> {
  bool isLoading = false;

  Future<void> _startChat() async {
    setState(() => isLoading = true);

    try {
      final currentUserID = ref.read(authRepositoryProvider).currentUser!.uid;
      final communityRepo = ref.read(communityRepositoryProvider);

      final existingChats = await communityRepo.getExistingChat(
        currentUserID,
        widget.otherUserId,
      );

      DocumentSnapshot<Map<String, dynamic>>? chatDoc;
      if (existingChats.isNotEmpty) {
        chatDoc = existingChats.first;
      }

      if (chatDoc == null) {
        final emptyMsg = MessageModel(
          id: '',
          senderId: '',
          text: 'Hi! Feel free to send your first message.',
          timestamp: DateTime.now(),
          seenBy: [],
        );

        final newChatRef = await communityRepo.addChat({
          'participants': [currentUserID, widget.otherUserId],
          'lastMessage': emptyMsg.toMap(),
          'lastTime': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
          'archivedBy': [],
          'deletedBy': [],
        });
        chatDoc = await newChatRef.get();
      }

      GoRouter.of(context).push(
        '/chats/${chatDoc.id}',
        extra: {'donorId': currentUserID, 'requesterId': widget.otherUserId},
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to start chat: $e')));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserID = ref.read(authRepositoryProvider).currentUser!.uid;
    final isSelf = widget.otherUserId == currentUserID;

    return ElevatedButton.icon(
      onPressed: isLoading || isSelf ? null : _startChat,
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelf ? Colors.grey : Colors.blue.shade300,
        visualDensity: VisualDensity.compact,
      ),
      icon: Icon(PhosphorIcons.chatDots, size: 14.w),
      label: isLoading
          ? SizedBox(
              width: 18.w,
              height: 18.h,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : Text(isSelf ? "Can't message" : widget.buttonText),
    );
  }
}
