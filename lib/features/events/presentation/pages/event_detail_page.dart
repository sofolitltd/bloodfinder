import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../data/providers/repository_providers.dart';
import '../../../../data/providers/user_providers.dart';
import '../../models/blood_event.dart';
import '../widgets/create_event_sheet.dart';

class EventDetailPage extends ConsumerStatefulWidget {
  final BloodEvent event;

  const EventDetailPage({super.key, required this.event});

  @override
  ConsumerState<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends ConsumerState<EventDetailPage> {
  bool _deleteLoading = false;

  bool _isOrganizer(String uid) =>
      uid.isNotEmpty && widget.event.organizerUid == uid;

  Future<void> _deleteEvent() async {
    final confirmed = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Event'),
        content: const Text('Are you sure? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;

    setState(() => _deleteLoading = true);

    try {
      await ref.read(eventRepositoryProvider).deleteEvent(widget.event.id);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event deleted.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete event: $e')),
      );
    } finally {
      if (mounted) setState(() => _deleteLoading = false);
    }
  }

  void _editEvent() {
    showCreateEventSheet(context, ref, event: widget.event);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final userAsync = ref.watch(userProvider);
    final uid = userAsync.value?.uid ?? '';
    final isOrganizer = _isOrganizer(uid);

    final repo = ref.read(eventRepositoryProvider);
    final rsvpStream = repo.rsvpStream(widget.event.id, uid);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.elliptical(300, 40),
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  if (widget.event.imageUrl != null &&
                      widget.event.imageUrl!.isNotEmpty)
                    SizedBox(
                      height: 280,
                      width: double.infinity,
                      child: Image.network(
                        widget.event.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                  Container(
                    height: 280,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.red.shade800,
                          Colors.red.shade600,
                          Colors.red.shade400,
                        ],
                      ),
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.elliptical(300, 40),
                      ),
                    ),
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(4, 4, 16, 28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    PhosphorIcons.arrowLeft,
                                    color: Colors.white,
                                  ),
                                  onPressed: () => Navigator.pop(context),
                                ),
                                const Spacer(),
                                if (isOrganizer)
                                  _deleteLoading
                                      ? const Padding(
                                          padding: EdgeInsets.all(16),
                                          child: SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          ),
                                        )
                                      : PopupMenuButton<String>(
                                          icon: const Icon(
                                            PhosphorIcons.dotsThreeVertical,
                                            color: Colors.white,
                                          ),
                                          onSelected: (value) {
                                            if (value == 'edit') _editEvent();
                                            if (value == 'delete')
                                              _deleteEvent();
                                          },
                                          itemBuilder: (_) => [
                                            const PopupMenuItem(
                                              value: 'edit',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.edit, size: 20),
                                                  SizedBox(width: 8),
                                                  Text('Edit Event'),
                                                ],
                                              ),
                                            ),
                                            const PopupMenuItem(
                                              value: 'delete',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.delete,
                                                      size: 20,
                                                      color: Colors.red),
                                                  SizedBox(width: 8),
                                                  Text('Delete Event',
                                                      style: TextStyle(
                                                          color: Colors.red)),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                              ],
                            ),
                            const Spacer(),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.event.title,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'by ${widget.event.organizerName}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color:
                                          Colors.white.withValues(alpha: 0.8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Transform.translate(
              offset: const Offset(0, -16),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  color: theme.colorScheme.surface,
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _InfoTile(
                          icon: PhosphorIcons.calendar,
                          iconColor: Colors.red.shade400,
                          label: 'Date & Time',
                          value: widget.event.dateDisplay,
                          isDark: isDark,
                        ),
                        const Divider(height: 20),
                        _InfoTile(
                          icon: PhosphorIcons.mapPin,
                          iconColor: Colors.grey.shade500,
                          label: 'Location',
                          value: widget.event.locationAddress,
                          isDark: isDark,
                        ),
                        const Divider(height: 20),
                        _InfoTile(
                          icon: PhosphorIcons.user,
                          iconColor: Colors.blue.shade400,
                          label: 'Attendance',
                          value: '${widget.event.rsvpCount} attending',
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (widget.event.description.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  color: theme.colorScheme.surface,
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(PhosphorIcons.info,
                                size: 20, color: Colors.red.shade400),
                            const SizedBox(width: 8),
                            Text(
                              'About this event',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.event.description,
                          style: TextStyle(
                            height: 1.5,
                            fontSize: 14,
                            color: isDark
                                ? Colors.grey.shade300
                                : Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          final text =
                              'Blood Camp Event: ${widget.event.title}\n'
                              'Date: ${widget.event.dateDisplay}\n'
                              'Location: ${widget.event.locationAddress}';
                          SharePlus.instance.share(
                            ShareParams(
                              text: text,
                              subject: 'Blood Camp Event',
                              title: widget.event.title,
                            ),
                          );
                        },
                        icon: const Icon(PhosphorIcons.shareNetwork, size: 20),
                        label: const Text('Share'),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: StreamBuilder<
                        DocumentSnapshot<Map<String, dynamic>>>(
                      stream: rsvpStream,
                      builder: (context, snap) {
                        final hasRsvpd = snap.hasData && snap.data!.exists;

                        return SizedBox(
                          height: 48,
                          child: FilledButton.icon(
                            onPressed: () async {
                              if (hasRsvpd) {
                                await repo.cancelRsvp(widget.event.id, uid);
                              } else {
                                await repo.rsvpEvent(widget.event.id, uid);
                              }
                            },
                            icon: Icon(
                              hasRsvpd
                                  ? PhosphorIcons.x
                                  : PhosphorIcons.check,
                              size: 20,
                            ),
                            label: Text(
                              hasRsvpd ? 'Cancel RSVP' : "I'll be there",
                            ),
                            style: hasRsvpd
                                ? FilledButton.styleFrom(
                                    backgroundColor: Colors.grey.shade400,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  )
                                : FilledButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final bool isDark;

  const _InfoTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: iconColor),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey.shade200 : Colors.grey.shade800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
