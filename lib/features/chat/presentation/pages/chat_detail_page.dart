import 'package:bloodfinder/features/notification/services/fcm_sender.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../../data/providers/repository_providers.dart';
import '../../models/chat_model.dart';
import '../widgets/chat_input.dart';
import '../widgets/chat_app_bar.dart';
import '../widgets/message_list.dart';

class ChatDetailPage extends ConsumerStatefulWidget {
  final String chatId;

  const ChatDetailPage({super.key, required this.chatId});

  @override
  ConsumerState<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends ConsumerState<ChatDetailPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  late final String _uid = ref.read(authRepositoryProvider).currentUser!.uid;

  String? otherUserId;
  String? otherUserImage;
  String? otherUserName;
  String? token = "";

  MessageModel? _selectedMessage;
  bool _showOverlay = false;
  bool _isEditing = false;
  bool isOtherUserOnline = false;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _fetchOtherUser();
    _setOnlineStatus(true);
    _controller.addListener(() {
      if (!_disposed) setState(() {});
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _setOnlineStatus(false);
    _focusNode.dispose();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchOtherUser() async {
    final communityRepo = ref.read(communityRepositoryProvider);
    final userRepo = ref.read(userRepositoryProvider);

    final chatDoc = await communityRepo.getChat(widget.chatId);
    final participants = List<String>.from(chatDoc['participants']);
    otherUserId = participants.firstWhere((id) => id != _uid);

    final userDoc = await userRepo.getUser(otherUserId!);
    final data = userDoc.data();
    if (!_disposed) {
      setState(() {
        otherUserName = '${data?['firstName'] ?? ''} ${data?['lastName'] ?? ''}'
            .trim();
        if (otherUserName?.isEmpty ?? true) otherUserName = 'User';
        token = data?['token'] as String? ?? '';
        otherUserImage = data?['image'] as String? ?? '';
      });
    }

    userRepo.userStream(otherUserId!).listen((doc) {
      if (doc.exists && !_disposed) {
        setState(() => isOtherUserOnline = doc['isOnline'] ?? false);
      }
    });
  }

  Future<void> _setOnlineStatus(bool status) async {
    await ref.read(userRepositoryProvider).updateOnlineStatus(_uid, status);
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
    final communityRepo = ref.read(communityRepositoryProvider);

    await communityRepo.updateMessage(widget.chatId, _selectedMessage!.id, {
      'text': 'This message was deleted',
      'isDeleted': true,
    });

    communityRepo.updateChat(widget.chatId, {
      'lastMessage.text': 'Last message was deleted',
      'lastMessage.isDeleted': true,
    });

    _closeOverlay();
  }

  Future<void> _deleteMessageFinally() async {
    if (_selectedMessage == null) return;
    final communityRepo = ref.read(communityRepositoryProvider);
    await communityRepo.deleteMessage(widget.chatId, _selectedMessage!.id);
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

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final communityRepo = ref.read(communityRepositoryProvider);
    final userRepo = ref.read(userRepositoryProvider);

    if (_isEditing && _selectedMessage != null) {
      await communityRepo.updateMessage(widget.chatId, _selectedMessage!.id, {
        'text': text,
        'isEdited': true,
      });
      _closeOverlay();
    } else {
      final msg = MessageModel(
        id: '',
        senderId: _uid,
        text: text,
        timestamp: DateTime.now(),
        seenBy: [_uid],
      );

      await communityRepo.addMessage(widget.chatId, msg.toMap());

      await communityRepo.updateChat(widget.chatId, {
        'lastMessage': msg.toMap(),
        'lastTime': FieldValue.serverTimestamp(),
      });

      final userDoc = await userRepo.getUser(_uid);
      final data = userDoc.data();
      final firstName = data?['firstName'] as String? ?? '';
      final lastName = data?['lastName'] as String? ?? '';
      final userName = '$firstName $lastName'.trim();

      if (!isOtherUserOnline && token != null && token!.isNotEmpty) {
        FCMSender.sendToToken(
          token: token!,
          title: userName.isEmpty ? 'New Message' : userName,
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
            : ChatAppBar(
                otherUserName: otherUserName,
                otherUserImage: otherUserImage,
                isOtherUserOnline: isOtherUserOnline,
              ),
        leading: _showOverlay
            ? IconButton(
                icon: Icon(PhosphorIcons.x),
                onPressed: _closeOverlay,
              )
            : null,
        actions: _showOverlay
            ? [
                if (_selectedMessage?.isDeleted == true)
                  IconButton(
                    icon: Icon(PhosphorIcons.trash),
                    onPressed:
                        _deleteMessageFinally,
                  ),
                if (_selectedMessage?.isDeleted != true && !_isEditing) ...[
                  IconButton(
                    icon: Icon(PhosphorIcons.trash),
                    onPressed: _deleteMessage,
                  ),
                  IconButton(
                    icon: Icon(PhosphorIcons.pencil),
                    onPressed: _editMessage,
                  ),
                  IconButton(
                    icon: Icon(PhosphorIcons.copy),
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
                child: MessageList(
                  chatId: widget.chatId,
                  uid: _uid,
                  otherUserId: otherUserId,
                  scrollController: _scrollController,
                  formatTime: formatTime,
                  onMessageLongPress: _onMessageLongPress,
                ),
              ),
              if (!_isEditing)
                ChatInput(
                  controller: _controller,
                  focusNode: _focusNode,
                  isEditing: false,
                  onSend: _sendMessage,
                ),
            ],
          ),
          if (_isEditing)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.6),
                alignment: Alignment.bottomCenter,
                child: ChatInput(
                  controller: _controller,
                  focusNode: _focusNode,
                  isEditing: true,
                  onSend: _sendMessage,
                ),
              ),
            ),
        ],
      ),
    );
  }

}
