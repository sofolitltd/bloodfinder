import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

class UserInfoSection extends StatelessWidget {
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController mobileController;
  final XFile? pickedImage;
  final VoidCallback onPickImage;

  const UserInfoSection({
    super.key,
    required this.firstNameController,
    required this.lastNameController,
    required this.mobileController,
    required this.pickedImage,
    required this.onPickImage,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8.h,
      children: [
          // Avatar
          GestureDetector(
            onTap: onPickImage,
            child: Stack(
              children: [
                Container(
                  height: 90.h,
                  width: 90.w,
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(20.r),
                    image: pickedImage != null
                        ? DecorationImage(
                            image: FileImage(File(pickedImage!.path)),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: pickedImage == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(PhosphorIcons.camera, size: 28.w, color: Colors.red.shade400),
                            SizedBox(height: 2.h),
                            Text(
                              'Add Photo',
                              style: TextStyle(fontSize: 10.sp, color: Colors.red.shade400),
                            ),
                          ],
                        )
                      : null,
                ),
                if (pickedImage != null)
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
                      child: Icon(Icons.edit, size: 14.w, color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: 2.h),

          // First name
          TextFormField(
            controller: firstNameController,
            decoration: InputDecoration(
              labelText: 'First Name',
              prefixIcon: Icon(PhosphorIcons.user, size: 20.w),
            ),
            validator: (v) => v == null || v.isEmpty ? 'Required' : null,
          ),
          SizedBox(height: 8.h),

          // Last name
          TextFormField(
            controller: lastNameController,
            decoration: InputDecoration(
              labelText: 'Last Name',
              prefixIcon: Icon(PhosphorIcons.user, size: 20.w),
            ),
            validator: (v) => v == null || v.isEmpty ? 'Required' : null,
          ),
          SizedBox(height: 8.h),

          // Mobile
          TextFormField(
            controller: mobileController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'Mobile Number',
              prefixIcon: Icon(PhosphorIcons.phone, size: 20.w),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Required';
              return null;
            },
          ),
          ],
    );
  }
}
