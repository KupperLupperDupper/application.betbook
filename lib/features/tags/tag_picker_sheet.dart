import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../data/database/database.dart';
import '../../data/repositories/tag_repository.dart';
import '../../l10n/l10n_ext.dart';
import '../../providers/core_providers.dart';
import '../../providers/tags_providers.dart';
import '../../widgets/tag_chip.dart';

/// Opens the tag picker (TAGS_HANDOFF §4.1). Selection changes are pushed to
/// [onChanged] live, so the sheet works the same however it is dismissed.
/// [maxSelection] is 5 when assigning, 3 when filtering Stats ([filterMode]).
Future<void> showTagPickerSheet(
  BuildContext context, {
  required List<String> selected,
  required ValueChanged<List<String>> onChanged,
  int maxSelection = 5,
  bool filterMode = false,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _TagPickerSheet(
      initial: selected,
      onChanged: onChanged,
      maxSelection: maxSelection,
      filterMode: filterMode,
    ),
  );
}

class _TagPickerSheet extends ConsumerStatefulWidget {
  const _TagPickerSheet({
    required this.initial,
    required this.onChanged,
    required this.maxSelection,
    required this.filterMode,
  });

  final List<String> initial;
  final ValueChanged<List<String>> onChanged;
  final int maxSelection;
  final bool filterMode;

  @override
  ConsumerState<_TagPickerSheet> createState() => _TagPickerSheetState();
}

class _TagPickerSheetState extends ConsumerState<_TagPickerSheet> {
  final _controller = TextEditingController();
  late final List<String> _selected = [...widget.initial];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _emit() => widget.onChanged(List.of(_selected));

  bool get _atCap => _selected.length >= widget.maxSelection;

  void _toggle(String id) {
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else if (!_atCap) {
        _selected.add(id);
      }
    });
    _emit();
  }

  Future<void> _create(String name) async {
    final id = await ref.read(tagRepositoryProvider).createOrGet(name);
    if (!mounted) return;
    setState(() {
      if (!_selected.contains(id) && !_atCap) _selected.add(id);
      _controller.clear();
    });
    _emit();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final tags = ref.watch(tagsProvider).valueOrNull ?? const <Tag>[];
    final counts = ref.watch(tagCountsProvider);
    final query = _controller.text.trim();
    final folded = TagRepository.fold(query);

    int use(Tag t) => counts[t.id] ?? 0;
    final byUse = [...tags]..sort((a, b) {
        final c = use(b).compareTo(use(a));
        return c != 0 ? c : a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

    List<Tag> visible;
    if (query.isEmpty) {
      visible = byUse.take(12).toList();
    } else {
      final q = query.toLowerCase();
      visible = byUse.where((t) => t.name.toLowerCase().contains(q)).toList()
        ..sort((a, b) {
          final ap = a.name.toLowerCase().startsWith(q) ? 0 : 1;
          final bp = b.name.toLowerCase().startsWith(q) ? 0 : 1;
          return ap != bp ? ap - bp : use(b).compareTo(use(a));
        });
    }
    final hasExact = tags.any((t) => t.nameFolded == folded);
    final showCreate = query.isNotEmpty && !hasExact;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            textCapitalization: TextCapitalization.none,
            onChanged: (_) => setState(() {}),
            onSubmitted: (v) {
              if (v.trim().isNotEmpty && !hasExact) _create(v.trim());
            },
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search_rounded),
              hintText: l10n.searchOrCreateTag,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
          if (_atCap) ...[
            const SizedBox(height: 8),
            Text(
              widget.filterMode ? l10n.maxTagsFilter : l10n.maxTagsPerTx,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
          const SizedBox(height: 16),
          Flexible(
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (showCreate)
                    ActionChip(
                      avatar: Icon(Icons.add_rounded,
                          size: 18, color: theme.colorScheme.primary),
                      label: Text(l10n.createTagNamed(query),
                          style: TextStyle(color: theme.colorScheme.primary)),
                      onPressed: () => _create(query),
                    ),
                  for (final tag in visible)
                    TagChip(
                      label: tag.name,
                      variant: TagChipVariant.filter,
                      dot: tag.dot,
                      selected: _selected.contains(tag.id),
                      disabled: _atCap && !_selected.contains(tag.id),
                      onTap: () => _toggle(tag.id),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (!widget.filterMode)
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.push(Routes.tags);
                  },
                  child: Text(l10n.allTags),
                ),
              const Spacer(),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.actionDone),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
