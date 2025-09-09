import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/chat_model.dart';

class StartChatButton extends StatefulWidget {
  final String otherUserId;
  final String buttonText;

  const StartChatButton({
    super.key,
    required this.otherUserId,
    this.buttonText = "Message",
  });

  @override
  State<StartChatButton> createState() => _StartChatButtonState();
}

class _StartChatButtonState extends State<StartChatButton> {
  bool isLoading = false;

  Future<void> _startChat() async {
    setState(() => isLoading = true);

    try {
      final currentUserID = FirebaseAuth.instance.currentUser!.uid;
      final chatsCollection = FirebaseFirestore.instance.collection('chats');

      // Check if chat exists
      final chatQuery = await chatsCollection
          .where('participants', arrayContains: currentUserID)
          .get();

      DocumentSnapshot? chatDoc;
      for (var doc in chatQuery.docs) {
        final participants = List<String>.from(doc['participants']);
        if (participants.contains(widget.otherUserId)) {
          chatDoc = doc;
          break;
        }
      }

      // If no chat exists, create a new one
      if (chatDoc == null) {
        // create an "empty" last message using your model
        final emptyMsg = MessageModel(
          id: '',
          senderId: '',
          text: 'Hi! Feel free to send your first message.',
          timestamp: DateTime.now(),
          seenBy: [],
        );

        //
        final newChatRef = await chatsCollection.add({
          'participants': [currentUserID, widget.otherUserId],
          'lastMessage': emptyMsg.toMap(),
          'lastTime': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
          'archivedBy': [],
          'deletedBy': [],
        });
        chatDoc = await newChatRef.get();
      }

      // Navigate to chat page
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
    final currentUserID = FirebaseAuth.instance.currentUser!.uid;
    final isSelf = widget.otherUserId == currentUserID;

    return ElevatedButton(
      onPressed: isLoading || isSelf ? null : _startChat,
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelf ? Colors.grey : Colors.blue.shade300,
        visualDensity: VisualDensity(vertical: -3),
        padding: const EdgeInsets.symmetric(horizontal: 10),
      ),
      child: isLoading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : Text(isSelf ? "Can't message" : widget.buttonText),
    );
  }
}
