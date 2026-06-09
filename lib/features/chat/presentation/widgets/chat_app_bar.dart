import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class ChatAppBar extends StatelessWidget {
  final String? otherUserName;
  final String? otherUserImage;
  final bool isOtherUserOnline;

  const ChatAppBar({
    super.key,
    required this.otherUserName,
    required this.otherUserImage,
    required this.isOtherUserOnline,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Stack(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.redAccent.shade200,
              child:
                  (otherUserImage != null && otherUserImage!.isNotEmpty)
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
    );
  }
}
