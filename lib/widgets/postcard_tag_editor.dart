import 'package:flutter/material.dart';

import '../models/postcard.dart';

class PostcardTagEditor extends StatefulWidget {
  const PostcardTagEditor({
    super.key,
    required this.selectedTags,
    required this.availableTags,
    required this.onChanged,
    this.enabled = true,
    this.labelText = '標籤',
    this.hintText = '輸入新的 hashtag',
  });

  final List<String> selectedTags;
  final List<String> availableTags;
  final ValueChanged<List<String>> onChanged;
  final bool enabled;
  final String labelText;
  final String hintText;

  @override
  State<PostcardTagEditor> createState() => _PostcardTagEditorState();
}

class _PostcardTagEditorState extends State<PostcardTagEditor> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleTag(String tag) {
    final normalized = Postcard.normalizeTag(tag);
    if (normalized.isEmpty || !widget.enabled) {
      return;
    }

    final nextTags = List<String>.from(widget.selectedTags);
    if (nextTags.contains(normalized)) {
      nextTags.remove(normalized);
    } else {
      nextTags.add(normalized);
    }

    widget.onChanged(nextTags);
  }

  void _addCustomTag() {
    final normalized = Postcard.normalizeTag(_controller.text);
    if (normalized.isEmpty || !widget.enabled) {
      return;
    }

    final nextTags = List<String>.from(widget.selectedTags);
    if (!nextTags.contains(normalized)) {
      nextTags.add(normalized);
      widget.onChanged(nextTags);
    }

    _controller.clear();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final allSuggestions =
        <String>{
            ...kBuiltInPostcardTags,
            ...widget.availableTags,
            ...widget.selectedTags,
          }.map(Postcard.normalizeTag).where((tag) => tag.isNotEmpty).toList()
          ..sort();

    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                widget.labelText,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 8),
              Text(
                '${widget.selectedTags.length} 個',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final tag in allSuggestions)
                FilterChip(
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  avatar: widget.selectedTags.contains(tag)
                      ? const Icon(Icons.check, size: 14)
                      : null,
                  label: Text(
                    Postcard.displayTag(tag),
                    style: const TextStyle(fontSize: 13),
                  ),
                  selected: widget.selectedTags.contains(tag),
                  onSelected: (_) => _toggleTag(tag),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  enabled: widget.enabled,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    hintText: widget.hintText,
                    prefixText: '#',
                    isDense: true,
                    filled: true,
                    fillColor: colorScheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onSubmitted: (_) => _addCustomTag(),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: widget.enabled ? _addCustomTag : null,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                ),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('新增'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
