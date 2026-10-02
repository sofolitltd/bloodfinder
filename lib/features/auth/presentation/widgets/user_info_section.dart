import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

class UserInfoSection extends StatelessWidget {
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController mobileController;
  final Uint8List? pickedImage;
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
      spacing: 8,
      children: [
          // Avatar
          GestureDetector(
            onTap: onPickImage,
            child: Stack(
              children: [
                Container(
                  height: 90,
                  width: 90,
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(20),
                    image: pickedImage != null
                        ? DecorationImage(
                            image: MemoryImage(pickedImage!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: pickedImage == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(PhosphorIcons.camera, size: 28, color: Colors.red.shade400),
                            SizedBox(height: 2),
                            Text(
                              'Add Photo',
                              style: TextStyle(fontSize: 10, color: Colors.red.shade400),
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
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red.shade500,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Icon(Icons.edit, size: 14, color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: 2),

          // First name
          TextFormField(
            controller: firstNameController,
            decoration: InputDecoration(
              labelText: 'First Name',
              prefixIcon: Icon(PhosphorIcons.user, size: 20),
            ),
            validator: (v) => v == null || v.isEmpty ? 'Required' : null,
          ),
          SizedBox(height: 8),

          // Last name
          TextFormField(
            controller: lastNameController,
            decoration: InputDecoration(
              labelText: 'Last Name',
              prefixIcon: Icon(PhosphorIcons.user, size: 20),
            ),
            validator: (v) => v == null || v.isEmpty ? 'Required' : null,
          ),
          SizedBox(height: 8),

          // Mobile
          TextFormField(
            controller: mobileController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'Mobile Number',
              prefixIcon: Icon(PhosphorIcons.phone, size: 20),
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
