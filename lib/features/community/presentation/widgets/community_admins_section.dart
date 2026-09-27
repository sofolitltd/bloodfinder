import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../../data/models/user_model.dart';
import '../../../../data/providers/repository_providers.dart';
import '../../models/community.dart';

/// Read-only list of a community's admins and moderators, so members can
/// see who to reach out to.
class CommunityAdminsSection extends ConsumerWidget {
  final Community community;

  const CommunityAdminsSection({super.key, required this.community});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userRepo = ref.read(userRepositoryProvider);

    final entries = <MapEntry<String, bool>>[
      ...community.admin.map((uid) => MapEntry(uid, true)),
      ...community.moderators
          .where((uid) => !community.admin.contains(uid))
          .map((uid) => MapEntry(uid, false)),
    ];

    if (entries.isEmpty) {
      return Center(
        child: Text(
          'No admins found',
          style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade500),
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.all(16.w),
      separatorBuilder: (_, _) => SizedBox(height: 8.h),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final uid = entries[index].key;
        final isAdmin = entries[index].value;

        return StreamBuilder<DocumentSnapshot>(
          stream: userRepo.userStream(uid),
          builder: (context, snapshot) {
            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const SizedBox.shrink();
            }

            final userData = snapshot.data!.data() as Map<String, dynamic>;
            final UserModel user;
            try {
              user = UserModel.fromJson(userData);
            } catch (_) {
              return const SizedBox.shrink();
            }

            final name = '${user.firstName} ${user.lastName}';
            final address = user.locationAddress ?? '';

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
              padding: EdgeInsets.all(12.w),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44.w,
                    height: 44.h,
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: user.image.isEmpty
                        ? Center(
                            child: Text(
                              user.firstName.isNotEmpty
                                  ? user.firstName[0].toUpperCase()
                                  : '',
                              style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.red.shade600,
                              ),
                            ),
                          )
                        : CachedNetworkImage(
                            imageUrl: user.image,
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
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                name,
                                style: TextStyle(
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(width: 6.w),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 6.w,
                                vertical: 2.h,
                              ),
                              decoration: BoxDecoration(
                                color: isAdmin
                                    ? Colors.red.shade50
                                    : Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(4.r),
                              ),
                              child: Text(
                                isAdmin ? 'Admin' : 'Moderator',
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  color: isAdmin
                                      ? Colors.red.shade600
                                      : Colors.blue.shade600,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (address.isNotEmpty) ...[
                          SizedBox(height: 4.h),
                          Text(
                            address,
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
