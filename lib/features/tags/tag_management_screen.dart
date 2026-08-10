import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database/database.dart';
import '../../l10n/l10n_ext.dart';
import '../../providers/core_providers.dart';
import '../../providers/tags_providers.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/tag_dot.dart';
import '../../widgets/undo_snackbar.dart';

/// Tag management (TAGS_HANDOFF §5). A pushed route reached from Settings ›
/// Data › Tags (and the picker's "All tags" row). Lists every tag by use, and
/// opens a detail sheet per tag for rename / dot / merge / delete.
class TagManagementScreen extends ConsumerWidget {
  const TagManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final tagsAsync = ref.watch(tagsProvider);
    final counts = ref.watch(tagCountsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.tagsManageTitle)),
      body: tagsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const SizedBox.shrink(),
        data: (tags) {
          if (tags.isEmpty) {
            return EmptyState(title: l10n.noTagsYet, message: l10n.noTagsYetBody);
          }
          final sorted = [...tags]..sort((a, b) {
              final ca = counts[a.id] ?? 0;
              final cb = counts[b.id] ?? 0;
              if (ca != cb) return cb.compareTo(ca);
              return a.name.toLowerCase().compareTo(b.name.toLowerCase());
            });
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: sorted.length,
            itemBuilder: (context, i) {
              final tag = sorted[i];
              return _TagRow(
                tag: tag,
                count: counts[tag.id] ?? 0,
                onTap: () => _openDetail(context, tag),
              );
            },
          );
        },
      ),
    );
  }

  void _openDetail(BuildContext context, Tag tag) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
      builder: (_) => _TagDetailSheet(tag: tag),
    );
  }
}

class _TagRow extends StatelessWidget {
  const _TagRow({required this.tag, required this.count, required this.onTap});

  final Tag tag;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dotColor = TagDot.color(tag.dot, theme.brightness);

    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 64),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              // Reserve the dot column even when there is no dot, so names align.
              SizedBox(
                width: TagDot.diameter + 12,
                child: dotColor == null
                    ? null
                    : Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          width: TagDot.diameter,
                          height: TagDot.diameter,
                          decoration: BoxDecoration(
                            color: dotColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
              ),
              Expanded(
                child: Text(
                  tag.name,
                  style: theme.textTheme.bodyLarge,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                context.l10n.entriesCount(count),
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

/// The per-tag detail sheet: rename, dot swatch row, merge, delete.
class _TagDetailSheet extends ConsumerStatefulWidget {
  const _TagDetailSheet({required this.tag});

  final Tag tag;

  @override
  ConsumerState<_TagDetailSheet> createState() => _TagDetailSheetState();
}

class _TagDetailSheetState extends ConsumerState<_TagDetailSheet> {
  late final TextEditingController _nameController;
  late final FocusNode _nameFocus;
  String? _renameError;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.tag.name);
    _nameFocus = FocusNode()..addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _nameFocus
      ..removeListener(_onFocusChange)
      ..dispose();
    _nameController.dispose();
    super.dispose();
  }

  /// The live tag — reflects dot/name changes the moment the stream re-emits.
  Tag get _currentTag => ref.read(tagsByIdProvider)[widget.tag.id] ?? widget.tag;

  void _onFocusChange() {
    if (!_nameFocus.hasFocus) _commitRename();
  }

  Future<void> _commitRename() async {
    final tag = _currentTag;
    final newName = _nameController.text.trim();
    if (newName.isEmpty) {
      _nameController.text = tag.name;
      if (_renameError != null) setState(() => _renameError = null);
      return;
    }
    if (newName == tag.name) {
      if (_renameError != null) setState(() => _renameError = null);
      return;
    }
    final ok = await ref.read(tagRepositoryProvider).rename(tag, newName);
    if (!mounted) return;
    // On a folded-name clash the save is blocked and the sheet stays open.
    setState(() => _renameError = ok ? null : context.l10n.tagInUse);
  }

  void _setDot(String? name) {
    final tag = _currentTag;
    if (tag.dot == name) return;
    ref.read(tagRepositoryProvider).setDot(tag, name);
  }

  Future<void> _openMergePicker() async {
    final source = _currentTag;
    final others = [
      ...?ref.read(tagsProvider).valueOrNull,
    ].where((t) => t.id != source.id).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    if (others.isEmpty) return;

    final target = await showModalBottomSheet<Tag>(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final t in others)
              ListTile(
                leading: _MiniDot(dot: t.dot),
                title: Text(t.name),
                onTap: () => Navigator.pop(ctx, t),
              ),
          ],
        ),
      ),
    );
    if (target == null || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final message = context.l10n.tagMergedSnack(source.name, target.name);
    await ref.read(tagRepositoryProvider).merge(source.id, target.id);
    navigator.pop(); // close the detail sheet
    messenger
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _delete() async {
    final tag = _currentTag;
    final count = ref.read(tagCountsProvider)[tag.id] ?? 0;
    final l10n = context.l10n;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.tagDeleteTitle),
        content: Text(l10n.tagDeleteBody(count)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.actionDelete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    // Capture the messenger before navigating — it lives above the router.
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final repo = ref.read(tagRepositoryProvider);
    final message = l10n.tagDeletedSnack;
    final undoLabel = l10n.actionUndo;

    final joins = await repo.deleteCapturing(tag.id);
    navigator.pop(); // close the detail sheet
    showUndoSnackBar(
      messenger,
      message: message,
      undoLabel: undoLabel,
      onUndo: () => repo.restore(tag, joins),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tag = ref.watch(tagsByIdProvider)[widget.tag.id] ?? widget.tag;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 8, 20, 20 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _nameController,
            focusNode: _nameFocus,
            textInputAction: TextInputAction.done,
            maxLength: 24,
            onSubmitted: (_) => _commitRename(),
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              counterText: '',
              errorText: _renameError,
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final name in TagDot.names)
                _ColorSwatch(
                  color: TagDot.color(name, theme.brightness)!,
                  selected: tag.dot == name,
                  onTap: () => _setDot(name),
                ),
              _NoColourOption(
                label: l10n.tagNoColour,
                selected: tag.dot == null,
                onTap: () => _setDot(null),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.call_merge_rounded, color: scheme.onSurfaceVariant),
            title: Text(l10n.tagMergeInto),
            onTap: _openMergePicker,
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.delete_outline_rounded, color: scheme.error),
            title: Text(l10n.tagDeleteTitle, style: TextStyle(color: scheme.error)),
            onTap: _delete,
          ),
        ],
      ),
    );
  }
}

/// A tappable colour swatch; a ring marks the selected dot.
class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? scheme.onSurface : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The "No colour" option that clears a tag's dot.
class _NoColourOption extends StatelessWidget {
  const _NoColourOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: selected ? scheme.secondaryContainer : Colors.transparent,
            border: selected ? null : Border.all(color: scheme.outline),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Icon(Icons.check_rounded,
                      size: 16, color: scheme.onSecondaryContainer),
                ),
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: selected
                      ? scheme.onSecondaryContainer
                      : scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A small leading dot for the merge-target list (or an empty slot when none).
class _MiniDot extends StatelessWidget {
  const _MiniDot({required this.dot});

  final String? dot;

  @override
  Widget build(BuildContext context) {
    final color = TagDot.color(dot, Theme.of(context).brightness);
    return SizedBox(
      width: 12,
      height: double.infinity,
      child: color == null
          ? null
          : Center(
              child: Container(
                width: TagDot.diameter,
                height: TagDot.diameter,
                decoration:
                    BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            ),
    );
  }
}
