import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../../core/constants/blood_groups_data.dart';
import '../../../../core/utils/phone_utils.dart';
import '../../../../data/models/user_model.dart';
import '../../../../data/providers/repository_providers.dart';
import '../../../notification/services/fcm_sender.dart';
import '../../../notification/services/notification_service.dart';
import '../../models/community.dart';

/// Lets ANY signed-in user — member or not — contact a community's
/// admins/moderators directly to ask for blood, without joining.
class RequestBloodFromCommunitySheet extends ConsumerStatefulWidget {
  final Community community;

  const RequestBloodFromCommunitySheet({super.key, required this.community});

  @override
  ConsumerState<RequestBloodFromCommunitySheet> createState() =>
      _RequestBloodFromCommunitySheetState();
}

class _RequestBloodFromCommunitySheetState
    extends ConsumerState<RequestBloodFromCommunitySheet> {
  final _formKey = GlobalKey<FormState>();
  final _mobileController = TextEditingController();
  final _noteController = TextEditingController();

  String? _bloodGroup;
  UserModel? _currentUserModel;
  bool _isSending = false;
  bool _prefillLoaded = false;

  @override
  void initState() {
    super.initState();
    _prefillFromProfile();
  }

  Future<void> _prefillFromProfile() async {
    try {
      final uid = ref.read(authRepositoryProvider).currentUser!.uid;
      final doc = await ref.read(userRepositoryProvider).getUser(uid);
      if (doc.exists && mounted) {
        final user = UserModel.fromFirestore(doc);
        setState(() {
          _mobileController.text = user.mobileNumber;
          _bloodGroup = user.bloodGroup;
          _currentUserModel = user;
        });
      }
    } catch (_) {
      // Prefill is a convenience only; leave fields blank on failure.
    } finally {
      if (mounted) setState(() => _prefillLoaded = true);
    }
  }

  @override
  void dispose() {
    _mobileController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false) || _bloodGroup == null) {
      if (_bloodGroup == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a blood group.')),
        );
      }
      return;
    }

    setState(() => _isSending = true);

    try {
      final requester = ref.read(authRepositoryProvider).currentUser!;
      final requesterName = _currentUserModel != null
          ? '${_currentUserModel!.firstName} ${_currentUserModel!.lastName}'
          : 'A Blood Finder user';
      final userRepo = ref.read(userRepositoryProvider);

      final recipientUids = {
        ...widget.community.admin,
        ...widget.community.moderators,
      }.toList();

      if (recipientUids.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('This community has no admins to notify.'),
            ),
          );
        }
        return;
      }

      final mobile = PhoneUtils.toCanonical(_mobileController.text.trim());
      final note = _noteController.text.trim();

      final data = {
        'communityId': widget.community.id,
        'communityName': widget.community.name,
        'requesterUid': requester.uid,
        'requesterName': requesterName,
        'bloodGroup': _bloodGroup,
        'mobile': mobile,
        if (note.isNotEmpty) 'note': note,
      };

      for (final adminUid in recipientUids) {
        try {
          await NotificationService.addNotification(
            title: 'Blood Help Request',
            body:
                '$_bloodGroup blood needed — someone is asking ${widget.community.name} for help.',
            type: 'community_blood_help_request',
            data: data,
            userId: adminUid,
          );
        } catch (_) {
          // Don't let one failed recipient block the others.
        }
      }

      try {
        final recipientsSnap = await userRepo.getUsersByIds(recipientUids);
        for (final doc in recipientsSnap.docs) {
          final token = doc.data()['token'] as String?;
          if (token != null && token.isNotEmpty) {
            await FCMSender.sendToToken(
              token: token,
              title: 'Blood Help Request',
              body:
                  '$_bloodGroup blood needed — someone is asking ${widget.community.name} for help.',
              data: data,
            );
          }
        }
      } catch (_) {
        // Push is best-effort; the in-app notification is already saved.
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Request sent to ${widget.community.name}\'s admins.'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Something went wrong. Please try again.'),
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
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
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
                'Request Blood from ${widget.community.name}',
                style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4.h),
              Text(
                'This goes directly to the community\'s admins — you don\'t need to join.',
                style: TextStyle(fontSize: 13.sp, color: Colors.grey.shade600),
              ),
              SizedBox(height: 20.h),
              DropdownButtonFormField<String>(
                initialValue: _bloodGroup,
                decoration: const InputDecoration(
                  labelText: 'Blood group needed',
                  border: OutlineInputBorder(),
                ),
                items: AppBloodGroups.bloodGroups
                    .map((bg) => DropdownMenuItem(value: bg, child: Text(bg)))
                    .toList(),
                onChanged: (value) => setState(() => _bloodGroup = value),
              ),
              SizedBox(height: 12.h),
              TextFormField(
                controller: _mobileController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Contact mobile number',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Please enter a contact number'
                    : null,
              ),
              SizedBox(height: 12.h),
              TextFormField(
                controller: _noteController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Note (hospital, patient, urgency...)',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
              SizedBox(height: 20.h),
              SizedBox(
                width: double.infinity,
                height: 50.h,
                child: ElevatedButton.icon(
                  onPressed:
                      (_isSending || !_prefillLoaded) ? null : _submit,
                  icon: _isSending
                      ? SizedBox(
                          width: 18.w,
                          height: 18.h,
                          child: const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Icon(PhosphorIcons.paperPlaneTilt),
                  label: const Text('Send Request'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
