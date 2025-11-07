import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/community.dart';
import 'create_community.dart';

final _currentUserId = FirebaseAuth.instance.currentUser!.uid;

class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Community'), centerTitle: true),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateCommunityScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: Text("Create Community"),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 🔍 Search bar
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by name...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                searchQuery = '';
                              });
                            },
                          ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value.trim().toLowerCase();
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),

            // 🔥 Combine communities + my memberships
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('communities')
                  .orderBy('name', descending: true)
                  .snapshots(),
              builder: (context, allCommunitiesSnap) {
                if (!allCommunitiesSnap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allDocs = allCommunitiesSnap.data!.docs;
                final allCommunities = allDocs
                    .map(
                      (e) =>
                          Community.fromJson(e.data() as Map<String, dynamic>),
                    )
                    .toList();

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collectionGroup('members')
                      .where('uid', isEqualTo: _currentUserId)
                      .where('member', isEqualTo: true)
                      .snapshots(),
                  builder: (context, myMembershipsSnap) {
                    if (!myMembershipsSnap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    // Get my community IDs
                    final myCommunityIds = myMembershipsSnap.data!.docs
                        .map((doc) => doc.reference.parent.parent!.id)
                        .toSet();

                    final myCommunities = allCommunities
                        .where((c) => myCommunityIds.contains(c.id))
                        .where(
                          (c) => c.name.toLowerCase().contains(searchQuery),
                        )
                        .toList();

                    final otherCommunities = allCommunities
                        .where((c) => !myCommunityIds.contains(c.id))
                        .where(
                          (c) => c.name.toLowerCase().contains(searchQuery),
                        )
                        .toList();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (myCommunities.isNotEmpty)
                          Card(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                                  child: Text(
                                    'My Communities',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),

                                //
                                _buildHorizontalCommunityList(
                                  context,
                                  myCommunities,
                                ),
                              ],
                            ),
                          ),

                        //
                        Card(
                          margin: const EdgeInsets.only(top: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Text(
                                  'Other Communities',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),

                              //
                              _buildVerticalCommunityList(
                                context,
                                otherCommunities,
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// 🔽 Helper widgets
Widget _buildHorizontalCommunityList(
  BuildContext context,
  List<Community> communities,
) {
  return SizedBox(
    height: 170,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16),
      itemCount: communities.length,
      separatorBuilder: (context, index) => const SizedBox(width: 16),
      itemBuilder: (context, index) {
        final community = communities[index];
        return GestureDetector(
          onTap: () {
            context.pushNamed(
              "communityDetail",
              pathParameters: {'communityId': community.id},
            );
          },

          child: Container(
            width: 250,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.transparent
                  : Colors.white,
              border: Border.all(
                color:
                    Theme.of(context).colorScheme.brightness == Brightness.light
                    ? Colors.black12
                    : Colors.white30,
                width: .5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.transparent.withValues(alpha: .05),
                  spreadRadius: 2,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Container(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  //
                  Row(
                    spacing: 10,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      //
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey, width: .5),
                          color: Colors.white,
                        ),
                        alignment: Alignment.center,
                        child: community.images.isEmpty
                            ? Text(
                                community.name.isNotEmpty
                                    ? community.name[0].toUpperCase()
                                    : '',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red.shade100,
                                ),
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: CachedNetworkImage(
                                  imageUrl: community.images.first,
                                  width: 64,
                                  height: 64,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) =>
                                      CupertinoActivityIndicator(),
                                  errorWidget: (context, url, error) =>
                                      Icon(Icons.error, color: Colors.red),
                                ),
                              ),
                      ),

                      //
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Code", style: TextStyle(fontSize: 12)),
                          Text(
                            "${community.code} ",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              height: .8,
                              fontSize: 15,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text("Members", style: TextStyle(fontSize: 12)),
                          Text(
                            "${community.memberCount}",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              height: .8,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  //
                  const SizedBox(height: 8),

                  Text(
                    community.name,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${community.address}, ${community.subDistrict}, ${community.district}',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: const TextStyle(
                      color: Colors.grey,
                      height: 1.1,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}

Widget _buildVerticalCommunityList(
  BuildContext context,
  List<Community> communities,
) {
  if (communities.isEmpty) {
    return Container(
      height: 100,
      padding: const EdgeInsets.all(16),
      child: const Center(
        child: Text(
          'No other communities to join at the moment.',
          style: TextStyle(color: Colors.grey),
        ),
      ),
    );
  }

  return ListView.separated(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
    itemCount: communities.length,
    separatorBuilder: (context, index) => const SizedBox(height: 16),
    itemBuilder: (context, index) {
      final community = communities[index];
      return GestureDetector(
        onTap: () {
          context.pushNamed(
            "communityDetail",
            pathParameters: {'communityId': community.id},
          );
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.transparent
                : Colors.white,
            border: Border.all(
              color:
                  Theme.of(context).colorScheme.brightness == Brightness.light
                  ? Colors.black12
                  : Colors.white30,
              width: .5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.transparent.withValues(alpha: .05),
                spreadRadius: 2,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                //
                Container(
                  width: 64,
                  height: 64,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey, width: .5),
                  ),
                  child: community.images.isEmpty
                      ? Text(
                          community.name.isNotEmpty
                              ? community.name[0].toUpperCase()
                              : '',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade200,
                          ),
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: community.images.first,
                            width: 64,
                            height: 64,
                            fit: BoxFit.cover,
                            placeholder: (context, url) =>
                                CupertinoActivityIndicator(),
                            errorWidget: (context, url, error) =>
                                Icon(Icons.error, color: Colors.red),
                          ),
                        ),
                ),

                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        community.name,
                        style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          height: 1.2,
                        ),
                      ),
                      Text(
                        '${community.subDistrict}, ${community.district}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        spacing: 12,
                        children: [
                          Text(
                            'Code: ${community.code}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            '|',
                            style: const TextStyle(fontSize: 10, height: 1),
                          ),
                          Text(
                            'Members: ${community.memberCount}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
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
    },
  );
}
