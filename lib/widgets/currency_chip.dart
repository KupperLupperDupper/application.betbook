import 'package:flutter/material.dart';

/// A small static currency badge, e.g. `DKK`. Uses the design's
/// surfaceVariant / onSurfaceVariant, labelSmall 700.
class CurrencyChip extends StatelessWidget {
  const CurrencyChip({super.key, required this.code});
  final String code;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        code,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
