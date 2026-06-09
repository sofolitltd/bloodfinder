import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

class ChatInput extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isEditing;
  final VoidCallback onSend;

  const ChatInput({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.isEditing,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
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
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      autocorrect: false,
                      maxLines: 8,
                      minLines: 1,
                      decoration: InputDecoration(
                        hintText: isEditing
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
                if (controller.text.trim().isNotEmpty)
                  GestureDetector(
                    onTap: onSend,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 4, right: 8),
                      child: Icon(
                        PhosphorIcons.paperPlaneRight,
                        color: Colors.red,
                      ),
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
