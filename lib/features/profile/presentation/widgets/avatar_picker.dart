import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
    final bool hasImage =
        selectedImage != null || (profileImageUrl != null && profileImageUrl!.isNotEmpty);

    return GestureDetector(
      onTap: onPickImage,
      child: Stack(
        children: [
          Container(
            height: 90.h,
            width: 90.w,
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(20.r),
              image: hasImage
                  ? DecorationImage(
                      image: selectedImage != null
                          ? FileImage(selectedImage!)
                          : NetworkImage(profileImageUrl!) as ImageProvider,
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: hasImage
                ? null
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        PhosphorIcons.camera,
                        size: 28.w,
                        color: Colors.red.shade400,
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'Add Photo',
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: Colors.red.shade400,
                        ),
                      ),
                    ],
                  ),
          ),
          if (hasImage)
            Positioned(
              bottom: 0,
              right: -2,
              child: Container(
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  color: Colors.red.shade500,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2.w),
                ),
                child: Icon(
                  Icons.edit,
                  size: 14.w,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
