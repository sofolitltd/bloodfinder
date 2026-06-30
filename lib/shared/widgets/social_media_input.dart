import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
            padding: EdgeInsets.only(bottom: 12.h),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Platform',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 12.h,
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
                SizedBox(width: 4.w),
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: entry.controller,
                    decoration: InputDecoration(
                      hintText: 'Enter URL',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 12.h,
                      ),
                    ),
                    keyboardType: TextInputType.url,
                    onChanged: (_) => widget.onLinksChanged(_links),
                  ),
                ),
                SizedBox(width: 2.w),
                IconButton(
                  icon: Icon(Icons.remove_circle_outline,
                      color: Colors.red, size: 20.w),
                  onPressed: () => _removeEntry(i),
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(
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
          icon: Icon(Icons.add),
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
