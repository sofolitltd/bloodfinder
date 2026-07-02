import 'package:cached_network_image/cached_network_image.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/providers/repository_providers.dart';

import '../../../../../shared/widgets/start_chat_btn.dart';

import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

class BloodGroupMembersScreen extends ConsumerWidget {
  final String communityId;
  final String bloodGroup;

  const BloodGroupMembersScreen({
    super.key,
    required this.communityId,
    required this.bloodGroup,
  });

  Stream<List<Map<String, dynamic>>> _communityBloodGroupMembers(
    WidgetRef ref,
  ) {
    final communityRepo = ref.read(communityRepositoryProvider);
    final userRepo = ref.read(userRepositoryProvider);

    return communityRepo
        .membersCollection()
        .where('communityId', isEqualTo: communityId)
        .snapshots()
        .asyncMap((snapshot) async {
          final userIds = snapshot.docs
              .map((doc) => doc['uid'] as String)
              .toList();

          if (userIds.isEmpty) return [];

          final List<Map<String, dynamic>> allMembers = [];

          for (var i = 0; i < userIds.length; i += 10) {
            final chunk = userIds.sublist(
              i,
              i + 10 > userIds.length ? userIds.length : i + 10,
            );

            final usersSnap = await userRepo.getUsersByIds(chunk);

            final members = usersSnap.docs
                .map((doc) {
                  final data = doc.data();
                  data['uid'] = doc.id;
                  return data;
                })
                .where((data) => data['bloodGroup'] == bloodGroup)
                .toList();

            allMembers.addAll(members);
          }

          return allMembers;
        });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$bloodGroup Blood Group Members'),
        centerTitle: true,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _communityBloodGroupMembers(ref),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final members = snapshot.data!;
          if (members.isEmpty) {
            return const Center(
              child: Text('No members found for this blood group.'),
            );
          }

          return ListView.separated(
            padding: EdgeInsets.all(16.w),
            itemCount: members.length,
            separatorBuilder: (_, _) => SizedBox(height: 8.h),
            itemBuilder: (context, index) {
              final member = members[index];
              final otherUserId = member['uid'] as String;

              final name =
                  '${member['firstName'] ?? ''} ${member['lastName'] ?? ''}'
                      .trim();
              final image = member['image'] as String? ?? '';
              final firstName = member['firstName'] as String? ?? '';
              final address = member['locationAddress'] as String? ?? '';

              return Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.all(14.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top row: Avatar + Name/Address + Blood group badge
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Avatar
                          Container(
                            width: 44.w,
                            height: 44.h,
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: image.isEmpty
                                ? Center(
                                    child: Text(
                                      firstName.isNotEmpty
                                          ? firstName[0].toUpperCase()
                                          : '',
                                      style: TextStyle(
                                        fontSize: 18.sp,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red.shade600,
                                      ),
                                    ),
                                  )
                                : CachedNetworkImage(
                                    imageUrl: image,
                                    width: 44.w,
                                    height: 44.h,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) =>
                                        const CupertinoActivityIndicator(),
                                    errorWidget: (context, url, error) => Icon(
                                      PhosphorIcons.warningCircle,
                                      color: Colors.red.shade300,
                                      size: 22.w,
                                    ),
                                  ),
                          ),
                          SizedBox(width: 12.w),
                          // Name + address
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name.isNotEmpty ? name : 'Unknown',
                                  style: TextStyle(
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (address.isNotEmpty) ...[
                                  SizedBox(height: 4.h),
                                  Column(
                                    crossAxisAlignment: .start,
                                    children: [
                                      Text(
                                        address,
                                        style: TextStyle(
                                          fontSize: 13.sp,
                                          color: Colors.grey.shade600,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),

                                      //
                                      SizedBox(height: 10.h),
                                      // Chat button
                                      SizedBox(
                                        height: 36,
                                        width: 150,
                                        child: StartChatButton(
                                          otherUserId: otherUserId,
                                          buttonText: 'Chat',
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          SizedBox(width: 8.w),
                          // Blood group badge
                          Container(
                            padding: EdgeInsets.symmetric(
                              vertical: 4.h,
                              horizontal: 10.w,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Text(
                              bloodGroup,
                              style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.red.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
