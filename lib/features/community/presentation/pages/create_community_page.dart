import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../widgets/community_form.dart';
import '../widgets/expandable_info_card.dart';

class CreateCommunityScreen extends StatefulWidget {
  const CreateCommunityScreen({super.key});

  @override
  State<CreateCommunityScreen> createState() => _CreateCommunityScreenState();
}

class _CreateCommunityScreenState extends State<CreateCommunityScreen> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                PhosphorIcons.usersFour,
                color: Colors.red.shade600,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Create Community',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          children: [
            const ExpandableInfoCard(),
            const SizedBox(height: 16),
            CommunityForm(
              onCommunityCreated: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}
