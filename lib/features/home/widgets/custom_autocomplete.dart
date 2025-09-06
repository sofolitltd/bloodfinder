import 'package:flutter/material.dart';

class CustomAutocomplete extends StatefulWidget {
  final List<String> items;
  final void Function(String) onSelected;
  final String label;
  final bool enabled;
  final VoidCallback? onClear;

  const CustomAutocomplete({
    super.key,
    required this.items,
    required this.onSelected,
    required this.label,
    this.enabled = true,
    this.onClear,
  });

  @override
  State<CustomAutocomplete> createState() => _CustomAutocompleteState();
}

class _CustomAutocompleteState extends State<CustomAutocomplete> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Autocomplete<String>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        final input = textEditingValue.text.toLowerCase();
        final sortedItems = [...widget.items]
          ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

        if (input.isEmpty) return sortedItems;
        return sortedItems.where((item) => item.toLowerCase().contains(input));
      },
      onSelected: widget.onSelected,
      fieldViewBuilder: (context, textEditingController, focusNode, _) {
        return Focus(
          onFocusChange: (hasFocus) {
            if (!hasFocus) focusNode.unfocus();
          },
          child: TextField(
            controller: textEditingController,
            focusNode: focusNode,
            enabled: widget.enabled,
            decoration: InputDecoration(
              labelText: widget.label,
              border: const OutlineInputBorder(),
              suffixIcon: textEditingController.text.isEmpty
                  ? const Icon(Icons.arrow_drop_down)
                  : IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        textEditingController.clear();
                        widget.onClear?.call();
                        setState(() {});
                      },
                    ),
            ),
            onChanged: (_) => setState(() {}),
          ),
        );
      },
    );
  }
}
