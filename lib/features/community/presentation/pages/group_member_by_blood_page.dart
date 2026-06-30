import 'package:bloodfinder/shared/widgets/start_chat_btn.dart';

import 'package:cached_network_image/cached_network_image.dart';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';


import '../../../../data/providers/repository_providers.dart';

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
      WidgetRef ref) {
    final communityRepo = ref.read(communityRepositoryProvider);
    final userRepo = ref.read(userRepositoryProvider);

    return communityRepo
        .membersCollection()
        .where('communityId', isEqualTo: communityId)
        .snapshots()
        .asyncMap((snapshot) async {
      final userIds =
          snapshot.docs.map((doc) => doc['uid'] as String).toList();

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
            separatorBuilder: (_, __) => SizedBox(height: 8.h),
            itemBuilder: (context, index) {
              final member = members[index];
              String otherUserId = member['uid'];

              final name =
                  '${member['firstName'] ?? ''} ${member['lastName'] ?? ''}'
                      .trim();
              final address =
                  '${member['locationAddress'] ?? ''}, ${member['district'] ?? ''} ${member['subdistrict'] ?? ''}';

              return Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        radius: 21,
                        backgroundColor: Colors.redAccent.shade200,
                        child: member['image'].isEmpty
                            ? Text(
                                member['firstName'].isNotEmpty
                                    ? member['firstName'][0].toUpperCase()
                                    : '',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20.sp,
                                ),
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(50.r),
                                child: CachedNetworkImage(
                                  imageUrl: member['image'],
                                  width: 40.w,
                                  height: 40.h,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) =>
                                      CircularProgressIndicator(strokeWidth: 2),
                                  errorWidget: (context, url, error) => Icon(
                                    PhosphorIcons.warningCircle,
                                    color: Colors.red,
                                  ),
                                ),
                              ),
                      ),
                      title: Text(name.isNotEmpty ? name : 'Unknown'),
                      isThreeLine: true,
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Address: $address'),
                          SizedBox(height: 8.h),

                          StartChatButton(otherUserId: otherUserId),
                          SizedBox(height: 4.h),
                        ],
                      ),
                    ),
                  ),

                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 8.w),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Text(
                        bloodGroup,
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
