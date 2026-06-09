import 'dart:io';

import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

class AvatarPicker extends StatelessWidget {
  const AvatarPicker({
    super.key,
    required this.selectedImage,
    required this.profileImageUrl,
    required this.onPickImage,
  });

  final File? selectedImage;
  final String? profileImageUrl;
  final VoidCallback onPickImage;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPickImage,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircleAvatar(
            radius: 60,
            backgroundImage: selectedImage != null
                ? FileImage(selectedImage!)
                : (profileImageUrl != null
                          ? NetworkImage(profileImageUrl!)
                          : null)
                      as ImageProvider?,
            child:
                selectedImage == null && profileImageUrl == null
                ? Icon(
                    PhosphorIcons.user,
                    size: 60,
                    color: Colors.grey[400],
                  )
                : null,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: CircleAvatar(
              radius: 20,
              backgroundColor: Theme.of(context).primaryColor,
              child: const Icon(
                Icons.camera_alt,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
