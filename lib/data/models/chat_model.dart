import 'package:cloud_firestore/cloud_firestore.dart';

// Message model
class MessageModel {
  final String id;
  final String senderId;
  final String text;
  final DateTime timestamp;
  final List<String> seenBy;
  final bool isDeleted;
  final bool isEdited;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.text,
    required this.timestamp,
    required this.seenBy,
    this.isDeleted = false,
    this.isEdited = false,
  });

  factory MessageModel.fromMap(String id, Map<String, dynamic> map) {
    return MessageModel(
      id: id,
      senderId: map['senderId'] ?? '',
      text: map['text'] ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      seenBy: List<String>.from(map['seenBy'] ?? []),
      isDeleted: map['isDeleted'] ?? false,
      isEdited: map['isEdited'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'text': text,
      'timestamp': Timestamp.fromDate(timestamp),
      'seenBy': seenBy,
      'isDeleted': isDeleted,
      'isEdited': isEdited,
    };
  }
}

// Chat model
class ChatModel {
  final String id;
  final List<String> participants;
  final MessageModel? lastMessage;

  ChatModel({required this.id, required this.participants, this.lastMessage});

  factory ChatModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    final lastMessageMap = data['lastMessage'] as Map<String, dynamic>?;
    return ChatModel(
      id: doc.id,
      participants: List<String>.from(data['participants'] ?? []),
      lastMessage: lastMessageMap != null
          ? MessageModel.fromMap('last', lastMessageMap)
          : null,
    );
  }
}
