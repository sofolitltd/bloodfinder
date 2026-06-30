import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';


import '../../models/community.dart';
import '../../../../data/providers/repository_providers.dart';

import '../../../../features/notification/services/fcm_sender.dart';

import '../../../../features/notification/services/notification_service.dart';

class JoinRequestSheet extends ConsumerWidget {
  final Community community;

  const JoinRequestSheet({
    super.key,
    required this.community,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserId = ref.read(authRepositoryProvider).currentUser!.uid;
    final communityRepo = ref.read(communityRepositoryProvider);
    final memberStream = communityRepo.memberStream(community.id, currentUserId);

    return StreamBuilder<DocumentSnapshot>(
      stream: memberStream,
      builder: (context, snapshot) {
        bool isRequested = false;

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          if (data['member'] == false) {
            isRequested = true;
          }
        }

        return Padding(
          padding: EdgeInsets.all(24.w),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40.w,
                    height: 4.h,
                    margin: EdgeInsets.only(bottom: 20.h),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 44.w,
                      height: 44.h,
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                      child: Icon(
                        PhosphorIcons.usersThree,
                        color: Colors.red.shade600,
                        size: 22,
                      ),
                    ),
                    SizedBox(width: 14.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            community.name,
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            community.address,
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: 12.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        PhosphorIcons.hash,
                        size: 14,
                        color: Colors.blue.shade600,
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        'Code: ${community.code}',
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20.h),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(14.w),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Instructions to join:',
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        '1. Press the Join Request button below.\n2. Wait for approval from community admin.',
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: Colors.grey.shade600,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24.h),
                SizedBox(
                  width: double.infinity,
                  height: 50.h,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (!isRequested) {
                        await communityRepo.addMember(
                          community.id,
                          currentUserId,
                          {
                            'uid': currentUserId,
                            'member': false,
                            'createdAt': FieldValue.serverTimestamp(),
                          },
                        );

                        await FCMSender.sendToTopic(
                          topic: community.id,
                          title: 'New Join Request',
                          body:
                              'Someone requested to join ${community.name}',
                          data: {
                            'type': 'community',
                            'communityId': community.id,
                          },
                        );

                        await Future.wait(
                          community.admin.map((adminUid) {
                            return NotificationService.addNotification(
                              title: 'New Join Request',
                              body:
                                  'Someone requested to join your ${community.name}.',
                              type: 'community',
                              data: {'communityId': community.id},
                              userId: adminUid,
                            );
                          }),
                        );

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content:
                                const Text('Join request sent'),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(12.r),
                            ),
                          ),
                        );
                      } else {
                        await communityRepo.removeMember(
                            community.id, currentUserId);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content:
                                const Text('Join request canceled'),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(12.r),
                            ),
                          ),
                        );
                      }
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isRequested
                          ? Colors.grey.shade400
                          : Colors.red.shade600,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    child: Text(
                      isRequested
                          ? 'Cancel Join Request'
                          : 'Send Join Request',
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
