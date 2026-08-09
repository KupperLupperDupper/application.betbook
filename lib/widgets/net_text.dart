import 'package:flutter/material.dart';

import '../core/theme/money_colors.dart';

/// Shows a monetary result coloured by sign, with an optional trend arrow.
/// Colour is never the only signal — a +/− sign (already in [text]) and the
/// arrow icon carry the meaning for colourblind users.
class NetText extends StatelessWidget {
  const NetText({
    super.key,
    required this.value,
    required this.text,
    this.style,
    this.showIcon = true,
    this.iconSize,
  });

  /// Numeric value used only to choose colour/icon (sign matters, not scale).
  final num value;

  /// Pre-formatted amount string (already includes the sign).
  final String text;

  final TextStyle? style;
  final bool showIcon;
  final double? iconSize;

  @override
  Widget build(BuildContext context) {
    final color = context.money.forAmount(value);
    final effectiveStyle = (style ?? DefaultTextStyle.of(context).style)
        .copyWith(color: color, fontFeatures: const [FontFeature.tabularFigures()]);
    final resolvedIconSize = iconSize ?? (effectiveStyle.fontSize ?? 16) * 0.9;

    final icon = value > 0
        ? Icons.trending_up_rounded
        : value < 0
            ? Icons.trending_down_rounded
            : Icons.trending_flat_rounded;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showIcon) ...[
          Icon(icon, color: color, size: resolvedIconSize),
          const SizedBox(width: 4),
        ],
        Flexible(
          child: Text(
            text,
            style: effectiveStyle,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
