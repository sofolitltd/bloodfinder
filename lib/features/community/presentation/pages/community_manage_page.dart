import 'package:flutter/material.dart';

import '../../models/community.dart';
import '../widgets/community_members_list.dart';
import 'community_audit_log_page.dart';
import 'community_member_request_page.dart';
import 'invite_member_page.dart';

/// Admin-only management hub for a community: members, pending join
/// requests, inviting new members, and the activity log — each as its own
/// tab, reached via the "Manage" button on the community details page.
class CommunityManagePage extends StatefulWidget {
  final Community community;
  final String uid;

  const CommunityManagePage({
    super.key,
    required this.community,
    required this.uid,
  });

  @override
  State<CommunityManagePage> createState() => _CommunityManagePageState();
}

class _CommunityManagePageState extends State<CommunityManagePage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(
    length: 4,
    vsync: this,
  );

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Community'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: Colors.red.shade700,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.red.shade700,
          tabs: const [
            Tab(text: 'Members'),
            Tab(text: 'Join Requests'),
            Tab(text: 'Invite Member'),
            Tab(text: 'Activity Log'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          CommunityMembersList(
            community: widget.community,
            currentUserId: widget.uid,
          ),
          CommunityMemberRequestsBody(community: widget.community),
          InviteMemberBody(community: widget.community),
          CommunityAuditLogBody(community: widget.community),
        ],
      ),
    );
  }
}
