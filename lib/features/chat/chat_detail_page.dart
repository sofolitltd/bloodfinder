import 'package:bloodfinder/notification/fcm_sender.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../data/models/chat_model.dart';

class ChatDetailPage extends StatefulWidget {
  final String chatId;

  const ChatDetailPage({super.key, required this.chatId});

  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final String _uid = FirebaseAuth.instance.currentUser!.uid;
  final FocusNode _focusNode = FocusNode();

  String? otherUserId;
  String? otherUserImage;
  String? otherUserName;
  String? token = "";

  MessageModel? _selectedMessage;
  bool _showOverlay = false;
  bool _isEditing = false;
  bool isOtherUserOnline = false;

  @override
  void initState() {
    super.initState();
    _fetchOtherUser();
    _setOnlineStatus(true);
    _controller.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _setOnlineStatus(false);
    _focusNode.dispose();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchOtherUser() async {
    final chatDoc = await _firestore
        .collection('chats')
        .doc(widget.chatId)
        .get();
    final participants = List<String>.from(chatDoc['participants']);
    otherUserId = participants.firstWhere((id) => id != _uid);

    final userDoc = await _firestore.collection('users').doc(otherUserId).get();
    setState(() {
      otherUserName =
          '${userDoc.data()?['firstName']} ${userDoc.data()?['lastName']}' ??
          'User';
      token = '${userDoc.data()?['token']}' ?? '';
      otherUserImage = userDoc.data()?['image'] as String? ?? '';
    });

    _firestore.collection('users').doc(otherUserId).snapshots().listen((doc) {
      if (doc.exists) {
        setState(() => isOtherUserOnline = doc['isOnline'] ?? false);
      }
    });
  }

  Future<void> _setOnlineStatus(bool status) async {
    await _firestore.collection('users').doc(_uid).update({'isOnline': status});
  }

  void _onMessageLongPress(MessageModel msg) {
    if (msg.senderId == _uid) {
      setState(() {
        _selectedMessage = msg;
        _showOverlay = true;
        _isEditing = false;
      });
    }
  }

  void _closeOverlay() {
    setState(() {
      _selectedMessage = null;
      _showOverlay = false;
      _isEditing = false;
      _controller.clear();
      _focusNode.unfocus();
    });
  }

  Future<void> _deleteMessage() async {
    if (_selectedMessage == null) return;
    await _firestore
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .doc(_selectedMessage!.id)
        .update({'text': 'This message was deleted', 'isDeleted': true});

    // update last message
    _firestore.collection('chats').doc(widget.chatId).update({
      'lastMessage.text': 'Last message was deleted',
      'lastMessage.isDeleted': true,
    });

    _closeOverlay();
  }

  Future<void> _deleteMessageFinally() async {
    if (_selectedMessage == null) return;
    await _firestore
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .doc(_selectedMessage!.id)
        .delete();
    _closeOverlay();
  }

  void _editMessage() {
    if (_selectedMessage == null) return;
    setState(() {
      _isEditing = true;
      _controller.text = _selectedMessage!.text;
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: _selectedMessage!.text.length),
      );
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  Future<void> _copyMessage() async {
    if (_selectedMessage == null) return;
    Clipboard.setData(ClipboardData(text: _selectedMessage!.text));
    Fluttertoast.showToast(msg: 'Message copied to clipboard');
    _closeOverlay();
  }

  //
  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final chatRef = _firestore.collection('chats').doc(widget.chatId);
    final messagesRef = chatRef.collection('messages');

    if (_isEditing && _selectedMessage != null) {
      await messagesRef.doc(_selectedMessage!.id).update({
        'text': text,
        'isEdited': true,
      });
      _closeOverlay();
    } else {
      //
      final msg = MessageModel(
        id: '',
        senderId: _uid,
        text: text,
        timestamp: DateTime.now(),
        seenBy: [_uid],
      );

      //
      await messagesRef.add(msg.toMap());

      //
      await chatRef.update({
        'lastMessage': msg.toMap(),
        'lastTime': FieldValue.serverTimestamp(),
      });

      // get current user name
      final userDoc = await _firestore.collection('users').doc(_uid).get();
      final userName =
          '${userDoc.data()?['firstName']} ${userDoc.data()?['lastName']}';

      //
      if (!isOtherUserOnline && token != null) {
        //
        FCMSender.sendToToken(
          token: token!,
          title: userName ?? 'New Message',
          body: text,
          data: {'type': 'chats', 'chatId': widget.chatId},
        );
      }
    }
    _controller.clear();
  }

  String formatTime(DateTime time) {
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    final ampm = time.hour >= 12 ? 'pm' : 'am';
    return '$hour:$minute $ampm';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: _showOverlay
            ? (_isEditing
                  ? const Text(
                      "Edit Message",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    )
                  : null)
            : Row(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.redAccent.shade200,
                        child:
                            (otherUserImage != null &&
                                otherUserImage!.isNotEmpty)
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(50),
                                child: CachedNetworkImage(
                                  imageUrl: otherUserImage!,
                                  width: 38,
                                  height: 38,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  errorWidget: (context, url, error) => Center(
                                    child: Text(
                                      otherUserName != null &&
                                              otherUserName!.isNotEmpty
                                          ? otherUserName![0].toUpperCase()
                                          : '',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            : Center(
                                child: Text(
                                  otherUserName != null &&
                                          otherUserName!.isNotEmpty
                                      ? otherUserName![0].toUpperCase()
                                      : '',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                  ),
                                ),
                              ),
                      ),

                      //
                      if (isOtherUserOnline)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    otherUserName ?? '',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
        leading: _showOverlay
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: _closeOverlay,
              )
            : null,
        actions: _showOverlay
            ? [
                // Only show delete button if the message is deleted
                if (_selectedMessage?.isDeleted == true)
                  IconButton(
                    icon: const Icon(Icons.delete_forever),
                    onPressed:
                        _deleteMessageFinally, // This will be the permanent delete function
                  ),
                // Show other buttons if the message is not deleted and not in editing mode
                if (_selectedMessage?.isDeleted != true && !_isEditing) ...[
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: _deleteMessage,
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: _editMessage,
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: _copyMessage,
                  ),
                ],
              ]
            : [],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _firestore
                      .collection('chats')
                      .doc(widget.chatId)
                      .collection('messages')
                      .orderBy('timestamp')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final messages = snapshot.data!.docs
                        .map((doc) => MessageModel.fromMap(doc.id, doc.data()))
                        .toList();

                    // todo: check if seen not work
                    for (var msg in messages) {
                      if (msg.senderId != _uid && !msg.seenBy.contains(_uid)) {
                        _firestore
                            .collection('chats')
                            .doc(widget.chatId)
                            .collection('messages')
                            .doc(msg.id)
                            .update({
                              'seenBy': FieldValue.arrayUnion([_uid]),
                            });

                        //
                        _firestore
                            .collection('chats')
                            .doc(widget.chatId)
                            .update({
                              'lastMessage.seenBy': FieldValue.arrayUnion([
                                _uid,
                              ]),
                            });
                      }
                    }

                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (_scrollController.hasClients) {
                        _scrollController.jumpTo(
                          _scrollController.position.maxScrollExtent,
                        );
                      }
                    });

                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = messages[index];
                        final isMe = msg.senderId == _uid;
                        final seenText = msg.seenBy.contains(otherUserId)
                            ? '✓✓'
                            : '✓';

