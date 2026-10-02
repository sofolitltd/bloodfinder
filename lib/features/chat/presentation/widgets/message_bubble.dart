import 'package:flutter/material.dart';
import '../../models/chat_model.dart';

class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final String? otherUserId;
  final String Function(DateTime) formatTime;
  final VoidCallback onLongPress;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.otherUserId,
    required this.formatTime,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final seenText = message.seenBy.contains(otherUserId) ? '✓✓' : '✓';

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: onLongPress,
        child: Container(
          margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          padding: EdgeInsets.fromLTRB(10, 7, 10, 6),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.8,
          ),
          decoration: BoxDecoration(
            color: isMe
                ? Colors.red.shade100.withValues(alpha: .5)
                : Theme.of(context).cardTheme.color ??
                    Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment:
                isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Text(
                message.text,
                style: TextStyle(fontSize: 15),
              ),
              SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (message.isEdited)
                    Text(
                      'Edited',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.black54,
                      ),
                    ),
                  SizedBox(width: 5),
                  Text(
                    formatTime(message.timestamp),
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.black54,
                    ),
                  ),
                  SizedBox(width: 8),
                  if (isMe)
                    Text(
                      seenText,
                      style: TextStyle(
                        fontSize: 10,
                        letterSpacing: -2,
                        color: message.seenBy.contains(otherUserId)
                            ? Colors.blue
                            : Colors.grey,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
