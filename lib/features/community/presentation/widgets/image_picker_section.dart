import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

class ImagePickerSection extends StatelessWidget {
  final Uint8List? pickedImage;
  final VoidCallback onPickImage;
  final VoidCallback onClearImage;

  const ImagePickerSection({
    super.key,
    required this.pickedImage,
    required this.onPickImage,
    required this.onClearImage,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPickImage,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            height: 140,
            width: 140,
            color: Colors.red.shade50.withValues(alpha: 0.4),
            child: pickedImage != null
                ? Image.memory(pickedImage!)
                : Icon(
                    Icons.image,
                    size: 50,
                    color: Colors.red.shade100,
                  ),
          ),
          if (pickedImage != null)
            Positioned(
              top: -8,
              right: -8,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: onClearImage,
                child: CircleAvatar(
                  radius: 12,
                  child: Icon(PhosphorIcons.x, size: 14),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
