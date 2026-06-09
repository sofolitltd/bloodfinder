import 'package:flutter/material.dart';

import '../models/social_media_link.dart';

class SocialMediaInput extends StatefulWidget {
  final List<SocialMediaLink> initialLinks;
  final ValueChanged<List<SocialMediaLink>> onLinksChanged;

  const SocialMediaInput({
    super.key,
    this.initialLinks = const [],
    required this.onLinksChanged,
  });

  @override
  State<SocialMediaInput> createState() => _SocialMediaInputState();
}

class _SocialMediaInputState extends State<SocialMediaInput> {
  late List<_LinkEntry> _entries;

  @override
  void initState() {
    super.initState();
    _entries = widget.initialLinks
        .map((l) => _LinkEntry(
              platform: l.platform,
              controller: TextEditingController(text: l.url),
            ))
        .toList();
  }

  @override
  void dispose() {
    for (final e in _entries) {
      e.controller.dispose();
    }
    super.dispose();
  }

  List<SocialMediaLink> get _links => _entries
      .where((e) => e.controller.text.trim().isNotEmpty)
      .map((e) => SocialMediaLink(
            platform: e.platform,
            url: e.controller.text.trim(),
          ))
      .toList();

  void _addEntry() {
    setState(() {
      _entries.add(_LinkEntry(
        platform: SocialMediaLink.platformOptions.first,
        controller: TextEditingController(),
      ));
    });
  }

  void _removeEntry(int index) {
    setState(() {
      _entries[index].controller.dispose();
      _entries.removeAt(index);
    });
    widget.onLinksChanged(_links);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...List.generate(_entries.length, (i) {
          final entry = _entries[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Platform',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 12,
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: entry.platform,
                        isExpanded: true,
                        isDense: true,
                        items: SocialMediaLink.platformOptions
                            .map(
                              (p) =>
                                  DropdownMenuItem(value: p, child: Text(p)),
                            )
                            .toList(),
                        onChanged: (v) {
                          if (v == null) return;
                          setState(() => entry.platform = v);
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: entry.controller,
                    decoration: const InputDecoration(
                      hintText: 'Enter URL',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 12,
                      ),
                    ),
                    keyboardType: TextInputType.url,
                    onChanged: (_) => widget.onLinksChanged(_links),
                  ),
                ),
                const SizedBox(width: 2),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline,
                      color: Colors.red, size: 20),
                  onPressed: () => _removeEntry(i),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 28,
                    minHeight: 28,
                  ),
                ),
              ],
            ),
          );
        }),
        TextButton.icon(
          onPressed: _addEntry,
          icon: const Icon(Icons.add),
          label: const Text('Add Link'),
        ),
      ],
    );
  }
}

class _LinkEntry {
  String platform;
  final TextEditingController controller;

  _LinkEntry({required this.platform, required this.controller});
}
