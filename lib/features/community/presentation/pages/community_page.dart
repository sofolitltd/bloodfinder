import 'package:cached_network_image/cached_network_image.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';


import '../../models/community.dart';
import '../../../../data/providers/repository_providers.dart';
import '../widgets/blood_group_count_chips.dart';
import '../widgets/pending_invites_section.dart';
import 'create_community_page.dart';

import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

class CommunityPage extends ConsumerStatefulWidget {
  const CommunityPage({super.key});

  @override
  ConsumerState<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends ConsumerState<CommunityPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<Community> _filtered(List<Community> communities) => communities
      .where((c) => c.name.toLowerCase().contains(_searchQuery))
      .toList();

  @override
  Widget build(BuildContext context) {
    final uid = ref.read(authRepositoryProvider).currentUser!.uid;
    final communityRepo = ref.read(communityRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Community',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.red.shade700,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.red.shade700,
          tabs: const [
            Tab(text: 'My Community'),
            Tab(text: 'Nearby'),
            Tab(text: 'Other'),
          ],
        ),
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton.extended(
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
        icon: Icon(PhosphorIcons.plusBold, size: 20),
        label: const Text('Create Community'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateCommunityScreen(),
            ),
          );
        },
      )
          : null,
      body: Column(
        spacing:8,
        children: [
          Container(
            color: Theme.of(context).colorScheme.surface,
            padding: EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name...',
                prefixIcon: Icon(PhosphorIcons.magnifyingGlass, size: 20),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        icon: Icon(PhosphorIcons.x, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      ),
              ),
              onChanged: (value) =>
                  setState(() => _searchQuery = value.trim().toLowerCase()),
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: communityRepo.allCommunitiesStream(),
              builder: (context, allCommunitiesSnap) {
                if (!allCommunitiesSnap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allDocs = allCommunitiesSnap.data!.docs;
                final allCommunities = allDocs
                    .map((e) =>
                        Community.fromJson(e.data() as Map<String, dynamic>))
                    .toList();

                return StreamBuilder<QuerySnapshot>(
                  stream: communityRepo.userMembershipsStream(uid),
                  builder: (context, myMembershipsSnap) {
                    if (!myMembershipsSnap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final myCommunityIds = myMembershipsSnap.data!.docs
                        .map((doc) => doc['communityId'] as String? ?? '')
                        .where((id) => id.isNotEmpty)
                        .toSet();

                    return TabBarView(
                      controller: _tabController,
                      children: [
                        Column(
                          children: [
                            const PendingInvitesSection(),
                            Expanded(
                              child: _CommunityTab(
                                communities: _filtered(allCommunities
                                    .where(
                                        (c) => myCommunityIds.contains(c.id))
                                    .toList()),
                              ),
                            ),
                          ],
                        ),
                        _CommunityTab(
                          communities: _filtered(allCommunities),
                          showNearby: true,
                        ),
                        _CommunityTab(
                          communities: _filtered(allCommunities
                              .where((c) => !myCommunityIds.contains(c.id))
                              .toList()),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CommunityTab extends StatelessWidget {
  final List<Community> communities;
  final bool showNearby;

  const _CommunityTab({
    required this.communities,
    this.showNearby = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _buildVerticalCommunityList(context, communities, isDark);
  }

  Widget _buildVerticalCommunityList(
      BuildContext context, List<Community> communities, bool isDark) {
    if (communities.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                PhosphorIcons.usersFour,
                size: 34,
                color: Colors.red.shade300,
              ),
            ),
            SizedBox(height: 8),
            Text(
              showNearby
                  ? 'No nearby communities'
                  : 'No communities found',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.grey.shade200 : Colors.grey.shade800,
              ),
            ),
            SizedBox(height: 6),
            Text(
              showNearby
                  ? 'Check back later or explore other tabs'
                  : 'Create a new community or join one',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                height: 1.4,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 96),
      itemCount: communities.length,
      itemBuilder: (context, index) {
        final community = communities[index];
        return Padding(
          padding: EdgeInsets.only(top: index == 0 ? 0 : 12),
          child: GestureDetector(
            onTap: () {
              context.pushNamed(
                "communityDetail",
                pathParameters: {'communityId': community.id},
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: community.images.isEmpty
                          ? Text(
                              community.name.isNotEmpty
                                  ? community.name[0].toUpperCase()
                                  : '',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.red.shade600,
                              ),
                            )
                          : CachedNetworkImage(
                              imageUrl: community.images.first,
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                              placeholder: (context, url) =>
                                  const CupertinoActivityIndicator(),
                              errorWidget: (context, url, error) => Icon(
                                PhosphorIcons.warningCircle,
                                color: Colors.red.shade300,
                                size: 22,
                              ),
                            ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            community.name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: isDark ? Colors.grey.shade200 : Colors.grey.shade800,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(PhosphorIcons.mapPin,
                                  size: 14, color: isDark ? Colors.grey.shade500 : Colors.grey.shade400),
                              SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  community.address,
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade700),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 6),
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${community.memberCount} members',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.green.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (community.bloodGroupCounts != null &&
                              community.bloodGroupCounts!.values
                                  .any((c) => c > 0)) ...[
                            SizedBox(height: 8),
                            BloodGroupCountChips(
                              bloodGroupCounts: community.bloodGroupCounts,
                              dense: true,
                            ),
                          ],
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Icon(
                        PhosphorIcons.caretRight,
                        size: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
