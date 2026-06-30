import 'package:cached_network_image/cached_network_image.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';


import '../../models/community.dart';
import '../../../../data/providers/repository_providers.dart';

import '../widgets/admin_management_section.dart';
import '../widgets/community_info_section.dart';
import '../widgets/join_request_sheet.dart';
import '../widgets/member_content_section.dart';

import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

class CommunityDetailsPage extends ConsumerWidget {
  final String communityId;

  const CommunityDetailsPage({super.key, required this.communityId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.read(authRepositoryProvider).currentUser!.uid;
    final communityRepo = ref.read(communityRepositoryProvider);

    return Scaffold(
      body: StreamBuilder<DocumentSnapshot>(
        stream: communityRepo.communityStream(communityId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Community not found"));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final community = Community.fromJson({...data, 'id': communityId});

          return CustomScrollView(
            slivers: [
              // Gradient hero header
              SliverToBoxAdapter(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.red.shade800,
                        Colors.red.shade600,
                        Colors.red.shade400,
                      ],
                    ),
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.elliptical(300, 40),
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(4.w, 4.h, 16.w, 28.h),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(
                                  PhosphorIcons.arrowLeft,
                                  color: Colors.white,
                                ),
                                onPressed: () => Navigator.pop(context),
                              ),
                              const Spacer(),
                              if (community.admin.contains(uid))
                                IconButton(
                                  icon: Icon(
                                    PhosphorIcons.trash,
                                    color: Colors.white.withValues(alpha: 0.8),
                                  ),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          title: const Text("Delete Community"),
                                          content: const Text(
                                            "Are you sure you want to delete this community? This action cannot be undone.",
                                          ),
                                          actions: <Widget>[
                                            TextButton(
                                              child: const Text("Cancel"),
                                              onPressed: () =>
                                                  Navigator.of(context).pop(),
                                            ),
                                            TextButton(
                                              child: Text(
                                                "Delete",
                                                style: TextStyle(
                                                    color: Colors.red),
                                              ),
                                              onPressed: () async {
                                                await communityRepo
                                                    .deleteCommunity(
                                                        communityId);
                                                Navigator.of(context).popUntil(
                                                  (route) => route.isFirst,
                                                );
                                              },
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                ),
                            ],
                          ),
                          SizedBox(height: 4.h),
                          Padding(
                            padding:
                                EdgeInsets.symmetric(horizontal: 16.w),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 56.w,
                                      height: 56.h,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius:
                                            BorderRadius.circular(16.r),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black
                                                .withValues(alpha: 0.2),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      child: community.images.isEmpty
                                          ? Center(
                                              child: Text(
                                                community.name.isNotEmpty
                                                    ? community.name[0]
                                                        .toUpperCase()
                                                    : '',
                                                style: TextStyle(
                                                  fontSize: 22.sp,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.red.shade600,
                                                ),
                                              ),
                                            )
                                          : CachedNetworkImage(
                                              imageUrl:
                                                  community.images.first,
                                              width: 56.w,
                                              height: 56.h,
                                              fit: BoxFit.cover,
                                            ),
                                    ),
                                    SizedBox(width: 14.w),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            community.name,
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 20.sp,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(height: 4.h),
                                          Text(
                                            community.address,
                                            style: TextStyle(
                                              color: Colors.white
                                                  .withValues(alpha: 0.8),
                                              fontSize: 14.sp,
                                            ),
                                          ),
                                          if (community.locationAddress != null &&
                                              community.locationAddress!.isNotEmpty)
                                            Padding(
                                              padding: EdgeInsets.only(top: 2.h),
                                              child: Text(
                                                community.locationAddress!,
                                                style: TextStyle(
                                                  color: Colors.white.withValues(alpha: 0.65),
                                                  fontSize: 12.sp,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Content
              SliverPadding(
                padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 32.h),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    CommunityInfoSection(community: community, uid: uid),

                    SizedBox(height: 16.h),

                    StreamBuilder<DocumentSnapshot>(
                      stream: communityRepo.memberStream(
                          community.id, uid),
                      builder: (context, memberStatusSnapshot) {
                        bool isApprovedMember = false;

                        if (memberStatusSnapshot.hasData &&
                            memberStatusSnapshot.data!.exists) {
                          final memberData =
                              memberStatusSnapshot.data!.data()
                                  as Map<String, dynamic>?;
                          if (memberData != null &&
                              memberData['member'] == true) {
                            isApprovedMember = true;
                          }
                        }

                        if (isApprovedMember) {
                          return MemberContentSection(
                              community: community, uid: uid);
                        } else {
                          return Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16.r),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            padding: EdgeInsets.all(16.w),
                            child: SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(20)),
                                    ),
                                    builder: (context) =>
                                        JoinRequestSheet(
                                            community: community),
                                  );
                                },
                                icon: Icon(PhosphorIcons.usersThree),
                                label: const Text(
                                    'View Join Instructions'),
                              ),
                            ),
                          );
                        }
                      },
                    ),

                    if (community.admin.contains(uid))
                      Padding(
                        padding: EdgeInsets.only(top: 16.h),
                        child: AdminManagementSection(
                            community: community, uid: uid),
                      ),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
