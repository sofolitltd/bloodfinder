import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/utils/phone_utils.dart';
import '../../../../data/providers/repository_providers.dart';
import '../../models/my_circle_contact.dart';
import '../../providers/my_circle_provider.dart';
import '../../../chat/models/chat_model.dart';
import '../widgets/add_contact_sheet.dart';

class MyCirclePage extends ConsumerStatefulWidget {
  const MyCirclePage({super.key});

  @override
  ConsumerState<MyCirclePage> createState() => _MyCirclePageState();
}

class _MyCirclePageState extends ConsumerState<MyCirclePage>
    with TickerProviderStateMixin {
  TabController? _tabController;

  static const _bloodGroupOrder = [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-',
  ];

  /// Ensures the auto-link check only runs once per page lifecycle.
  bool _autoLinkChecked = false;

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final contactsAsync = ref.watch(myCircleProvider);

    // Auto-link: once per page load, check non-app-user contacts
    // to see if they've since joined the app.
    ref.listen(myCircleProvider, (prev, next) {
      next.whenData((contacts) => _autoLinkUnlinkedContacts(contacts));
    });

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
                PhosphorIcons.usersThree,
                color: Colors.red.shade600,
                size: 18.w,
              ),
            ),
            SizedBox(width: 8.w),
            const Text(
              'My Circle',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
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
                .where(
                  (bg) => grouped.containsKey(bg) && grouped[bg]!.isNotEmpty,
                )
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
              tabs: available
                  .map((bg) => Tab(text: '$bg (${grouped[bg]!.length})'))
                  .toList(),
            );
          },
          orElse: () => null as PreferredSizeWidget?,
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
        icon: Icon(PhosphorIcons.plusBold, size: 20.w),
        label: const Text('Add Contact'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
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
    BuildContext context,
    WidgetRef ref,
    List<MyCircleContact> contacts,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (contacts.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72.w,
              height: 72.h,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Icon(
                PhosphorIcons.usersThree,
                size: 34.w,
                color: Colors.red.shade300,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'No contacts yet',
              style: TextStyle(
                fontSize: 17.sp,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.grey.shade200 : Colors.grey.shade800,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              "Tap + to add family & friends\nto your circle",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.sp,
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
      _tabController = TabController(length: available.length, vsync: this);
    }

    return TabBarView(
      controller: _tabController,
      children: available.map((bg) {
        final bgContacts = grouped[bg]!;
        return ListView.builder(
          padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 96.h),
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
    BuildContext context,
    WidgetRef ref,
    MyCircleContact contact,
    bool isDark,
  ) {
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
        padding: EdgeInsets.all(12.w),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40.w,
              height: 48.h,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Center(
                child: Text(
                  contact.name.isNotEmpty ? contact.name[0].toUpperCase() : '?',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade600,
                  ),
                ),
              ),
            ),
            SizedBox(width: 8.w),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: .start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: .start,
                          children: [
                            Text(
                              contact.name,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16.sp,
                                height: 1.2,
                                color: isDark
                                    ? Colors.grey.shade200
                                    : Colors.grey.shade800,
                              ),
                            ),

                            SizedBox(height: 2.h),

                            Row(
                              children: [
                                Icon(
                                  PhosphorIcons.usersThree,
                                  size: 14.w,
                                  color: isDark
                                      ? Colors.grey.shade500
                                      : Colors.grey.shade400,
                                ),
                                SizedBox(width: 6.w),
                                Text(
                                  contact.relation,
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    color: isDark
                                        ? Colors.grey.shade400
                                        : Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (contact.isAppUser)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 3.h,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Text(
                            'App User',
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      Icon(
                        PhosphorIcons.phone,
                        size: 14.w,
                        color: isDark
                            ? Colors.grey.shade500
                            : Colors.grey.shade400,
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        contact.phone,
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: isDark
                              ? Colors.grey.shade400
                              : Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6.h),
                  Row(
                    children: [
                      _ActionButton(
                        icon: PhosphorIcons.phoneCall,
                        label: 'Call',
                        color: Colors.green.shade600,
                        onTap: () => _callNumber(contact.phone),
                      ),
                      SizedBox(width: 8.w),
                      if (contact.isAppUser)
                        _ActionButton(
                          icon: PhosphorIcons.chatDots,
                          label: 'Message',
                          color: Colors.blue.shade600,
                          onTap: () => _messageContact(contact),
                        ),
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

  /// For contacts that were added before their phone number was linked to
  /// an app user, check if they've registered since and update accordingly.
  ///
  /// Only runs once per page lifecycle (guarded by [_autoLinkChecked]).
  Future<void> _autoLinkUnlinkedContacts(List<MyCircleContact> contacts) async {
    if (_autoLinkChecked) return;
    _autoLinkChecked = true;

    final unlinked = contacts
        .where((c) => !c.isAppUser && c.phone.isNotEmpty)
        .toList();
    if (unlinked.isEmpty) return;

    try {
      final repo = ref.read(myCircleRepositoryProvider);

      // Batch check all unlinked contact phones
      final appUsers = await repo.findRegisteredUsersByPhones(
        unlinked.map((c) => c.phone).toList(),
      );
      if (appUsers.isEmpty) return;

      // Link each matching contact
      for (final contact in unlinked) {
        final userId = appUsers[PhoneUtils.normalize(contact.phone)];
        if (userId != null) {
          await repo.linkContactToUser(contact.id, userId);
        }
      }
    } catch (e) {
      debugPrint('autoLinkUnlinkedContacts error: $e');
    }
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

  Future<void> _messageContact(MyCircleContact contact) async {
    final otherUserId = contact.linkedUserId;
    if (otherUserId == null) return;

    try {
      final currentUserId = ref.read(authRepositoryProvider).currentUser!.uid;
      final communityRepo = ref.read(communityRepositoryProvider);

      final existingChats = await communityRepo.getExistingChat(
        currentUserId,
        otherUserId,
      );

      DocumentSnapshot<Map<String, dynamic>>? chatDoc;
      if (existingChats.isNotEmpty) {
        chatDoc = existingChats.first;
      }

      if (chatDoc == null) {
        final emptyMsg = MessageModel(
          id: '',
          senderId: '',
          text: 'Hi! Feel free to send your first message.',
          timestamp: DateTime.now(),
          seenBy: [],
        );

        final newChatRef = await communityRepo.addChat({
          'participants': [currentUserId, otherUserId],
          'lastMessage': emptyMsg.toMap(),
          'lastTime': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
          'archivedBy': [],
          'deletedBy': [],
        });
        chatDoc = await newChatRef.get();
      }

      if (context.mounted) {
        context.push('/chats/${chatDoc.id}');
      }
    } catch (e) {
      debugPrint('Error messaging contact: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to start chat: $e')));
      }
    }
  }

  Future<void> _removeContact(
    BuildContext context,
    WidgetRef ref,
    MyCircleContact contact,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Contact'),
        content: Text('Remove ${contact.name} from your circle?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final ownerId = ref.read(authRepositoryProvider).currentUser!.uid;
      await ref
          .read(myCircleRepositoryProvider)
          .removeContact(ownerId, contact.id);
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
      borderRadius: BorderRadius.circular(8.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15.w, color: color),
            if (label.isNotEmpty) ...[
              SizedBox(width: 5.w),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
