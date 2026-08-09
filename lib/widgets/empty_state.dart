import 'package:flutter/material.dart';

import 'suit_marks.dart';

/// The design's empty state: a 2×2 suit mark, a headline, one supportive
/// sentence, a single filled primary action, and an optional footnote line
/// (e.g. the on-device privacy reassurance).
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.footnote,
  });

  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? footnote;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SuitGlyphMark(size: 64),
            const SizedBox(height: 24),
            Text(
              title,
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              message,
              style: theme.textTheme.bodyLarge
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add_rounded),
                label: Text(actionLabel!),
              ),
            ],
            if (footnote != null) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_outline_rounded,
                      size: 14, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Text(
                    footnote!,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
