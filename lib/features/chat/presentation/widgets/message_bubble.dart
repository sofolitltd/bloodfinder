import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
          margin: EdgeInsets.symmetric(vertical: 4.h, horizontal: 8.w),
          padding: EdgeInsets.fromLTRB(10.w, 7.h, 10.w, 6.h),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.8,
          ),
          decoration: BoxDecoration(
            color: isMe
                ? Colors.red.shade100.withValues(alpha: .5)
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Column(
            crossAxisAlignment:
                isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Text(
                message.text,
                style: TextStyle(fontSize: 15.sp),
              ),
              SizedBox(height: 4.h),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (message.isEdited)
                    Text(
                      'Edited',
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: Colors.black54,
                      ),
                    ),
                  SizedBox(width: 5.w),
                  Text(
                    formatTime(message.timestamp),
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: Colors.black54,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  if (isMe)
                    Text(
                      seenText,
                      style: TextStyle(
                        fontSize: 10.sp,
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
