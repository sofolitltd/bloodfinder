import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/providers/repository_providers.dart';
import '../../../notification/services/fcm_sender.dart';
import '../../models/community.dart';

class CreateAnnouncementSheet extends ConsumerStatefulWidget {
  final Community community;

  const CreateAnnouncementSheet({super.key, required this.community});

  @override
  ConsumerState<CreateAnnouncementSheet> createState() =>
      _CreateAnnouncementSheetState();
}

class _CreateAnnouncementSheetState
    extends ConsumerState<CreateAnnouncementSheet> {
  final _messageController = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    setState(() => _isSending = true);
    try {
      final communityRepo = ref.read(communityRepositoryProvider);
      final currentUserId = ref.read(authRepositoryProvider).currentUser!.uid;

      await communityRepo.addAnnouncement({
        'communityId': widget.community.id,
        'authorUid': currentUserId,
        'message': message,
        'pinned': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      try {
        await FCMSender.sendToTopic(
          topic: widget.community.id,
          title: widget.community.name,
          body: message,
          data: {
            'type': 'community',
            'communityId': widget.community.id,
          },
        );
      } catch (_) {
        // Announcement is already posted; a failed push shouldn't fail the flow.
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not post the announcement. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24.w,
        right: 24.w,
        top: 24.w,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24.w,
      ),
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
          Text(
            'New Announcement',
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16.h),
          TextField(
            controller: _messageController,
            maxLines: 4,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Share an update with the community...',
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 20.h),
          SizedBox(
            width: double.infinity,
            height: 50.h,
            child: ElevatedButton(
              onPressed: _isSending ? null : _submit,
              child: _isSending
                  ? SizedBox(
                      width: 18.w,
                      height: 18.h,
                      child: const CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Post'),
            ),
          ),
        ],
      ),
    );
  }
}
