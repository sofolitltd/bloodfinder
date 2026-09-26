import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../../data/models/user_model.dart';
import '../../../../data/providers/repository_providers.dart';
import '../../../../data/repositories/community_repository.dart';
import '../../../notification/services/fcm_sender.dart';
import '../../../notification/services/notification_service.dart';
import '../../models/community.dart';

enum _MemberStatus { eligible, alreadyMember, alreadyInvited, hasJoinRequest }

class _SearchResult {
  final UserModel user;
  _MemberStatus status;
  bool selected;

  _SearchResult({
    required this.user,
    required this.status,
    this.selected = false,
  });
}

/// Lets an admin/moderator invite one or more registered users — searched
/// by name, email, or phone — to join the community. Each result shows
/// whether the person is already a member/invited/requesting, so those
/// rows can't be (re-)selected; eligible rows can be checked/unchecked
/// before sending invites in bulk.
class InviteMemberPage extends ConsumerStatefulWidget {
  final Community community;

  const InviteMemberPage({super.key, required this.community});

  @override
  ConsumerState<InviteMemberPage> createState() => _InviteMemberPageState();
}

class _InviteMemberPageState extends ConsumerState<InviteMemberPage> {
  final _queryController = TextEditingController();

  List<_SearchResult> _results = [];
  bool _isSearching = false;
  bool _hasSearched = false;
  bool _isSendingInvites = false;
  final Set<String> _processingUids = {};

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _queryController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
      _hasSearched = true;
      _results = [];
    });

    try {
      final userRepo = ref.read(userRepositoryProvider);
      final communityRepo = ref.read(communityRepositoryProvider);

      final users = await userRepo.searchRegisteredUsers(query);

      final results = <_SearchResult>[];
      for (final user in users) {
        final status = await _resolveStatus(communityRepo, user.uid);
        results.add(_SearchResult(
          user: user,
          status: status,
          selected: status == _MemberStatus.eligible,
        ));
      }

      if (mounted) setState(() => _results = results);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Something went wrong. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<_MemberStatus> _resolveStatus(
      CommunityRepository communityRepo, String uid) async {
    final memberDoc =
        await communityRepo.memberDoc(widget.community.id, uid).get();
    if (!memberDoc.exists) return _MemberStatus.eligible;

    final data = memberDoc.data();
    final isMember = data?['member'] == true;
    final source = data?['source'] as String? ?? 'requested';
    if (isMember) return _MemberStatus.alreadyMember;
    if (source == 'invited') return _MemberStatus.alreadyInvited;
    return _MemberStatus.hasJoinRequest;
  }

  Future<void> _approveDirectly(_SearchResult result) async {
    setState(() => _processingUids.add(result.user.uid));
    try {
      final communityRepo = ref.read(communityRepositoryProvider);
      final currentUserId = ref.read(authRepositoryProvider).currentUser!.uid;
      await communityRepo.approveMemberAndUpdateCounts(
          widget.community.id, result.user.uid, result.user.bloodGroup);

      try {
        await communityRepo.logCommunityAction(
          communityId: widget.community.id,
          actorUid: currentUserId,
          action: 'approve_member',
          targetUid: result.user.uid,
        );
      } catch (_) {
        // Logging is best-effort.
      }

      if (mounted) {
        setState(() {
          result.status = _MemberStatus.alreadyMember;
          result.selected = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${result.user.firstName} is now a member.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not approve this member. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _processingUids.remove(result.user.uid));
      }
    }
  }

  Future<void> _inviteUser(_SearchResult result) async {
    final communityRepo = ref.read(communityRepositoryProvider);
    final currentUserId = ref.read(authRepositoryProvider).currentUser!.uid;
    final user = result.user;

    await communityRepo.inviteMember(
      widget.community.id,
      user.uid,
      currentUserId,
      user.bloodGroup,
    );

    try {
      await communityRepo.logCommunityAction(
        communityId: widget.community.id,
        actorUid: currentUserId,
        action: 'invite_member',
        targetUid: user.uid,
      );
    } catch (_) {
      // Logging is best-effort.
    }

    try {
      await NotificationService.addNotification(
        title: 'Community Invite',
        body: 'You\'ve been invited to join ${widget.community.name}.',
        type: 'community_invite',
        data: {
          'communityId': widget.community.id,
          'communityName': widget.community.name,
          'invitedBy': currentUserId,
          'bloodGroup': user.bloodGroup,
        },
        userId: user.uid,
      );
      if (user.token.isNotEmpty) {
        await FCMSender.sendToToken(
          token: user.token,
          title: 'Community Invite',
          body: 'You\'ve been invited to join ${widget.community.name}.',
          data: {
            'type': 'community_invite',
            'communityId': widget.community.id,
          },
        );
      }
    } catch (_) {
      // Invite is already recorded; a failed notification shouldn't fail the flow.
    }
  }

  Future<void> _sendInvites() async {
    final selected =
        _results.where((r) => r.status == _MemberStatus.eligible && r.selected);
    if (selected.isEmpty) return;

    setState(() => _isSendingInvites = true);
    var succeeded = 0;
    var failed = 0;

    for (final result in selected.toList()) {
      try {
        await _inviteUser(result);
        succeeded++;
      } catch (_) {
        failed++;
      }
    }

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(failed == 0
              ? 'Invite${succeeded == 1 ? '' : 's'} sent to $succeeded ${succeeded == 1 ? 'person' : 'people'}.'
              : 'Sent $succeeded invite(s); $failed failed. Please try again for those.'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
      );
    }
  }

  String _statusLabel(_MemberStatus status) {
    switch (status) {
      case _MemberStatus.alreadyMember:
        return 'Already a member';
      case _MemberStatus.alreadyInvited:
        return 'Invite already pending';
      case _MemberStatus.hasJoinRequest:
        return 'Already requested to join';
      case _MemberStatus.eligible:
        return '';
    }
  }

  Widget _buildResultTile(_SearchResult result) {
    final user = result.user;
    final isProcessing = _processingUids.contains(user.uid);

    if (result.status == _MemberStatus.eligible) {
      return CheckboxListTile(
        value: result.selected,
        onChanged: (v) => setState(() => result.selected = v ?? false),
        title: Text('${user.firstName} ${user.lastName}'),
        subtitle: Text('${user.bloodGroup} · ${user.mobileNumber}'),
        controlAffinity: ListTileControlAffinity.leading,
      );
    }

    return ListTile(
      leading: CircleAvatar(child: Icon(PhosphorIcons.user)),
      title: Text('${user.firstName} ${user.lastName}'),
      subtitle: Text(_statusLabel(result.status)),
      trailing: result.status == _MemberStatus.hasJoinRequest
          ? TextButton(
              onPressed: isProcessing ? null : () => _approveDirectly(result),
              child: isProcessing
                  ? SizedBox(
                      width: 16.w,
                      height: 16.h,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Approve'),
            )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedCount =
        _results.where((r) => r.status == _MemberStatus.eligible && r.selected).length;

    return Scaffold(
      appBar: AppBar(
        title: Text('Invite Someone to ${widget.community.name}'),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _queryController,
                  decoration: const InputDecoration(
                    labelText: 'Search by name, email, or phone',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _search(),
                ),
                SizedBox(height: 12.h),
                SizedBox(
                  width: double.infinity,
                  height: 48.h,
                  child: ElevatedButton.icon(
                    onPressed: _isSearching ? null : _search,
                    icon: Icon(PhosphorIcons.magnifyingGlass, size: 18.w),
                    label: const Text('Search'),
                  ),
                ),
              ],
            ),
          ),
          if (_isSearching)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_hasSearched && _results.isEmpty)
            Expanded(
              child: Center(
                child: Text(
                  'No registered users found.',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13.sp),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: _results.length,
                itemBuilder: (context, index) =>
                    _buildResultTile(_results[index]),
              ),
            ),
          if (selectedCount > 0)
            Padding(
              padding: EdgeInsets.all(16.w),
              child: SizedBox(
                width: double.infinity,
                height: 50.h,
                child: ElevatedButton(
                  onPressed: _isSendingInvites ? null : _sendInvites,
                  child: _isSendingInvites
                      ? SizedBox(
                          width: 18.w,
                          height: 18.h,
                          child: const CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : Text('Send Invite${selectedCount == 1 ? '' : 's'} ($selectedCount)'),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
