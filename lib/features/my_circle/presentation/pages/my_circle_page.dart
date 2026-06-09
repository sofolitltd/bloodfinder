import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../data/providers/repository_providers.dart';
import '../../models/my_circle_contact.dart';
import '../../providers/my_circle_provider.dart';
import '../widgets/add_contact_sheet.dart';

class MyCirclePage extends ConsumerStatefulWidget {
  const MyCirclePage({super.key});

  @override
  ConsumerState<MyCirclePage> createState() => _MyCirclePageState();
}

class _MyCirclePageState extends ConsumerState<MyCirclePage>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;

  static const _bloodGroupOrder = [
    'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-',
  ];

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final contactsAsync = ref.watch(myCircleProvider);

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
                PhosphorIcons.usersThree,
                color: Colors.red.shade600,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            const Text('My Circle', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        bottom: contactsAsync.maybeWhen(
          data: (contacts) {
            if (contacts.isEmpty) return null as PreferredSizeWidget?;
            final grouped = <String, List<MyCircleContact>>{};
            for (final c in contacts) {
              grouped.putIfAbsent(c.bloodGroup, () => []);
              grouped[c.bloodGroup]!.add(c);
            }
            final available = _bloodGroupOrder
                .where((bg) => grouped.containsKey(bg) && grouped[bg]!.isNotEmpty)
                .toList();
            if (available.isEmpty) return null as PreferredSizeWidget?;

            _tabController?.dispose();
            _tabController = TabController(
              length: available.length,
              vsync: this,
            );

            return TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: Colors.red.shade700,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.red.shade700,
              tabs: available.map((bg) => Tab(text: '$bg (${grouped[bg]!.length})')).toList(),
            );
          },
          orElse: () => null as PreferredSizeWidget?,
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
        icon: const Icon(PhosphorIcons.plusBold, size: 20),
        label: const Text('Add Contact'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (_) => const AddContactSheet(),
          );
        },
      ),
      body: contactsAsync.when(
        data: (contacts) => _buildBody(context, ref, contacts),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildBody(
      BuildContext context, WidgetRef ref, List<MyCircleContact> contacts) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (contacts.isEmpty) {
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
                PhosphorIcons.usersThree,
                size: 34,
                color: Colors.red.shade300,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No contacts yet',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.grey.shade200 : Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Tap + to add family & friends\nto your circle",
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

    final grouped = <String, List<MyCircleContact>>{};
    for (final c in contacts) {
      grouped.putIfAbsent(c.bloodGroup, () => []);
      grouped[c.bloodGroup]!.add(c);
    }

    final available = _bloodGroupOrder
        .where((bg) => grouped.containsKey(bg) && grouped[bg]!.isNotEmpty)
        .toList();

    if (_tabController == null || _tabController!.length != available.length) {
      _tabController?.dispose();
      _tabController = TabController(
        length: available.length,
        vsync: this,
      );
    }

    return TabBarView(
      controller: _tabController,
      children: available.map((bg) {
        final bgContacts = grouped[bg]!;
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          itemCount: bgContacts.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: EdgeInsets.only(top: index == 0 ? 0 : 12),
              child: _buildContactCard(context, ref, bgContacts[index], isDark),
            );
          },
        );
      }).toList(),
    );
  }

  Widget _buildContactCard(
      BuildContext context, WidgetRef ref, MyCircleContact contact, bool isDark) {
    return Container(
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
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  contact.name.isNotEmpty
                      ? contact.name[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          contact.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isDark ? Colors.grey.shade200 : Colors.grey.shade800,
                          ),
                        ),
                      ),
                      if (contact.isAppUser)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'App User',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(PhosphorIcons.phone,
                          size: 14, color: isDark ? Colors.grey.shade500 : Colors.grey.shade400),
                      const SizedBox(width: 6),
                      Text(
                        contact.phone,
                        style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(PhosphorIcons.usersThree,
                          size: 14, color: isDark ? Colors.grey.shade500 : Colors.grey.shade400),
                      const SizedBox(width: 6),
                      Text(
                        contact.relation,
                        style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _ActionButton(
                        icon: PhosphorIcons.phoneCall,
                        label: 'Call',
                        color: Colors.green.shade600,
                        onTap: () => _callNumber(contact.phone),
                      ),
                      const SizedBox(width: 8),
                      if (!contact.isAppUser)
                        _ActionButton(
                          icon: PhosphorIcons.shareNetwork,
                          label: 'Invite',
                          color: Colors.blue.shade600,
                          onTap: () => _inviteContact(contact),
                        ),
                      const Spacer(),
                      _ActionButton(
                        icon: PhosphorIcons.trash,
                        label: '',
                        color: Colors.red.shade400,
                        onTap: () => _removeContact(context, ref, contact),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _callNumber(String phone) async {
    final uri = Uri.parse('tel:$phone');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Error calling $phone: $e');
    }
  }

  Future<void> _inviteContact(MyCircleContact contact) async {
    await SharePlus.instance.share(
      ShareParams(
        text:
            'Hey ${contact.name}, I use Blood Finder to manage blood donations. '
            'Please join and help save lives! Download the app and use my invite.',
      ),
    );
  }

  Future<void> _removeContact(
      BuildContext context, WidgetRef ref, MyCircleContact contact) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Contact'),
        content: Text('Remove ${contact.name} from your circle?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child:
                const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final ownerId =
          ref.read(authRepositoryProvider).currentUser!.uid;
      await ref.read(myCircleRepositoryProvider).removeContact(
            ownerId,
            contact.id,
          );
    }
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: color),
            if (label.isNotEmpty) ...[
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
