import 'package:flutter/material.dart';

import 'tag_dot.dart';

/// The one visual family of tag chip, four variants (TAGS_HANDOFF §3). Radius is
/// always full; a chip must read as a filing label — never a badge, level, or
/// filled accent.
enum TagChipVariant {
  /// In transaction rows — 20 dp, not tappable (the row is).
  micro,

  /// In add/edit transaction + tag management — 32 dp with a trailing ×.
  assigned,

  /// In the Stats filter — 32 dp, outlined when unselected, filled when on.
  filter,

  /// The "+ Add tag" affordance — 32 dp, outlined, leading +.
  add,
}

class TagChip extends StatelessWidget {
  const TagChip({
    super.key,
    required this.label,
    this.variant = TagChipVariant.assigned,
    this.dot,
    this.selected = false,
    this.disabled = false,
    this.onTap,
    this.onRemove,
  });

  final String label;
  final TagChipVariant variant;

  /// Dot palette name, or null for no dot.
  final String? dot;
  final bool selected;
  final bool disabled;
  final VoidCallback? onTap;

  /// The trailing × on an [TagChipVariant.assigned] chip.
  final VoidCallback? onRemove;

  double get _height => variant == TagChipVariant.micro ? 20 : 32;
  double get _maxWidth => variant == TagChipVariant.micro ? 116 : 148;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final brightness = theme.brightness;
    final dotColor = TagDot.color(dot, brightness);

    // Resolve fill / ink / outline per variant + state.
    Color fill = Colors.transparent;
    Color ink = scheme.onSurfaceVariant;
    BorderSide side = BorderSide.none;

    switch (variant) {
      case TagChipVariant.micro:
      case TagChipVariant.assigned:
        fill = scheme.surfaceContainerHigh;
        ink = scheme.onSurfaceVariant;
        break;
      case TagChipVariant.filter:
        if (selected) {
          fill = scheme.primaryContainer;
          ink = scheme.onPrimaryContainer;
        } else if (disabled) {
          side = BorderSide(color: scheme.outlineVariant);
          ink = scheme.onSurfaceVariant.withValues(alpha: 0.38);
        } else {
          side = BorderSide(color: scheme.outline);
          ink = scheme.onSurfaceVariant;
        }
        break;
      case TagChipVariant.add:
        side = BorderSide(color: scheme.outline);
        ink = scheme.onSurfaceVariant;
        break;
    }

    final labelStyle = (variant == TagChipVariant.micro
            ? theme.textTheme.labelSmall
            : theme.textTheme.labelLarge)
        ?.copyWith(color: ink, fontWeight: FontWeight.w600);

    final children = <Widget>[
      if (variant == TagChipVariant.filter && selected)
        Padding(
          padding: const EdgeInsets.only(right: 4),
          child: Icon(Icons.check_rounded, size: 16, color: ink),
        ),
      if (variant == TagChipVariant.add)
        Padding(
          padding: const EdgeInsets.only(right: 4),
          child: Icon(Icons.add_rounded, size: 16, color: ink),
        ),
      if (dotColor != null && variant != TagChipVariant.add) ...[
        Container(
          width: TagDot.diameter,
          height: TagDot.diameter,
          decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
      ],
      Flexible(
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: labelStyle,
        ),
      ),
      if (variant == TagChipVariant.assigned && onRemove != null)
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: InkResponse(
            onTap: onRemove,
            radius: 18,
            child: Icon(Icons.close_rounded, size: 18, color: ink),
          ),
        ),
    ];

    final content = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: _maxWidth, minHeight: _height),
      child: Container(
        height: _height,
        padding: _padding,
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(_height / 2),
          border: side == BorderSide.none ? null : Border.fromBorderSide(side),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: children),
      ),
    );

    // Micro chips are decorative; the row owns the tap.
    final tappable = variant != TagChipVariant.micro && onTap != null;
    if (!tappable) return content;
    return InkWell(
      onTap: disabled ? null : onTap,
      borderRadius: BorderRadius.circular(_height / 2),
      child: content,
    );
  }

  EdgeInsets get _padding {
    switch (variant) {
      case TagChipVariant.micro:
        return EdgeInsets.symmetric(horizontal: dot != null ? 10 : 8);
      case TagChipVariant.assigned:
        return const EdgeInsets.only(left: 12, right: 8);
      case TagChipVariant.filter:
        return EdgeInsets.only(left: dot != null ? 12 : 14, right: 14);
      case TagChipVariant.add:
        return const EdgeInsets.only(left: 10, right: 14);
    }
  }
}
