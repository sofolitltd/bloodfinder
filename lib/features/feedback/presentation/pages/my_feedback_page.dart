import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../../data/providers/repository_providers.dart';
import '../../../home/presentation/widgets/feedback_sheet.dart';
import '../../models/app_feedback.dart';

class MyFeedbackPage extends ConsumerStatefulWidget {
  const MyFeedbackPage({super.key});

  @override
  ConsumerState<MyFeedbackPage> createState() => _MyFeedbackPageState();
}

class _MyFeedbackPageState extends ConsumerState<MyFeedbackPage> {
  List<AppFeedback> _feedbacks = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final uid = ref.read(firebaseDataSourceProvider).currentUser?.uid;
      if (uid == null) return;
      final repo = ref.read(feedbackRepositoryProvider);
      final list = await repo.getUserFeedback(uid);
      if (mounted) setState(() => _feedbacks = list);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load feedback')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _delete(AppFeedback fb) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Feedback'),
        content: const Text('Are you sure you want to delete this feedback?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await ref.read(feedbackRepositoryProvider).deleteFeedback(fb.id);
      setState(() => _feedbacks.removeWhere((f) => f.id == fb.id));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Feedback deleted')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete feedback')),
        );
      }
    }
  }

  void _edit(AppFeedback fb) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _EditFeedbackSheet(
        feedback: fb,
        onSaved: (updated) {
          setState(() {
            final index = _feedbacks.indexWhere((f) => f.id == updated.id);
            if (index != -1) _feedbacks[index] = updated;
          });
        },
      ),
    );
  }

  void _add() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const FeedbackSheet(),
    ).then((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32.w,
              height: 32.h,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(
                PhosphorIcons.chatCircleDots,
                color: Colors.red.shade600,
                size: 18.w,
              ),
            ),
            SizedBox(width: 8.w),
            const Text(
              'My Feedback',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
        icon: const Icon(PhosphorIcons.plus, size: 20),
        label: const Text('Add Feedback'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        onPressed: _add,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _feedbacks.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        PhosphorIcons.chatCircleDots,
                        size: 48.w,
                        color: Colors.grey.shade300,
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'No feedback yet',
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'Tap the button below to share your thoughts',
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 80.h),
                    itemCount: _feedbacks.length,
                    separatorBuilder: (_, __) => SizedBox(height: 12.h),
                    itemBuilder: (context, index) {
                      final fb = _feedbacks[index];
                      return _FeedbackCard(
                        feedback: fb,
                        onEdit: () => _edit(fb),
                        onDelete: () => _delete(fb),
                      );
                    },
                  ),
                ),
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  final AppFeedback feedback;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _FeedbackCard({
    required this.feedback,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat.yMMMd().add_jm().format(feedback.createdAt.toDate());
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
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    feedback.category,
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.red.shade700,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  dateStr,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Text(
              feedback.message,
              style: TextStyle(fontSize: 14.sp, height: 1.4),
            ),
            SizedBox(height: 12.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: Icon(PhosphorIcons.pencil, size: 18.w),
                  color: Colors.grey.shade600,
                  onPressed: onEdit,
                ),
                SizedBox(width: 4.w),
                IconButton(
                  icon: Icon(PhosphorIcons.trash, size: 18.w),
                  color: Colors.red.shade400,
                  onPressed: onDelete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EditFeedbackSheet extends ConsumerStatefulWidget {
  final AppFeedback feedback;
  final ValueChanged<AppFeedback> onSaved;

  const _EditFeedbackSheet({
    required this.feedback,
    required this.onSaved,
  });

  @override
  ConsumerState<_EditFeedbackSheet> createState() => _EditFeedbackSheetState();
}

class _EditFeedbackSheetState extends ConsumerState<_EditFeedbackSheet> {
  late final TextEditingController _categoryController;
  late final TextEditingController _messageController;
  bool _submitting = false;

  static const _categories = ['Idea / Suggestion', 'Bug Report', 'Other'];

  @override
  void initState() {
    super.initState();
    _categoryController = TextEditingController(text: widget.feedback.category);
    _messageController = TextEditingController(text: widget.feedback.message);
  }

  @override
  void dispose() {
    _categoryController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final category = _categoryController.text;
    final message = _messageController.text.trim();
    if (category.isEmpty || message.isEmpty) return;

    setState(() => _submitting = true);

    try {
      await ref.read(feedbackRepositoryProvider).updateFeedback(
        widget.feedback.id,
        {'category': category, 'message': message},
      );

      final updated = widget.feedback.copyWith(
        category: category,
        message: message,
      );

      widget.onSaved(updated);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Feedback updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20.w,
        right: 20.w,
        top: 20.h,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Edit Feedback',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          DropdownButtonFormField<String>(
            initialValue: widget.feedback.category,
            decoration: const InputDecoration(
              labelText: 'Category',
              border: OutlineInputBorder(),
            ),
            items: _categories
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (v) => _categoryController.text = v ?? '',
          ),
          SizedBox(height: 16.h),
          TextFormField(
            controller: _messageController,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Your message',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
          SizedBox(height: 20.h),
          FilledButton(
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? SizedBox(
                    width: 20.w,
                    height: 20.h,
                    child: const CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Update'),
          ),
          SizedBox(height: 20.h),
        ],
      ),
    );
  }
}
