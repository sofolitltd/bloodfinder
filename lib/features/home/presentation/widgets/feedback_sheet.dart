import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../feedback/models/app_feedback.dart';
import '../../../../data/providers/repository_providers.dart';

class FeedbackSheet extends ConsumerStatefulWidget {
  const FeedbackSheet({super.key});

  @override
  ConsumerState<FeedbackSheet> createState() => _FeedbackSheetState();
}

class _FeedbackSheetState extends ConsumerState<FeedbackSheet> {
  final _categoryController = TextEditingController();
  final _messageController = TextEditingController();
  bool _submitting = false;

  static const _categories = ['Idea / Suggestion', 'Bug Report', 'Other'];

  @override
  void initState() {
    super.initState();
    _categoryController.text = _categories[0];
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

    final uid = FirebaseAuth.instance.currentUser!.uid;
    final feedback = AppFeedback(
      id: '',
      uid: uid,
      category: category,
      message: message,
      createdAt: Timestamp.now(),
    );

    try {
      await ref.read(feedbackRepositoryProvider).submitFeedback(feedback);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thank you for your feedback!')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Share Feedback',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _categories[0],
            decoration: const InputDecoration(
              labelText: 'Category',
              border: OutlineInputBorder(),
            ),
            items: _categories
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (v) => _categoryController.text = v ?? '',
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _messageController,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Your message',
              hintText: 'Describe your idea, suggestion, or bug...',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Submit'),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

void showFeedbackSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => const FeedbackSheet(),
  );
}
