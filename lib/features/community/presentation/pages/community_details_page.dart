import 'package:cached_network_image/cached_network_image.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/community.dart';
import '../../../../data/providers/repository_providers.dart';
import '../../../../data/repositories/community_repository.dart';

import '../widgets/announcements_section.dart';
import '../widgets/blood_tab_section.dart';
import '../widgets/community_admins_section.dart';
import '../widgets/community_info_section.dart';
import '../widgets/community_members_list.dart';
import '../widgets/non_member_join_card.dart';
import 'community_manage_page.dart';

import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

class CommunityDetailsPage extends ConsumerStatefulWidget {
  final String communityId;

  const CommunityDetailsPage({super.key, required this.communityId});

  @override
  ConsumerState<CommunityDetailsPage> createState() =>
      _CommunityDetailsPageState();
}

class _CommunityDetailsPageState extends ConsumerState<CommunityDetailsPage>
    with TickerProviderStateMixin {
  TabController? _tabController;

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = ref.read(authRepositoryProvider).currentUser!.uid;
    final communityRepo = ref.read(communityRepositoryProvider);

    return Scaffold(
      body: StreamBuilder<DocumentSnapshot>(
        stream: communityRepo.communityStream(widget.communityId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Community not found"));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final community = Community.fromJson({
            ...data,
            'id': widget.communityId,
          });
          if (_tabController == null || _tabController!.length != 5) {
            _tabController?.dispose();
            _tabController = TabController(length: 5, vsync: this);
          }

          return Column(
            children: [
              _CommunityHero(
                community: community,
                uid: uid,
                communityRepo: communityRepo,
              ),
              Container(
                color: Theme.of(context).colorScheme.surface,
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  labelColor: Colors.red.shade700,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Colors.red.shade700,
                  tabs: const [
                    Tab(text: 'About'),
                    Tab(text: 'Blood'),
                    Tab(text: 'Members'),
                    Tab(text: 'Admins'),
                    Tab(text: 'Announcements'),
                  ],
                ),
              ),
              Expanded(
                child: StreamBuilder<DocumentSnapshot>(
                  stream: communityRepo.memberStream(community.id, uid),
                  builder: (context, memberStatusSnapshot) {
                    bool isApprovedMember = false;

                    if (memberStatusSnapshot.hasData &&
                        memberStatusSnapshot.data!.exists) {
                      final memberData =
                          memberStatusSnapshot.data!.data()
                              as Map<String, dynamic>?;
                      if (memberData != null && memberData['member'] == true) {
                        isApprovedMember = true;
                      }
                    }

                    return TabBarView(
                      controller: _tabController,
                      children: [
                        SingleChildScrollView(
                          padding: EdgeInsets.all(16),
                          child: CommunityInfoSection(
                            community: community,
                            uid: uid,
                          ),
                        ),
                        BloodTabSection(community: community),
                        isApprovedMember
                            ? CommunityMembersList(
                                community: community,
                                currentUserId: uid,
                              )
                            : NonMemberJoinCard(community: community),
                        CommunityAdminsSection(community: community),
                        SingleChildScrollView(
                          padding: EdgeInsets.all(16),
                          child: AnnouncementsSection(
                            community: community,
                            uid: uid,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Fixed (non-scrolling) gradient hero header shown above the tabs.
class _CommunityHero extends StatelessWidget {
  final Community community;
  final String uid;
  final CommunityRepository communityRepo;

  const _CommunityHero({
    required this.community,
    required this.uid,
    required this.communityRepo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
          padding: EdgeInsets.fromLTRB(4, 4, 16, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: Icon(PhosphorIcons.arrowLeft, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  if (community.canManageCommunity(uid))
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
                                  onPressed: () => Navigator.of(context).pop(),
                                ),
                                TextButton(
                                  child: Text(
                                    "Delete",
                                    style: TextStyle(color: Colors.red),
                                  ),
                                  onPressed: () async {
                                    await communityRepo.deleteCommunity(
                                      community.id,
                                    );
                                    Navigator.of(
                                      context,
                                    ).popUntil((route) => route.isFirst);
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
              SizedBox(height: 4),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: community.images.isEmpty
                              ? null
                              : () => _showFullImage(
                                  context,
                                  community.images.first,
                                ),
                          child: Container(
                            width: 76,
                            height: 76,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
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
                                          ? community.name[0].toUpperCase()
                                          : '',
                                      style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red.shade600,
                                      ),
                                    ),
                                  )
                                : CachedNetworkImage(
                                    imageUrl: community.images.first,
                                    width: 76,
                                    height: 76,
                                    fit: BoxFit.cover,
                                  ),
                          ),
                        ),
                        SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                community.name,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              if (community.canManageMembers(uid))
                                Padding(
                                  padding: EdgeInsets.only(top: 4),
                                  child: OutlinedButton.icon(
                                    onPressed: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => CommunityManagePage(
                                          community: community,
                                          uid: uid,
                                        ),
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      side: BorderSide(
                                        color: Colors.white.withValues(
                                          alpha: 0.6,
                                        ),
                                      ),
                                      visualDensity: VisualDensity.compact,
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                    ),
                                    icon: Icon(
                                      PhosphorIcons.shieldChevron,
                                      size: 16,
                                    ),
                                    label: const Text('Manage'),
                                  ),
                                )
                              else ...[
                                Text(
                                  community.address,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontSize: 14,
                                  ),
                                ),
                                if (community.locationAddress != null &&
                                    community.locationAddress!.isNotEmpty)
                                  Padding(
                                    padding: EdgeInsets.only(top: 2),
                                    child: Text(
                                      community.locationAddress!,
                                      style: TextStyle(
                                        color: Colors.white.withValues(
                                          alpha: 0.65,
                                        ),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                              ],
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
    );
  }

  void _showFullImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: InteractiveViewer(
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            IconButton(
              icon: Icon(PhosphorIcons.x, color: Colors.white),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
