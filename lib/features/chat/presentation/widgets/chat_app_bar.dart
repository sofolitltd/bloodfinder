import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
              radius: 16.r,
              backgroundColor: Colors.redAccent.shade200,
              child:
                  (otherUserImage != null && otherUserImage!.isNotEmpty)
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(50.r),
                          child: CachedNetworkImage(
                            imageUrl: otherUserImage!,
                            width: 38.w,
                            height: 38.h,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => SizedBox(
                              width: 20.w,
                              height: 20.h,
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
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20.sp,
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
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 20.sp,
                            ),
                          ),
                        ),
            ),
            if (isOtherUserOnline)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 12.w,
                  height: 12.h,
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
        SizedBox(width: 8.w),
        Text(
          otherUserName ?? '',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