                        return Align(
                          alignment: isMe
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: GestureDetector(
                            onLongPress: () => _onMessageLongPress(msg),
                            child: Container(
                              margin: const EdgeInsets.symmetric(
                                vertical: 4,
                                horizontal: 8,
                              ),
                              padding: const EdgeInsets.fromLTRB(10, 7, 10, 6),
                              constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.of(context).size.width * 0.8,
                              ),
                              decoration: BoxDecoration(
                                color: isMe
                                    ? Colors.red.shade100.withValues(alpha: .5)
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: isMe
                                    ? CrossAxisAlignment.end
                                    : CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    msg.text,
                                    style: const TextStyle(fontSize: 15),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (msg.isEdited)
                                        const Text(
                                          'Edited',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.black54,
                                          ),
                                        ),

                                      const SizedBox(width: 5),

                                      Text(
                                        formatTime(msg.timestamp),
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Colors.black54,
                                        ),
                                      ),

                                      const SizedBox(width: 8),

                                      //
                                      if (isMe) ...[
                                        Text(
                                          seenText,
                                          style: TextStyle(
                                            fontSize: 10,
                                            letterSpacing: -2,
                                            color:
                                                msg.seenBy.contains(otherUserId)
                                                ? Colors.blue
                                                : Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              if (!_isEditing) _buildInputField(),
            ],
          ),
          if (_isEditing)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.6),
                alignment: Alignment.bottomCenter,
                child: _buildInputField(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInputField() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: EdgeInsets.zero,
          child: Container(
            padding: const EdgeInsets.only(top: 10, left: 12, bottom: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              spacing: 4,
              children: [
                Expanded(
                  child: Scrollbar(
                    // color: Colors.red,
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      autocorrect: false,
                      maxLines: 8,
                      minLines: 1,
                      decoration: InputDecoration(
                        hintText: _isEditing
                            ? "Edit message..."
                            : "Type a message...",
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 0,
                          vertical: 0,
                        ),

                        border: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                      ),
                    ),
                  ),
                ),

                //
                if (_controller.text.trim().isNotEmpty)
                  GestureDetector(
                    onTap: _controller.text.trim().isEmpty
                        ? null
                        : _sendMessage,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 4, right: 8),
                      child: const Icon(Icons.send, color: Colors.red),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
